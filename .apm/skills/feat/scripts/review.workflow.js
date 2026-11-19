export const meta = {
  name: 'feat-code-review',
  description: '/feat phase 7: code reviewers per the size table, merge rules 2-5, the gate, and the fix pass on a soft gate',
  phases: [{ title: 'Review' }, { title: 'Fix' }],
}

// Spike #56 prototype. args:
//   mode: 'review' (default) | 'fix'
//   size: 'small' | 'medium' | 'large'
//   root: the worktree; featureDir: specs/<short-name>/ (absolute)
//   diff: the diff command; prefix: '' or 'logistics:'
//   rejected, secFindings, hooks: text passed through to the agents
//   picked: (fix mode) the finding lines the user picked, as this script returned them

const A = args || {}
const P = A.prefix || ''

// Rows 7a-7e and 6 of /feat's size table (a copy: #30 would generate it).
const ROWS = {
  '7a': { small: ['sonnet', 'medium'], medium: ['opus', 'medium'], large: ['opus', 'medium'] },
  '7b': { small: ['sonnet', 'medium'], medium: ['opus', 'medium'], large: ['opus', 'high'] },
  '7c': { small: ['sonnet', 'medium'], medium: ['sonnet', 'medium'], large: ['opus', 'medium'] },
  '7d': { small: ['sonnet', 'medium'], medium: ['sonnet', 'medium'], large: ['sonnet', 'medium'] },
  '7e': { small: ['sonnet', 'medium'], medium: ['sonnet', 'medium'], large: ['sonnet', 'medium'] },
  '6': { small: ['sonnet', 'medium'], medium: ['opus', 'medium'], large: ['opus', 'high'] },
}
const MODELS = ['haiku', 'sonnet', 'opus']
const EFFORTS = ['low', 'medium', 'high', 'xhigh', 'max']
function strongest(lenses) {
  let m = 0, e = 0
  for (const l of lenses) {
    const [model, effort] = ROWS[l][A.size]
    m = Math.max(m, MODELS.indexOf(model))
    e = Math.max(e, EFFORTS.indexOf(effort))
  }
  return { model: MODELS[m], effort: EFFORTS[e] }
}

const FINDING = {
  type: 'object',
  properties: {
    section: { type: 'string', enum: ['bugs', 'spec', 'standards', 'security', 'performance', 'cuts', 'readability'] },
    file: { type: 'string', description: 'repo-relative path' },
    line_start: { type: 'integer' },
    line_end: { type: 'integer' },
    title: { type: 'string', description: 'the finding, one line' },
    fix: { type: 'string', description: 'the → fix text' },
    kind: { type: 'string', description: 'spec: missing | scope creep | wrong; standards: hard | judgement; cuts: the tag; else empty' },
    detail: { type: 'string', description: 'the section\'s other fields as one line: confidence, severity, measured / verify with / guard, quoted spec line, standard cited' },
    confidence: { type: 'string', enum: ['high', 'medium', 'n/a'] },
    rec: { type: 'string', enum: ['apply', 'skip', 'user'] },
    why: { type: 'string', description: 'required for skip and user; empty for apply' },
  },
  required: ['section', 'file', 'line_start', 'line_end', 'title', 'fix', 'confidence', 'rec', 'why'],
}
const REVIEW = {
  type: 'object',
  properties: {
    findings: { type: 'array', items: FINDING },
    criteria: {
      type: 'array',
      items: {
        type: 'object',
        properties: { criterion: { type: 'string' }, status: { type: 'string', enum: ['met', 'not met', 'untested'] }, why: { type: 'string' } },
        required: ['criterion', 'status'],
      },
    },
    design_built: { type: 'array', items: { type: 'string' }, description: '7b: "D-id: yes | no"' },
    net: { type: 'string', description: '7d: "-N lines possible" or "lean already"' },
    dismissed: { type: 'array', items: { type: 'string' } },
    wrote: { type: 'array', items: { type: 'string' }, description: 'paths you wrote; empty (you are read-only)' },
  },
  // criteria is required: the dry run's 7a put its verdicts under dismissed, which hides a `not met` from the gate
  required: ['findings', 'criteria', 'dismissed', 'wrote'],
}
const FIXED = {
  type: 'object',
  properties: {
    checks: {
      type: 'array',
      items: {
        type: 'object',
        properties: { command: { type: 'string' }, result: { type: 'string', enum: ['pass', 'fail'] }, error: { type: 'string' } },
        required: ['command', 'result'],
      },
    },
    not_verified: { type: 'array', items: { type: 'string' }, description: '"<item> → <check> → <why>"; empty means none' },
    fixes: {
      type: 'array',
      items: {
        type: 'object',
        properties: { id: { type: 'string' }, status: { type: 'string', enum: ['applied', 'reverted'] }, why: { type: 'string' } },
        required: ['id', 'status'],
      },
    },
    performance: { type: 'array', items: { type: 'string' }, description: '"<id>: <before> → <after> (<command>)"' },
    design_problems: { type: 'string' },
    files_changed: { type: 'string' },
    skipped_hooks: { type: 'array', items: { type: 'string' } },
    wrote: { type: 'array', items: { type: 'string' }, description: 'absolute paths of files you created' },
  },
  required: ['checks', 'not_verified', 'fixes', 'wrote'],
}

