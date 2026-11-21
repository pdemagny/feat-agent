#!/usr/bin/env python3
"""Generate every copy of the size tables from .apm/skills/feat/sizes.json.

    python3 -I docs/diagrams/sizes.py [--root DIR] [--check | --d2]

With no mode it rewrites .apm/skills/feat/sizes.tsv (the whole file step.sh reads: one line per
row and size, one per review group) and the marked regions (<!-- sizes-start NAME --> ...
<!-- sizes-end NAME -->) of /brief's row 1 sentence and docs/workflow.md's matrices and agents
table. With --d2 it prints the D2 source of docs/img/models.svg: one cell per phase and size,
coloured by model; a split cell is a phase that runs several reviewers in parallel, each group
of lenses on the strongest model and effort among its rows. With --check it writes nothing and
exits 1, naming each file that differs. Exit 0, or 2 on an error (nothing is written then).
Python 3.11+, standard library only.
"""
import argparse
import json
import pathlib
import re
import sys

JSON_PATH = ".apm/skills/feat/sizes.json"
SIZES = ("small", "medium", "large")
MODELS = ("haiku", "sonnet", "opus")
EFFORTS = ("low", "medium", "high", "xhigh", "max")
LENSES = ("7a", "7b", "7c", "7d", "7e")
# The diagram's columns: (phase, title). Fixed text: the titles are not row labels.
COLUMNS = [(1, "Brief review"), (2, "Specify"), (3, "Plan"), (4, "Design review"), (5, "Tasks"),
           (6, "Implement"), (7, "Code review"), (8, "Ship")]
FILL = {"haiku": "#e3e8fb", "sonnet": "#8fa3ee", "opus": "#3443ae"}
FONT = {"haiku": "#24305e", "sonnet": "#101736", "opus": "#ffffff"}
WIDTH, GAP = 126, 3

NAME_RE = re.compile(r"[a-z0-9-]+")
ID_RE = re.compile(r"[0-9]+[a-z]?")
LABEL_RE = re.compile(r"[A-Za-z0-9 ,()`/-]+")
MARKER_RE = re.compile(r"<!-- sizes-(start|end) (\S+) -->")
# Marker name -> (kind, file); the regions each target file must hold.
TARGETS = {
    ".apm/skills/brief/SKILL.md": {"brief-review": "inline"},
    "docs/workflow.md": {"feat-matrix": "block", "fix-matrix": "block", "agents-table": "block"},
}
WORKFLOW = "docs/workflow.md"
# The whole-file target step.sh reads.
TSV_PATH = ".apm/skills/feat/sizes.tsv"


class Fail(Exception):
    pass


# ---- the data file ----------------------------------------------------------------------------

def bad(where, what):
    raise Fail(f"sizes.py: {JSON_PATH}: {where}: {what}")


def only_keys(obj, where, allowed, required=None):
    if not isinstance(obj, dict):
        bad(where, "must be an object")
    for key in obj:
        if key not in allowed:
            bad(f"{where}.{key}" if where else key, "unknown key")
    for key in (required if required is not None else allowed):
        if key not in obj:
            bad(f"{where}.{key}" if where else key, "missing")


