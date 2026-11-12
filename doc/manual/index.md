# err_marker

<!-- Overview page. Keep this order: one line naming the documented release, Overview, Install, Pages, the exported items grouped by purpose, Where to read next, Validation. Details belong on the package pages. -->

This manual documents version `v0.1.3` of `KCN-judu/err_marker`.

## Overview

`err_marker` shows a reader where an error is. It renders a sequence (the
command-line arguments of a program, a list of tokens, or a string), draws a
line of markers under the part that is wrong, and prints a message below:

```text
sudoku export a.txt sovle out.txt
                    ^^^^^
Error(ArgError): unknown mode 'sovle'
```

The library is one package with two types and four functions. It does not
read files, track line numbers or colour its output; it turns a sequence, a
position and a message into three lines of text.

The 0.1 series has known limits with non-ASCII text; they are listed in the [design](design/core.md) and
tracked for 0.2.0 in
[#5](https://github.com/moonbit-community/err_marker/issues/5).

## Install

```bash
moon add KCN-judu/err_marker@0.1.3
```

Then import `"KCN-judu/err_marker"` in your `moon.pkg`; the package is
available as `@err_marker`. The module needs the MoonBit toolchain 0.10 or
later (`moonc` ≥ 0.10) and depends only on `moonbitlang/core`.

## Pages

The module is one MoonBit package at `src`, documented as `core`.

| Part | Tutorial | API | Design |
| --- | --- | --- | --- |
| `core`: sequences, error data and marking | [tutorial](tutorial/core.md) | [API](api/core.md) | [design](design/core.md) |

## Exported items

- Sequences: `Sequence`, `Sequence::from_array`, `Sequence::from_string`
- Error data: `ErrorData`, `ErrorData::make`
- Rendering: `ErrorData::mark`

## Where to read next

- New to the package: the [tutorial](tutorial/core.md) builds a small argument
  checker and prints its errors.
- Using it in a program: keep the [API](api/core.md) at hand.
- Contributing, or relying on exact output: read the [design](design/core.md),
  which states how the marker column is computed and where the 0.1 model
  breaks, and [CONTRIBUTING.md](https://github.com/moonbit-community/err_marker/blob/main/CONTRIBUTING.md).

## Validation

Recommended release checks:

```bash
moon check --target all --deny-warn
just test-all
```

`just test-all` runs the tests on wasm, wasm-gc, js and native, in debug and
release.