const STRUCT = 'Give your report only through the structured output, one findings entry per finding line of your usual report (file and line range in the new file; the rec and its why apart); write no text report.'

function reviewPrompt(lenses, cuts) {
  return [
    `Lenses: ${lenses.join('+')}. Size: ${A.size}.`,
    `Worktree: ${A.root}. Feature dir: ${A.featureDir}.`,
    `Diff command: ${A.diff}`,
    lenses.includes('7b') ? `Accepted [sec] design findings: ${A.secFindings || 'none'}` : '',
    `Rejected findings (don't propose them again): ${A.rejected || 'none'}`,
    cuts ? `7d's cuts (don't review code they remove): ${cuts}` : '',
    STRUCT,
    lenses.includes('7a') ? 'criteria: one entry per acceptance criterion of spec.md, never empty.' : 'criteria: empty (not your lens).',
  ].filter(Boolean).join('\n')
}

function review(lenses, cuts) {
  const { model, effort } = strongest(lenses)
  return agent(reviewPrompt(lenses, cuts), {
    label: `reviewer ${lenses.join('+')}`, phase: 'Review', agentType: `${P}feat-code-reviewer`,
    model, effort, schema: REVIEW,
  }).then(r => (r ? { lenses, ...r } : { lenses, failed: true }))
}

function cutsText(r) {
  return (r.findings || []).filter(f => f.section === 'cuts').map(f => `${f.file}:${f.line_start}-${f.line_end} ${f.title}`).join('; ') || 'none'
}

// ---- merge rules 2-5 (rule 1 needs judgement: the coordinator keeps it) ----
const PREFIX = { bugs: 'B', spec: 'B', standards: 'B', security: 'S', performance: 'P', cuts: 'C', readability: 'R' }
const ORDER = ['bugs', 'spec', 'standards', 'security', 'cuts', 'performance', 'readability']
const overlap = (a, b) => a.file === b.file && a.line_start <= b.line_end && b.line_start <= a.line_end

function merge(reports) {
  let all = []
  for (const r of reports) for (const f of r.findings || []) all.push({ ...f, from: r.lenses.join('+') })
  const kept = []
  for (const f of all) {
    const same = kept.find(k => k.section === f.section && overlap(k, f))
    if (!same) { kept.push(f); continue }
    if (same.rec === f.rec && same.fix === f.fix) continue // rule 2
    if (same.from !== f.from) { // rule 3
      same.rec = 'user'; same.why = 'reviewers disagree'
      kept.push({ ...f, rec: 'user', why: 'reviewers disagree' })
    } else kept.push(f)
  }
  for (const f of kept) {
    if (f.section === 'bugs' && f.confidence === 'high' && f.rec === 'skip') { // rule 4
      f.rec = 'user'; f.why = f.why || 'no valid recommendation'
    }
    if (f.rec !== 'apply' && !(f.why || '').trim()) { f.rec = 'user'; f.why = 'no valid recommendation' } // rule 5
  }
  kept.sort((a, b) => ORDER.indexOf(a.section) - ORDER.indexOf(b.section))
  const n = {}
  for (const f of kept) {
    const p = PREFIX[f.section]
    n[p] = (n[p] || 0) + 1
    f.id = `${p}${n[p]}`
  }
  return kept
}

const spot = f => `${f.file}:${f.line_start}${f.line_end !== f.line_start ? '-' + f.line_end : ''}`
const recText = f => (f.rec === 'apply' ? 'apply' : `${f.rec} (${f.why})`)
function line(f) {
  const tag = f.section === 'standards' ? ` [std ${f.kind || ''}]`.replace(' ]', ']') : ''
  return `${f.id}${tag} ${spot(f)} — ${f.title} → ${f.fix}${f.detail ? ' — ' + f.detail : ''} — rec: ${recText(f)}`
}
function logLine(f) {
  return f.section === 'security' ? `    - ${f.id} ${f.file} — ${f.title}` : `    - ${f.id} ${spot(f)} — ${f.title} — rec: ${f.rec}`
}

