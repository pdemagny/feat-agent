# specs/

logistics is built with itself. Each folder here is what a `/feat` run
left behind for one feature of this repo: the spec, plan, research,
contracts and tasks Spec Kit wrote, and `feat-state.md`, the run's state
file and log (gates passed, user decisions, what each agent reported).

They are records, kept as examples of what a run produces. They describe
the feature as it was built; the docs in [`docs/`](../docs) describe how
logistics works now.

Bug fixes made with `/fix` leave the same kind of trail under
[`.specify/bugs/`](../.specify/bugs). `.specify/` and `.claude/skills/speckit-*`
are Spec Kit's own files, installed by `specify init`.
