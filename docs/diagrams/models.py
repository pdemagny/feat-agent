#!/usr/bin/env python3
"""Print the D2 source of docs/img/models.svg: one cell per phase and size, coloured by model.

Read from the size table in .apm/skills/feat/SKILL.md, so changing the table and
running `mise run diagrams` changes the picture. A split cell is a phase that runs
several reviewers in parallel; each group of lenses runs on the strongest model and
effort among its rows, as the skill says under the table.
"""
import pathlib
import re
import sys

SKILL = pathlib.Path(__file__).resolve().parents[2] / ".apm/skills/feat/SKILL.md"
SIZES = ("small", "medium", "large")
MODELS = ("haiku", "sonnet", "opus")
EFFORTS = ("low", "medium", "high", "xhigh", "max")
# Columns: (title, row ids grouped per reviewer, per size). The groups mirror the
# paragraphs under the size table.
ONE_PER_LENS_4 = [["4a"], ["4b"], ["4c"]]
ONE_PER_LENS_7 = [["7a"], ["7b"], ["7c"], ["7d"], ["7e"]]
COLUMNS = [
    ("Brief review", {s: [["1"]] for s in SIZES}),
    ("Specify", {s: [["2"]] for s in SIZES}),
    ("Plan", {s: [["3"]] for s in SIZES}),
    ("Design review", {"small": [["4a", "4b", "4c"]], "medium": ONE_PER_LENS_4, "large": ONE_PER_LENS_4}),
    ("Tasks", {s: [["5"]] for s in SIZES}),
    ("Implement", {s: [["6"]] for s in SIZES}),
    ("Code review", {"small": [["7a", "7b"], ["7c", "7d", "7e"]], "medium": ONE_PER_LENS_7,
                     "large": ONE_PER_LENS_7}),
    ("Ship", {s: [["8"]] for s in SIZES}),
]
FILL = {"haiku": "#e3e8fb", "sonnet": "#8fa3ee", "opus": "#3443ae"}
FONT = {"haiku": "#24305e", "sonnet": "#101736", "opus": "#ffffff"}
WIDTH, GAP = 126, 3


def size_table(text):
    """Map row id ('1', '4a', '7e', ...) to {size: (model, effort)}."""
    section = text.split("## Size table", 1)[1].split("\n## ", 1)[0]
    rows = {}
    for line in section.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        m = re.match(r"(\d[a-e]?) ", cells[0])
        if not m or len(cells) != 6:
            continue
        rows[m.group(1)] = {s: tuple(c.split(" · ")) for s, c in zip(SIZES, cells[3:])}
    if not rows:
        sys.exit(f"no size table found in {SKILL}")
    return rows


def strongest(pairs):
    return max(pairs, key=lambda p: MODELS.index(p[0])), max(pairs, key=lambda p: EFFORTS.index(p[1]))


def main():
    rows = size_table(SKILL.read_text())
    out = [f"grid-rows: {len(SIZES) + 1}", f"grid-columns: {len(COLUMNS) + 1}", "grid-gap: 6", ""]
    blank = "style: {fill: transparent; stroke: transparent}"
    out.append(f'h0: "" {{{blank}}}')
    for j, (title, _) in enumerate(COLUMNS, 1):
        out.append(f'h{j}: "{title}" {{width: {WIDTH}; height: 30; style: {{fill: transparent; stroke: transparent; '
                   f'font-color: "#6b7385"}}}}')
    for r, size in enumerate(SIZES):
        out.append(f'r{r}: "{size}" {{width: 80; {blank}}}')
        for j, (_, groups) in enumerate(COLUMNS):
            cells = []
            for group in groups[size]:
                (model, _), (_, effort) = strongest([rows[i][size] for i in group])
                cells.append((model, effort))
            cid = f"c{r}_{j}"
            n = len(cells)
            style = 'stroke: transparent; border-radius: {}'
            if n == 1:
                model, effort = cells[0]
                out.append(f'{cid}: "{model}\\n{effort}" {{width: {WIDTH}; height: 60; style: {{fill: "{FILL[model]}"; '
                           f'font-color: "{FONT[model]}"; {style.format(6)}}}}}')
                continue
            out += [f'{cid}: "" {{', "  grid-rows: 1", f"  grid-columns: {n}", f"  grid-gap: {GAP}", f"  {blank}"]
            width = (WIDTH - GAP * (n - 1)) // n
            for k, (model, effort) in enumerate(cells):
                label = model[0].upper() + (f"\\n{effort.replace('medium', 'med')}" if n <= 3 else "")
                out.append(f'  l{k}: "{label}" {{width: {width}; height: 60; style: {{fill: "{FILL[model]}"; '
                           f'font-color: "{FONT[model]}"; font-size: 13; {style.format(4)}}}}}')
            out.append("}")
    print("\n".join(out))


if __name__ == "__main__":
    main()