// ---- the fix pass ----
// lines: rendered finding lines, already in fix order (merge() sorts bugs, security, cuts, performance, readability)
async function fixPass(lines) {
  const { model, effort } = strongest(['6'])
  const list = lines.join('\n')
  const base = [
    `Fix mode (phase 7). Worktree: ${A.root}. Feature dir: ${A.featureDir}. <who>: review fixes.`,
    `Allowed Spec Kit hooks: ${A.hooks || 'none'}.`,
    `Findings to apply, in this order (skip a performance or readability finding whose code a cut removed, and say so as reverted):`,
    list,
    'Give your report only through the structured output; write no text report.',
  ]
  let r = await agent(base.join('\n'), { label: 'implementer review fixes', phase: 'Fix', agentType: `${P}feat-implementer`, model, effort, schema: FIXED })
  let retried = false
  const failing = x => (x.checks || []).filter(c => c.result === 'fail')
  if (r && failing(r).length) {
    retried = true
    const fails = failing(r).map(c => `${c.command} → fail (${c.error || ''})`).join('\n')
    r = await agent([...base, 'A first pass left these checks failing; fix them without weakening a test:', fails].join('\n'), {
      label: 'implementer review fixes (retry)', phase: 'Fix', agentType: `${P}feat-implementer`, model, effort, schema: FIXED,
    })
  }
  let stop = null
  if (!r) stop = 'implementer returned nothing'
  else if (failing(r).length) stop = `checks still fail: ${failing(r).map(c => c.command).join(', ')}`
  const nv = r ? (r.not_verified.length ? r.not_verified.join('; ') : 'none') : null
  return {
    checks: r ? r.checks.map(c => `${c.command} → ${c.result}${c.error ? ' (' + c.error + ')' : ''}`) : [],
    retried,
    stop, // non-null: hard stop before phase 8
    wrote: r ? r.wrote : [],
    log: r
      ? [
          stop ? `- [!] 7 review fixes — ${stop}` : `- [x] 7 review fixes — ${r.fixes.map(x => `${x.id} ${x.status}${x.why ? ' (' + x.why + ')' : ''}`).join('; ')}${r.performance && r.performance.length ? '; ' + r.performance.join('; ') : ''}`,
          `- [x] 7 review fixes — not verified: ${nv}`,
        ]
      : [`- [!] 7 review fixes — ${stop}`],
  }
}

// ---- main ----
if (A.mode === 'fix') {
  phase('Fix')
  const picked = A.picked || []
  if (!picked.length) return { mode: 'fix', fix: null, log: ['- [x] 7 review fixes — none picked'] }
  return { mode: 'fix', fix: await fixPass(picked) }
}

phase('Review')
let reports
if (A.size === 'small') {
  reports = await parallel([() => review(['7a', '7b']), () => review(['7c', '7d', '7e'])])
} else {
  const r = await parallel([
    () => review(['7a']),
    () => review(['7b']),
    () => review(['7c']),
    () => review(['7d']).then(async d => [d, await review(['7e'], d.failed ? 'none' : cutsText(d))]),
  ])
  reports = r.flat()
}

const failed = reports.filter(r => !r || r.failed).map(r => (r ? r.lenses.join('+') : '?'))
const ok = reports.filter(r => r && !r.failed)
const wroteSomething = ok.filter(r => (r.wrote || []).length).map(r => `${r.lenses.join('+')}: ${r.wrote.join(', ')}`)
const findings = merge(ok)
const criteria = ok.flatMap(r => r.criteria || [])
const notMet = criteria.filter(c => c.status === 'not met')
const untested = criteria.filter(c => c.status === 'untested').map(c => c.criterion)

// gate: Reported files (a reviewer wrote) and a missing reviewer are hard too
const reasons = []
if (A.size === 'large') reasons.push('large')
const userIds = findings.filter(f => f.rec === 'user').map(f => f.id)
if (userIds.length) reasons.push(`${userIds.join(', ')} need you`)
for (const f of findings.filter(f => f.section === 'security')) reasons.push(`${f.id} security`)
for (const c of notMet) reasons.push(`criterion not met: ${c.criterion}`)
if (ok.some(r => r.lenses.includes('7a') && !(r.criteria || []).length)) reasons.push('7a reported no acceptance criteria')
const notBuilt = ok.flatMap(r => r.design_built || []).filter(d => /:\s*no\b/i.test(d))
for (const d of notBuilt) reasons.push(`design finding not built: ${d}`)
for (const w of wroteSomething) reasons.push(`a read-only reviewer wrote files: ${w}`)
for (const l of failed) reasons.push(`reviewer ${l} returned nothing`)
const gate = reasons.length ? 'hard' : 'soft'

const apply = findings.filter(f => f.rec === 'apply')
const skipped = findings.filter(f => f.rec === 'skip')
const untestedText = untested.length ? `; untested: ${untested.join(', ')}` : ''
const findingLog = findings.map(logLine)

// Keep the return small: the task notification truncates a long result
// (about 8k characters); full reports stay in the run's journal.jsonl.
const out = {
  mode: 'review',
  gate,
  reasons,
  lines: findings.map(line), // pass the picked ones back as `picked` after a hard gate
  untested,
}
if (gate === 'hard') return out

out.softLine = `Phase 7 Code review — soft: ${findings.length} findings, ${apply.length} to apply, ${skipped.length} skipped; none needs your call${untestedText}. Next: ${apply.length ? 'review fixes, then phase 8 Ship' : 'phase 8 Ship'}`
out.log = [
  `- [x] 7 Code review — soft: auto-applied ${apply.map(f => f.id).join(', ') || 'none'}${skipped.length ? '; skipped ' + skipped.map(f => `${f.id} (reviewer: "${f.why}")`).join(', ') : ''}${untestedText}`,
  ...findingLog,
]
phase('Fix')
out.fix = apply.length ? await fixPass(apply.map(line)) : null
return out