def check_row(row, where, skill):
    keys = ("id", "label", "agent", "loads") + SIZES
    only_keys(row, where, keys + (("lens",) if skill == "fix" else ()), keys)
    if skill == "fix":
        if row["agent"] == "feat-code-reviewer" and "lens" not in row:
            bad(f"{where}.lens", "missing")
        if "lens" in row and row["lens"] not in LENSES:
            bad(f"{where}.lens", f"must be one of {', '.join(LENSES)}")
    if not isinstance(row["id"], str) or not ID_RE.fullmatch(row["id"]):
        bad(f"{where}.id", "must match ^[0-9]+[a-z]?$")
    label = row["label"]
    if not isinstance(label, str) or not label:
        bad(f"{where}.label", "must be a non-empty string")
    if not LABEL_RE.fullmatch(label):
        bad(f"{where}.label", "may hold only letters, digits, spaces and , ( ) ` / -")
    if not isinstance(row["agent"], str) or not NAME_RE.fullmatch(row["agent"]):
        bad(f"{where}.agent", "must match ^[a-z0-9-]+$")
    if not isinstance(row["loads"], list):
        bad(f"{where}.loads", "must be a list")
    for k, name in enumerate(row["loads"]):
        if not isinstance(name, str) or not NAME_RE.fullmatch(name):
            bad(f"{where}.loads[{k}]", "must match ^[a-z0-9-]+$")
    for size in SIZES:
        spawn = row[size]
        only_keys(spawn, f"{where}.{size}", ("model", "effort"))
        if spawn["model"] not in MODELS:
            bad(f"{where}.{size}.model", f"must be one of {', '.join(MODELS)}")
        if spawn["effort"] not in EFFORTS:
            bad(f"{where}.{size}.effort", f"must be one of {', '.join(EFFORTS)}")


def phase_of(row_id):
    return int(re.match(r"\d+", row_id).group())


def check_groups(groups, rows, skill, strict):
    """<skill>.groups. Strict (feat): every phase with two or more rows has groups and each size
    lists its rows once. Loose (fix): each listed id is a row of that phase, no id twice in one
    size, every size present; an optional `performance` object may leave a size out."""
    phases = {}
    for row in rows:
        phases.setdefault(phase_of(row["id"]), []).append(row["id"])
    multi = {str(p): ids for p, ids in phases.items() if len(ids) > 1}
    if not isinstance(groups, dict):
        bad(f"{skill}.groups", "must be an object")
    for phase in groups:
        if phase not in multi:
            bad(f"{skill}.groups.{phase}", "not a phase with two or more rows")
    for phase, ids in multi.items():
        if phase not in groups:
            if strict:
                bad(f"{skill}.groups.{phase}", "missing")
            continue
        where = f"{skill}.groups.{phase}"
        if strict:
            only_keys(groups[phase], where, SIZES)
        else:
            only_keys(groups[phase], where, SIZES + ("performance",), SIZES)
        variants = [(groups[phase], where, SIZES)]
        if not strict and "performance" in groups[phase]:
            perf = groups[phase]["performance"]
            only_keys(perf, f"{where}.performance", SIZES, ())
            variants.append((perf, f"{where}.performance", tuple(s for s in SIZES if s in perf)))
        for by_size, base, sizes in variants:
            for size in sizes:
                check_group_list(by_size[size], f"{base}.{size}", ids, strict)


def check_group_list(listed, where, ids, strict):
    if strict:
        rule = f"must list each of {', '.join(ids)} exactly once"
    else:
        rule = f"must list rows of {', '.join(ids)}, each at most once"
    if not isinstance(listed, list) or not all(isinstance(g, list) and g for g in listed):
        bad(where, rule)
    flat = [i for g in listed for i in g]
    if strict and sorted(flat) != sorted(ids):
        bad(where, rule)
    if not strict and (any(i not in ids for i in flat) or len(set(flat)) != len(flat)):
        bad(where, rule)


def load(root):
    path = root / JSON_PATH
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        raise Fail(f"sizes.py: {JSON_PATH}: {e}")
    only_keys(data, "", ("feat", "fix"))
    only_keys(data["feat"], "feat", ("rows", "groups"))
    only_keys(data["fix"], "fix", ("rows", "groups"), ("rows",))
    for skill in ("feat", "fix"):
        rows = data[skill]["rows"]
        if not isinstance(rows, list) or not rows:
            bad(f"{skill}.rows", "must be a non-empty list")
        seen = set()
        for k, row in enumerate(rows):
            check_row(row, f"{skill}.rows[{k}]", skill)
            if row["id"] in seen:
                bad(f"{skill}.rows[{k}].id", f"duplicate id {row['id']}")
            seen.add(row["id"])
    check_groups(data["feat"]["groups"], data["feat"]["rows"], "feat", True)
    check_groups(data["fix"].get("groups", {}), data["fix"]["rows"], "fix", False)
    have = {int(re.match(r"\d+", r["id"]).group()) for r in data["feat"]["rows"]}
    if have != {p for p, _ in COLUMNS}:
        bad("feat.rows", f"phases {sorted(have)} differ from the diagram's {[p for p, _ in COLUMNS]}")
    return data


