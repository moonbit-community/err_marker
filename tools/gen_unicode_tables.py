#!/usr/bin/env python3
"""Generate src/internal/ucd/tables.mbt from the Unicode Character Database.

The UCD version and the sha256 of every input file are pinned in
tools/ucd/SOURCES. Files are read from tools/ucd/cache/ (or --ucd DIR) and
downloaded from unicode.org when missing; every file is checked against its
sha256 before use.

usage:
  python3 tools/gen_unicode_tables.py           # regenerate the tables
  python3 tools/gen_unicode_tables.py --check   # fail if the checked-in file differs

After regenerating, run `moon fmt`. --check compares the Unicode version and
the numbers in every table, not the layout, so formatting never makes it fail.
"""

import argparse
import hashlib
import os
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = os.path.join(ROOT, "tools", "ucd", "SOURCES")
OUT = os.path.join(ROOT, "src", "internal", "ucd", "tables.mbt")
TEST_OUT = os.path.join(ROOT, "src", "internal", "ucd", "grapheme_break_conformance_test.mbt")
MAX = 0x110000

# Grapheme_Cluster_Break values, in the order of the MoonBit enum `Gcb`.
GCB = ["Other", "CR", "LF", "Control", "Extend", "ZWJ", "Regional_Indicator",
       "Prepend", "SpacingMark", "L", "V", "T", "LV", "LVT"]
# Indic_Conjunct_Break values, in the order of the MoonBit enum `Incb`.
INCB = ["None", "Linker", "Consonant", "Extend"]


