#!/usr/bin/env python3
"""Regenerate .github/demo/src/scenes.json from the real renderer.

1. Renders every scene with `Report::render(..., color=true)` through a
   temporary test in the root package and parses the ANSI colours.
2. Lays every line out with `@cursor` (clusters and display widths) through a
   temporary test in the cursor package.
3. Writes one cell per grapheme cluster: text, column, width and colour.

The temporary test files are removed afterwards. Run from anywhere:

    python3 .github/demo/capture.py
"""

import json
import os
import re
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, ".github", "demo", "src", "scenes.json")
RENDER_TEST = os.path.join(ROOT, "src", "zz_demo_capture_test.mbt")
LAYOUT_TEST = os.path.join(ROOT, "src", "cursor", "zz_demo_layout_test.mbt")

# The scenes of the demo, as MoonBit expressions that render with colour.
SCENES = {
    "argv": """@err_marker.Report::new(Error, "unknown mode 'sovle'")
    .with_code("E01")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(3, 4), message="did you mean 'solve'?"))
    .render(@err_marker.Sequence::from_args(["sudoku", "export", "a.txt", "sovle", "out.txt"]), color=true)""",
    "missing": """@err_marker.Report::new(Error, "export needs an output path")
    .with_mark(@err_marker.Mark::secondary(@err_marker.Span::new(1, 3)))
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::point(3), message="here"))
    .render(@err_marker.Sequence::from_args(["sudoku", "export", "a.txt"]), color=true)""",
    "cjk": """@err_marker.Report::new(Warning, "duplicate digit in row 1")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(4, 5), message="again here"))
    .with_mark(@err_marker.Mark::secondary(@err_marker.Span::new(1, 2), message="first"))
    .with_note("each digit appears once per row")
    .render(@err_marker.Sequence::from_string("数5独.5"), color=true)""",
    "emoji": """@err_marker.Report::new(Error, "cannot split a grapheme cluster")
    .with_code("E42")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(4, 5), message="whole family"))
    .with_mark(@err_marker.Mark::secondary(@err_marker.Span::new(10, 11), message="e + U+0301"))
    .render(@err_marker.Sequence::from_string("hi \\u{1F468}\\u{200D}\\u{1F469}\\u{200D}\\u{1F467} e\\u{301}!"), color=true)""",
}

COLORS = {"1;31": "error", "1;33": "warning", "34": "secondary", "1": "bold"}


def moon_test(package):
    out = subprocess.run(
        ["moon", "test", "--target", "native", "-p", package],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout
    return out


def literal(s):
    out = '"'
    for ch in s:
        if ch in '"\\':
            out += "\\" + ch
        elif ord(ch) < 0x20 or ord(ch) > 0x7E:
            out += "\\u{%X}" % ord(ch)
        else:
            out += ch
    return out + '"'


def render_scenes():
    body = ["///|", 'test "demo capture" {']
    for name, expr in SCENES.items():
        body.append(f'  println("@@@ {name}")')
        body.append(f"  println({expr})")
    body.append("}")
    with open(RENDER_TEST, "w", encoding="utf-8") as f:
        f.write("\n".join(body) + "\n")
    try:
        out = moon_test("KCN-judu/err_marker")
    finally:
        os.remove(RENDER_TEST)
    out = out[out.index("@@@ "):]
    scenes = {}
    for block in out.split("@@@ ")[1:]:
        name, _, text = block.partition("\n")
        lines = []
        for line in text.split("\n"):
            if line.startswith("Total tests") or line == "":
                break
            segs, color, pos = [], None, 0
            for m in re.finditer(r"\x1b\[([0-9;]+)m", line):
                if m.start() > pos:
                    segs.append((line[pos:m.start()], color))
                color = COLORS.get(m.group(1)) if m.group(1) != "0" else None
                pos = m.end()
            if pos < len(line):
                segs.append((line[pos:], color))
            lines.append(segs)
        scenes[name.strip()] = lines
    return scenes


def layout(scenes):
    keys, body = [], ["///|", 'test "demo layout" {', "  let m = @cursor.Model::new()"]
    for name, lines in scenes.items():
        for i, segs in enumerate(lines):
            keys.append((name, i))
            text = "".join(t for t, _ in segs)
            body += [
                f'  println("@@ {name} {i}")',
                "  let mut col = 0",
                f"  for g in @cursor.clusters({literal(text)}) {{",
                "    let w = m.cluster_width(g)",
                '    println("\\{col} \\{w} \\{g.to_array().length()}")',
                "    col += w",
                "  }",
            ]
    body.append("}")
    with open(LAYOUT_TEST, "w", encoding="utf-8") as f:
        f.write("\n".join(body) + "\n")
    try:
        out = moon_test("KCN-judu/err_marker/cursor")
    finally:
        os.remove(LAYOUT_TEST)
    lay, key = {}, None
    for line in out[out.index("@@ "):].split("\n"):
        if line.startswith("@@ "):
            _, n, i = line.split()
            key = (n, int(i))
            lay[key] = []
        elif re.match(r"^\d+ \d+ \d+$", line):
            lay[key].append(tuple(map(int, line.split())))
    return lay


def main():
    scenes = render_scenes()
    lay = layout(scenes)
    result = {}
    for name, lines in scenes.items():
        rows = []
        for i, segs in enumerate(lines):
            chars = [(ch, c) for t, c in segs for ch in t]
            cells, p = [], 0
            for col, w, k in lay[(name, i)]:
                text = "".join(ch for ch, _ in chars[p:p + k])
                color = chars[p][1]
                p += k
                if text != " ":
                    cells.append({"t": text, "col": col, "w": w, "c": color})
            rows.append(cells)
        result[name] = rows
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False)
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