# ---- the diagram ------------------------------------------------------------------------------

def strongest(pairs):
    return max(pairs, key=lambda p: MODELS.index(p[0])), max(pairs, key=lambda p: EFFORTS.index(p[1]))


def d2(data):
    rows = {r["id"]: {size: (r[size]["model"], r[size]["effort"]) for size in SIZES}
            for r in data["feat"]["rows"]}
    groups = data["feat"]["groups"]
    columns = []
    for phase, title in COLUMNS:
        by_size = groups.get(str(phase)) or {size: [[str(phase)]] for size in SIZES}
        columns.append((title, by_size))
    out = [f"grid-rows: {len(SIZES) + 1}", f"grid-columns: {len(columns) + 1}", "grid-gap: 6", ""]
    blank = "style: {fill: transparent; stroke: transparent}"
    out.append(f'h0: "" {{{blank}}}')
    for j, (title, _) in enumerate(columns, 1):
        out.append(f'h{j}: "{title}" {{width: {WIDTH}; height: 30; '
                   f'style: {{fill: transparent; stroke: transparent; font-color: "#6b7385"}}}}')
    for row_no, size in enumerate(SIZES):
        out.append(f'r{row_no}: "{size}" {{width: 80; {blank}}}')
        for j, (_, by_size) in enumerate(columns):
            cells = []
            for group in by_size[size]:
                (model, _), (_, effort) = strongest([rows[i][size] for i in group])
                cells.append((model, effort))
            cid = f"c{row_no}_{j}"
            n = len(cells)
            style = 'stroke: transparent; border-radius: {}'
            if n == 1:
                model, effort = cells[0]
                out.append(f'{cid}: "{model}\\n{effort}" {{width: {WIDTH}; height: 60; '
                           f'style: {{fill: "{FILL[model]}"; font-color: "{FONT[model]}"; '
                           f'{style.format(6)}}}}}')
                continue
            out += [f'{cid}: "" {{', "  grid-rows: 1", f"  grid-columns: {n}", f"  grid-gap: {GAP}",
                    f"  {blank}"]
            width = (WIDTH - GAP * (n - 1)) // n
            for k, (model, effort) in enumerate(cells):
                label = model[0].upper() + (f"\\n{effort.replace('medium', 'med')}" if n <= 3 else "")
                out.append(f'  l{k}: "{label}" {{width: {width}; height: 60; '
                           f'style: {{fill: "{FILL[model]}"; font-color: "{FONT[model]}"; '
                           f'font-size: 13; {style.format(4)}}}}}')
            out.append("}")
    return "\n".join(out)


# ---- the tables -------------------------------------------------------------------------------

def table(header, rows):
    """A GFM table, every column padded to its widest cell (counted in code points)."""
    widths = [max(len(r[i]) for r in [header] + rows) for i in range(len(header))]
    line = lambda cells: "| " + " | ".join(c.ljust(w) for c, w in zip(cells, widths)) + " |"
    rule = "| " + " | ".join("-" * w for w in widths) + " |"
    return "\n".join([line(header), rule] + [line(r) for r in rows])


def spawn(row, size):
    return f"{row[size]['model']} · {row[size]['effort']}"


def feat_matrix(rows):
    first = ["1", "Brief", "your session", "session", "session", "session", "session, plus capability map"]
    body = [[r["id"], r["label"], f"`{r['agent']}`", *[spawn(r, s) for s in SIZES],
             "first capability's size" if r["id"] == "1" else "—"] for r in rows]
    return table(["#", "Phase", "Agent", *SIZES, "huge"], [first] + body)


