# Contract: the setup hook gate and the agents' hook line

Two sides of one rule (principle IV: they change together): `/feat` setup
tells the user which hooks won't run; the specifier, planner and tasker
skip every hook and list it. Classification is in
[../data-model.md](../data-model.md#spec-kit-hook-entry-specifyextensionsyml).

## `.apm/skills/feat/SKILL.md`, setup step 4 (replaces today's text)

Wording may be tightened in implementation; the content may not change.

> 4. Read `.specify/extensions.yml` (enabled entries only). The specifier,
>    planner and tasker can't run hooks (`Skill` is denied): every hook
>    under `before_`/`after_` `specify`, `plan`, `tasks` or `analyze`,
>    git ones included, will not run. `implement` hooks are allowed,
>    except those that create a branch or commit (the git extension's),
>    which agents skip unless the user says otherwise. If any hook won't
>    run or would branch or commit, **hard gate** before phase 2, one
>    message: each such hook with its key, extension and command, and the
>    command to run it by hand (`/` and its `command`, dots as hyphens; a
>    hook with no `command` is shown by its extension only), and that
>    these won't run during this run: run them by hand once the PR is
>    open, or stop now. The user continues with them skipped, or stops,
>    and says whether to allow a branching or committing `implement` hook.
>    On `rebase`, only the `implement` part applies.

Phases table, row 0, Gate column (`SKILL.md` and `docs/workflow.md`):
`hard only if a Spec Kit hook won't run (specify, plan, tasks, analyze) or would branch or commit`.

## Gate message shape

One message, sections omitted when empty. Every hook line has the same
shape:

```text
<key>: <extension>.<command> → run it by hand: /<command with dots as hyphens>
```

A hook with no `command` is shown by its extension only:
`<key>: <extension>`, with no manual command.

```text
Spec Kit hooks — decide before phase 2:
Won't run (the specifier, planner and tasker can't run hooks):
- <key>: <extension>.<command> → run it by hand: /<command with dots as hyphens>
- …
Would branch or commit (implement), skipped unless you allow it:
- <key>: <extension>.<command> → run it by hand: /<command with dots as hyphens>
These won't run during this run: run them by hand once the PR is open,
or stop now. Continue with these skipped, or stop?
```

A hook enabled under several of the four keys appears once per key
(edge case: still one message). The answer is logged on the setup line
of the state file's Log; there is no "run it anyway" for the first section.

## Agent hook line (feat-specifier, feat-planner, feat-tasker)

Replaces the four-line "Spec Kit hooks: the orchestrator tells you which
hooks … are allowed …" paragraph in each of the three files:

> Spec Kit hooks: you can't run them (`Skill` is denied; `/feat` setup told
> the user). Skip every hook and list each under `Skipped hooks:`.

The report format is unchanged: each already ends with
`Skipped hooks: <hook → why, or "none">`. The PR body is unchanged.
`feat-implementer`, `feat-bug-assessor` keep their existing hook paragraph.
