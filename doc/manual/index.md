# err_marker

<!-- Overview page. Keep this order: one line naming the documented release, Overview, Install, Pages, the exported items grouped by purpose, Where to read next, Validation. Details belong on the package pages. -->

This manual documents version `v0.2.0` of `KCN-judu/err_marker`.

## Overview

`err_marker` shows a reader where an error is. It renders a sequence (the
command-line arguments of a program, a list of tokens, or a string), draws
markers under the places that are wrong, and prints messages and a header:

```text
sudoku export a.txt sovle out.txt
                    ^^^^^ did you mean 'solve'?
error[E01]: unknown mode 'sovle'
```

A `Report` holds a severity, a message, marks and notes; `Report::render`
turns it and a sequence into text. Columns follow Unicode 18.0.0, so wide
characters, emoji and combining marks line up, and tabs are expanded. The
`cursor` package exposes the column arithmetic, and the `error_report`
package converts reports for `marianoguerra/error-report`. The 0.1 API,
`ErrorData::mark`, is deprecated.

## Install

```bash
moon add KCN-judu/err_marker@0.2.0
```

Then import `"KCN-judu/err_marker"` in your `moon.pkg`; the package is
available as `@err_marker`. The module needs the MoonBit toolchain 0.10 or
later (`moonc` ≥ 0.10) and depends on `moonbitlang/core` and, for the
`error_report` adapter only, `marianoguerra/error-report`.

## Pages

The module has three public packages: the root package at `src`, documented
as `core`; `src/cursor`, documented as `cursor`; and `src/error_report`,
documented as `error_report`.

| Part | Tutorial | API | Design |
| --- | --- | --- | --- |
| `core`: sequences, reports and rendering | [tutorial](tutorial/core.md) | [API](api/core.md) | [design](design/core.md) |
| `cursor`: terminal columns of text (Unicode 18.0.0) | [tutorial](tutorial/cursor.md) | [API](api/cursor.md) | [design](design/cursor.md) |
| `error_report`: conversion to `marianoguerra/error-report` | [tutorial](tutorial/error_report.md) | [API](api/error_report.md) | [design](design/error_report.md) |

## Exported items

- Sequences: `Sequence`, `Sequence::from_array`, `Sequence::from_string`
- Reports: `Severity`, `Style`, `Span`, `Mark`, `Report`, `Report::render`, `Sequence::from_args`, `Sequence::rendered`, `Sequence::locate`, `utf16_to_scalar`
- Cursor (`@cursor`): `Pos`, `Move`, `Model`, `clusters`
- Adapter (`@error_report`): `to_error_report`
- Deprecated: `ErrorData`, `ErrorData::make`, `ErrorData::mark`

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