def fix_matrix(rows):
    return table(["#", "Phase", "Agent", *SIZES],
                 [[r["id"], r["label"], f"`{r['agent']}`", *[spawn(r, s) for s in SIZES]] for r in rows])


def brief_sentence(data):
    row = next(r for r in data["feat"]["rows"] if r["id"] == "1")
    groups = []
    for size in SIZES:
        if groups and groups[-1][1] == row[size]:
            groups[-1][0].append(size)
        else:
            groups.append(([size], row[size]))

    def join_sizes(sizes):
        if len(sizes) <= 2:
            return " and ".join(sizes)
        return ", ".join(sizes[:-1]) + " and " + sizes[-1]

    return ", ".join(f"{join_sizes(s)} `{v['model']}` · `{v['effort']}`" for s, v in groups)


def agents_table(region, data):
    """Replace the `small size` cells of the agents table in region; keep every other cell."""
    where = f"sizes.py: {WORKFLOW}: agents table: "
    lines = [ln for ln in region.splitlines() if ln.strip()]
    split = lambda ln: [c.strip() for c in ln.strip().strip("|").split("|")]
    if len(lines) < 3:
        raise Fail(where + "no header, separator and rows")
    header = split(lines[0])
    if "Agent" not in header or "small size" not in header:
        raise Fail(where + "header lacks Agent or small size")
    agent_col, small_col = header.index("Agent"), header.index("small size")
    values = {}
    for row in data["feat"]["rows"] + data["fix"]["rows"]:
        values.setdefault(row["agent"], []).append(row)
    body, seen = [], set()
    for ln in lines[2:]:
        cells = split(ln)
        if len(cells) != len(header):
            raise Fail(where + f"{len(cells)} cells, header has {len(header)}: {ln[:40]}")
        agent = cells[agent_col].strip("`")
        if agent not in values:
            raise Fail(where + f"{agent} has no row in sizes.json")
        seen.add(agent)
        distinct = {}
        for row in values[agent]:
            distinct.setdefault(spawn(row, "small"), row["label"].lower())
        if len(distinct) == 1:
            cells[small_col] = next(iter(distinct))
        else:
            cells[small_col] = ", ".join(f"{value} ({label})" for value, label in distinct.items())
        body.append(cells)
    for agent in values:
        if agent not in seen:
            raise Fail(where + f"no line for {agent}")
    return table(header, body)


# ---- the marked regions -----------------------------------------------------------------------

def render(name, region, data):
    if name == "feat-matrix":
        return feat_matrix(data["feat"]["rows"])
    if name == "fix-matrix":
        return fix_matrix(data["fix"]["rows"])
    if name == "agents-table":
        return agents_table(region, data)
    return brief_sentence(data)


def markers(path, text, names):
    """Return {name: (end of start marker, start of end marker)}; Fail naming every bad marker."""
    found = {}
    for m in MARKER_RE.finditer(text):
        found.setdefault(m.group(2), {"start": [], "end": []})[m.group(1)].append(m)
    errors = []
    for name in sorted(set(found) - set(names)):
        errors.append(f"sizes.py: {path}: marker {name}: unknown")
    spans = {}
    for name in names:
        s, e = (found.get(name, {}).get(k, []) for k in ("start", "end"))
        if not s and not e:
            errors.append(f"sizes.py: {path}: marker {name}: missing")
        elif len(s) > 1 or len(e) > 1:
            errors.append(f"sizes.py: {path}: marker {name}: duplicated")
        elif not s or not e or e[0].start() < s[0].end():
            errors.append(f"sizes.py: {path}: marker {name}: unpaired")
        else:
            spans[name] = (s[0].end(), e[0].start())
    if errors:
        raise Fail("\n".join(errors))
    return spans