def read_sources():
    version, files = None, []
    for line in open(SOURCES, encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("version "):
            version = line.split()[1]
        else:
            sha, path = line.split()
            files.append((path, sha))
    if version is None:
        sys.exit("SOURCES has no version line")
    return version, dict(files)


def fetch(version, files, ucd_dir):
    paths = {}
    for path, sha in files.items():
        local = os.path.join(ucd_dir, path)
        if not os.path.exists(local):
            os.makedirs(os.path.dirname(local), exist_ok=True)
            url = f"https://www.unicode.org/Public/{version}/ucd/{path}"
            with urllib.request.urlopen(url, timeout=60) as r:
                data = r.read()
            with open(local, "wb") as f:
                f.write(data)
        digest = hashlib.sha256(open(local, "rb").read()).hexdigest()
        if digest != sha:
            sys.exit(f"sha256 mismatch for {path}: {digest} != {sha}")
        paths[path] = local
    return paths


def records(path):
    """Yield (first, last, fields) for each data line; fields are stripped."""
    for line in open(path, encoding="utf-8"):
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        fields = [f.strip() for f in line.split(";")]
        cps = fields[0]
        if ".." in cps:
            a, b = cps.split("..")
            yield int(a, 16), int(b, 16), fields[1:]
        else:
            c = int(cps, 16)
            yield c, c, fields[1:]


def ranges(values, keep):
    """Merge runs of equal values into (first, last, value), keeping `keep(v)`."""
    out, start = [], None
    for cp in range(MAX + 1):
        v = values[cp] if cp < MAX else None
        if start is not None and (cp == MAX or v != values[start]):
            if keep(values[start]):
                out.append((start, cp - 1, values[start]))
            start = None
        if cp < MAX and start is None:
            start = cp
    return out


def build(paths):
    eaw = ["N"] * MAX
    for a, b, f in records(paths["EastAsianWidth.txt"]):
        for cp in range(a, b + 1):
            eaw[cp] = f[0]
    gc = ["Cn"] * MAX
    for a, b, f in records(paths["extracted/DerivedGeneralCategory.txt"]):
        for cp in range(a, b + 1):
            gc[cp] = f[0]
    di = [False] * MAX
    incb = ["None"] * MAX
    for a, b, f in records(paths["DerivedCoreProperties.txt"]):
        if f[0] == "Default_Ignorable_Code_Point":
            for cp in range(a, b + 1):
                di[cp] = True
        elif f[0] == "InCB":
            for cp in range(a, b + 1):
                incb[cp] = f[1]
    ext = [False] * MAX
    for a, b, f in records(paths["emoji/emoji-data.txt"]):
        if f[0] == "Extended_Pictographic":
            for cp in range(a, b + 1):
                ext[cp] = True
    gcb = ["Other"] * MAX
    for a, b, f in records(paths["auxiliary/GraphemeBreakProperty.txt"]):
        for cp in range(a, b + 1):
            gcb[cp] = f[0]
    unknown = (set(gcb) - set(GCB)) | (set(incb) - set(INCB))
    if unknown:
        sys.exit(f"unknown property values: {sorted(unknown)}")
    wide = [v in ("W", "F") for v in eaw]
    amb = [v == "A" for v in eaw]
    zero = [gc[cp] in ("Mn", "Me", "Cf") or di[cp] for cp in range(MAX)]
    return {
        "wide": ranges(wide, bool),
        "ambiguous": ranges(amb, bool),
        "zero_width": ranges(zero, bool),
        "extended_pictographic": ranges(ext, bool),
        "gcb": ranges([GCB.index(v) for v in gcb], lambda v: v != 0),
        "incb": ranges([INCB.index(v) for v in incb], lambda v: v != 0),
    }


def fmt_array(name, nums, per_line=8):
    lines = [f"let {name} : FixedArray[Int32] = ["]
    for i in range(0, len(nums), per_line):
        lines.append("  " + ", ".join(f"0x{n:X}" if n > 9 else str(n) for n in nums[i:i + per_line]) + ",")
    lines.append("]")
    return "\n".join(lines)


def render(version, tables):
    parts = [
        "// Generated by tools/gen_unicode_tables.py from the Unicode Character",
        f"// Database {version}. Do not edit: change the generator and run it again.",
        "",
        "///|",
        "/// The Unicode version the tables in this package are generated from.",
        f'pub let unicode_version : String = "{version}"',
    ]
    for name, rs in tables.items():
        parts += ["", "///|", fmt_array(f"{name}_first", [r[0] for r in rs])]
        parts += ["", "///|", fmt_array(f"{name}_last", [r[1] for r in rs])]
        if name in ("gcb", "incb"):
            parts += ["", "///|", fmt_array(f"{name}_value", [r[2] for r in rs])]
    return "\n".join(parts) + "\n"


def arrays_of(text):
    """The Unicode version and every table of a tables.mbt text, layout-free."""
    version = re.search(r'unicode_version : String = "([^"]+)"', text)
    tables = {}
    for name, body in re.findall(r"let (\w+) : FixedArray\[\w+\] = \[(.*?)\]", text, re.S):
        tables[name] = [int(n, 0) for n in re.findall(r"0x[0-9A-Fa-f]+|\d+", body)]
    return (version.group(1) if version else None), tables


def conformance(path, version):
    """GraphemeBreakTest.txt as MoonBit test data: code points and boundaries."""
    cps_all, cps_off, bnd_all, bnd_off = [], [0], [], [0]
    for line in open(path, encoding="utf-8"):
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        toks = line.split()
        cps, bnds, n = [], [], 0
        for t in toks:
            if t == "\u00f7":
                bnds.append(n)
            elif t == "\u00d7":
                pass
            else:
                cps.append(int(t, 16))
                n += 1
        cps_all += cps
        cps_off.append(len(cps_all))
        bnd_all += bnds
        bnd_off.append(len(bnd_all))
    parts = [
        "// Generated by tools/gen_unicode_tables.py from GraphemeBreakTest.txt of the",
        f"// Unicode Character Database {version}. Do not edit.",
        "",
        "///|",
        fmt_array("conformance_code_points", cps_all),
        "",
        "///|",
        fmt_array("conformance_code_point_offsets", cps_off),
        "",
        "///|",
        fmt_array("conformance_boundaries", bnd_all),
        "",
        "///|",
        fmt_array("conformance_boundary_offsets", bnd_off),
        "",
        "///|",
        "test \"GraphemeBreakTest.txt: every case\" {",
        "  let cases = conformance_code_point_offsets.length() - 1",
        "  assert_eq(cases, " + str(len(cps_off) - 1) + ")",
        "  for i in 0..<cases {",
        "    let text = StringBuilder()",
        "    for k in conformance_code_point_offsets[i]..<conformance_code_point_offsets[i + 1] {",
        "      text.write_char(Int::unsafe_to_char(conformance_code_points[k]))",
        "    }",
        "    let expected = []",
        "    for k in conformance_boundary_offsets[i]..<conformance_boundary_offsets[i + 1] {",
        "      expected.push(conformance_boundaries[k])",
        "    }",
        "    let actual = @ucd.cluster_boundaries(text.to_string())",
        "    assert_eq((i, actual), (i, expected))",
        "  }",
        "}",
    ]
    return "\n".join(parts) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--ucd", default=os.path.join(ROOT, "tools", "ucd", "cache"))
    args = ap.parse_args()
    version, files = read_sources()
    paths = fetch(version, files, args.ucd)
    text = render(version, build(paths))
    test_text = conformance(paths["auxiliary/GraphemeBreakTest.txt"], version)
    if args.check:
        current = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else ""
        if arrays_of(current) != arrays_of(text):
            sys.exit(f"{OUT} is out of date; run tools/gen_unicode_tables.py")
        current = open(TEST_OUT, encoding="utf-8").read() if os.path.exists(TEST_OUT) else ""
        if arrays_of(current)[1] != arrays_of(test_text)[1]:
            sys.exit(f"{TEST_OUT} is out of date; run tools/gen_unicode_tables.py")
        print("tables are up to date")
        return
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    with open(TEST_OUT, "w", encoding="utf-8") as f:
        f.write(test_text)
    print(f"wrote {OUT} and {TEST_OUT}")


if __name__ == "__main__":
    main()
