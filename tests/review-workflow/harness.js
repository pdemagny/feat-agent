// Offline check of review.workflow.js: stub agent()/parallel(), fixture reports.
const fs = require('fs')
const src = fs.readFileSync(process.argv[2], 'utf8').replace(/^export const meta/m, 'const meta')
const run = new Function('args', 'agent', 'parallel', 'phase', 'log', `return (async () => {${src}})()`)

const F = (o) => ({ section: 'bugs', file: 'a.go', line_start: 10, line_end: 12, title: 't', fix: 'f', confidence: 'medium', rec: 'apply', why: '', ...o })
const crit = [{ criterion: 'AC1', status: 'met' }]

async function go(name, size, reports, fixReports, check) {
  const calls = []
  let fi = 0
  const agent = async (prompt, o) => {
    calls.push(o.label + ' ' + o.model + '·' + o.effort)
    if (o.agentType.endsWith('feat-implementer')) return fixReports[fi++]
    const lens = /Lenses: (\S+)\./.exec(prompt)[1]
    return reports[lens]
  }
  const parallel = (ts) => Promise.all(ts.map((t) => t().catch(() => null)))
  const out = await run({ size, root: '/r', featureDir: '/r/specs/x', diff: 'git diff HEAD' }, agent, parallel, () => {}, () => {})
  const ok = check(out, calls)
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}`)
  if (!ok) console.log(JSON.stringify({ out, calls }, null, 1))
  if (!ok) process.exitCode = 1
}

const pass = { checks: [{ command: 'mise run lint', result: 'pass' }], not_verified: [], fixes: [{ id: 'R1', status: 'applied' }], wrote: [] }
const fail = { checks: [{ command: 'mise run lint', result: 'fail', error: 'x' }], not_verified: [], fixes: [], wrote: [] }

;(async () => {
  await go('rule 2: same spot, section, rec, fix -> one', 'small',
    { '7a+7b': { findings: [F({}), F({ line_start: 11 })], criteria: crit, dismissed: [], wrote: [] },
      '7c+7d+7e': { findings: [], criteria: [], dismissed: [], wrote: [] } }, [pass],
    (o) => o.gate === 'soft' && o.lines.length === 1 && o.fix && o.fix.stop === null)

  await go('rule 3: two reviewers disagree -> both user, hard', 'medium',
    { '7a': { findings: [], criteria: crit, dismissed: [], wrote: [] }, '7b': { findings: [], criteria: [], dismissed: [], wrote: [] },
      '7c': { findings: [F({ section: 'readability', rec: 'apply' })], criteria: [], dismissed: [], wrote: [] },
      '7d': { findings: [], criteria: [], dismissed: [], wrote: [] },
      '7e': { findings: [F({ section: 'readability', rec: 'skip', why: 'meh' })], criteria: [], dismissed: [], wrote: [] } }, [],
    (o) => o.gate === 'hard' && o.lines.filter((l) => l.includes('user (reviewers disagree)')).length === 2)

  await go('rule 4: high-confidence bug skipped -> user', 'small',
    { '7a+7b': { findings: [F({ confidence: 'high', rec: 'skip', why: 'later' })], criteria: crit, dismissed: [], wrote: [] },
      '7c+7d+7e': { findings: [], criteria: [], dismissed: [], wrote: [] } }, [],
    (o) => o.gate === 'hard' && o.lines[0].includes('rec: user (later)'))

  await go('rule 5: skip without why -> user', 'small',
    { '7a+7b': { findings: [F({ section: 'cuts', rec: 'skip', why: ' ' })], criteria: crit, dismissed: [], wrote: [] },
      '7c+7d+7e': { findings: [], criteria: [], dismissed: [], wrote: [] } }, [],
    (o) => o.gate === 'hard' && o.lines[0].includes('user (no valid recommendation)'))

  await go('S finding with apply -> hard', 'small',
    { '7a+7b': { findings: [F({ section: 'security' })], criteria: crit, dismissed: [], wrote: [] },
      '7c+7d+7e': { findings: [], criteria: [], dismissed: [], wrote: [] } }, [],
    (o) => o.gate === 'hard' && o.reasons.includes('S1 security'))

  await go('criterion not met -> hard; 7a without criteria -> hard', 'small',
    { '7a+7b': { findings: [], criteria: [{ criterion: 'AC2', status: 'not met' }], dismissed: [], wrote: [] },
      '7c+7d+7e': { findings: [], criteria: [], dismissed: [], wrote: [] } }, [],
    (o) => o.gate === 'hard' && o.reasons.includes('criterion not met: AC2'))
  await go('7a reports no criteria -> hard', 'small',
    { '7a+7b': { findings: [], criteria: [], dismissed: [], wrote: [] },
      '7c+7d+7e': { findings: [], criteria: [], dismissed: [], wrote: [] } }, [],
    (o) => o.gate === 'hard' && o.reasons.includes('7a reported no acceptance criteria'))

  await go('large -> hard always; models per row; 7e after 7d', 'large',
    { '7a': { findings: [], criteria: crit, dismissed: [], wrote: [] }, '7b': { findings: [], criteria: [], dismissed: [], wrote: [] },
      '7c': { findings: [], criteria: [], dismissed: [], wrote: [] }, '7d': { findings: [], criteria: [], dismissed: [], wrote: [] },
      '7e': { findings: [], criteria: [], dismissed: [], wrote: [] } }, [],
    (o, c) => o.gate === 'hard' && o.reasons[0] === 'large' && c.includes('reviewer 7b opus·high') && c.indexOf('reviewer 7e sonnet·medium') > c.indexOf('reviewer 7d sonnet·medium'))

  await go('small groups take the strongest row', 'small',
    { '7a+7b': { findings: [], criteria: crit, dismissed: [], wrote: [] }, '7c+7d+7e': { findings: [], criteria: [], dismissed: [], wrote: [] } }, [],
    (o, c) => o.gate === 'soft' && o.fix === null && c.includes('reviewer 7a+7b sonnet·medium'))

  await go('soft: failing checks retried once, then stop', 'small',
    { '7a+7b': { findings: [F({})], criteria: crit, dismissed: [], wrote: [] }, '7c+7d+7e': { findings: [], criteria: [], dismissed: [], wrote: [] } }, [fail, fail],
    (o, c) => o.fix.retried && o.fix.stop && o.fix.log[0].startsWith('- [!] 7 review fixes') && c.filter((x) => x.startsWith('implementer')).length === 2)

  await go('a reviewer dies -> hard', 'small',
    { '7a+7b': null, '7c+7d+7e': { findings: [], criteria: [], dismissed: [], wrote: [] } }, [],
    (o) => o.gate === 'hard' && o.reasons.some((r) => r.includes('returned nothing')))
})()