TSV_HEADER = [
    "# Generated by docs/diagrams/sizes.py from sizes.json; edit that and run `mise run diagrams`.",
    "# In an install (no sizes.py), tune a row by editing its `row` line and every `group` line"
    " that names it:",
    "# each group line carries its own model and effort (the strongest of its rows), and groups"
    " are what review phases spawn.",
    "# row\tskill\trow\tagent\tlens\tsize\tmodel\teffort",
    "# group\tskill\tphase\tsize\tvariant\trows\tlenses\tmodel\teffort",
]


def row_lens(skill, row):
    if skill == "fix":
        return row.get("lens", "-")
    return row["id"] if re.fullmatch(r"[47][a-z]", row["id"]) else "-"


def tsv(data):
    """The text of sizes.tsv: one `row` line per row and size, then one `group` line per phase,
    size, variant and group, each group on the strongest model and effort among its rows."""
    out = list(TSV_HEADER)
    for skill in ("feat", "fix"):
        for row in data[skill]["rows"]:
            for size in SIZES:
                out.append("\t".join(["row", skill, row["id"], row["agent"], row_lens(skill, row),
                                      size, row[size]["model"], row[size]["effort"]]))
    for skill in ("feat", "fix"):
        rows = {r["id"]: r for r in data[skill]["rows"]}
        for phase, by_size in data[skill].get("groups", {}).items():
            perf = by_size.get("performance", {})
            for size in SIZES:
                for variant, listed in (("default", by_size[size]), ("performance", perf.get(size))):
                    for group in listed or []:
                        (model, _), (_, effort) = strongest(
                            [(rows[i][size]["model"], rows[i][size]["effort"]) for i in group])
                        lenses = [row_lens(skill, rows[i]) for i in group]
                        out.append("\t".join(["group", skill, phase, size, variant, "+".join(group),
                                              "+".join(lenses), model, effort]))
    return "\n".join(out) + "\n"


def regenerate(root, data):
    """Return {path: new text} for every target whose text changes; nothing is written here."""
    changed, errors = {}, []
    try:
        with open(root / TSV_PATH, encoding="utf-8", newline="") as f:
            old = f.read()
    except FileNotFoundError:
        old = None
    except OSError as e:
        errors.append(f"sizes.py: {TSV_PATH}: {e.strerror}")
        old = ""
    new_tsv = tsv(data)
    if old != new_tsv:
        changed[TSV_PATH] = new_tsv
    for path, names in TARGETS.items():
        try:
            with open(root / path, encoding="utf-8", newline="") as f:
                text = f.read()
        except OSError as e:
            errors.append(f"sizes.py: {path}: {e.strerror}")
            continue
        try:
            spans = markers(path, text, names)
            new = text
            for name, (start, end) in sorted(spans.items(), key=lambda kv: -kv[1][0]):
                body = render(name, text[start:end], data)
                new = new[:start] + (f"\n\n{body}\n\n" if names[name] == "block" else body) + new[end:]
        except Fail as e:
            errors.append(str(e))
            continue
        if new != text:
            changed[path] = new
    if errors:
        raise Fail("\n".join(errors))
    return changed


def main(argv):
    parser = argparse.ArgumentParser(prog="sizes.py")
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parents[2])
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--d2", action="store_true")
    args = parser.parse_args(argv)
    root, mode_d2, mode_check = args.root, args.d2, args.check
    try:
        data = load(root)
        if mode_d2:
            print(d2(data))
            return 0
        changed = regenerate(root, data)
    except Fail as e:
        print(e, file=sys.stderr)
        return 2
    if mode_check:
        for path in changed:
            if path == TSV_PATH:
                print("sizes.tsv is stale: run mise run diagrams", file=sys.stderr)
            else:
                print(f"{path}: differs from {JSON_PATH}; run mise run diagrams", file=sys.stderr)
        return 1 if changed else 0
    for path, text in changed.items():
        with open(root / path, "w", encoding="utf-8", newline="") as f:
            f.write(text)
        print(f"updated {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
