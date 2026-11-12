# err_marker

[![Maintainer](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu)
[![License](https://img.shields.io/badge/License-Apache--2.0-blue)](./LICENSE)
![State](https://img.shields.io/badge/State-active-success)

<p align="center">
  <img src="./.github/assets/demo.gif" width="720" alt="err_marker marking a typo in command-line arguments, a missing argument, CJK text and an emoji ZWJ sequence">
</p>

`KCN-judu/err_marker` shows a reader where an error is. It renders a sequence
(command-line arguments, tokens or a string), draws markers under the places
that are wrong, and prints messages, notes and a header. Positions are element
indices or character indices; spans are clamped to the sequence and snapped to
extended grapheme clusters (UAX #29), and columns follow East Asian Width
(UAX #11) from tables generated from the Unicode Character Database 18.0.0, so
CJK text, emoji and combining marks line up. The output is the same, byte for
byte, on wasm, wasm-gc, js and native.

## Install

```bash
moon add KCN-judu/err_marker@0.2.0
```

The module needs the MoonBit toolchain 0.10 or later (`moonc` ≥ 0.10). Import
the packages you use in your `moon.pkg`:

```moonbit nocheck
import {
  "KCN-judu/err_marker",
  "KCN-judu/err_marker/cursor",
}
```

## Quick start

```moonbit
///|
test "err_marker quick start" {
  // A typo in the fourth argument, with a hint next to the marker.
  let report = @err_marker.Report::new(Error, "unknown mode 'sovle'")
    .with_code("E01")
    .with_mark(
      @err_marker.Mark::primary(
        @err_marker.Span::new(3, 4),
        message="did you mean 'solve'?",
      ),
    )
  let args = @err_marker.Sequence::from_args([
    "sudoku", "export", "a.txt", "sovle", "out.txt",
  ])
  inspect(
    report.render(args),
    content=(
      #|sudoku export a.txt sovle out.txt
      #|                    ^^^^^ did you mean 'solve'?
      #|error[E01]: unknown mode 'sovle'
    ),
  )

  // Wide characters take two columns; marks never split a character.
  let row = @err_marker.Report::new(Warning, "duplicate digit")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(4, 5)))
    .with_mark(@err_marker.Mark::secondary(@err_marker.Span::new(1, 2)))
  inspect(
    row.render(@err_marker.Sequence::from_string("数5独.5")),
    content=(
      #|数5独.5
      #|  -   ^
      #|warning: duplicate digit
    ),
  )
}
```

`Span::new(3, 4)` is element 3 of the argument vector; in a string, positions
count characters. `render(..., color=true)` adds ANSI colours, and
`model=@cursor.Model::new(tab_width=4)` changes how tabs are expanded.

## Packages

| Package | Purpose |
| --- | --- |
| [`err_marker`](./doc/manual/api/core.md) | sequences, `Report`, `Mark`, `Span`, `Severity` and the compact renderer; the deprecated 0.1 `ErrorData::mark` |
| [`err_marker/cursor`](./doc/manual/api/cursor.md) | terminal columns of text: grapheme clusters, display widths and the cursor-move monoid behind every column |
| [`err_marker/error_report`](./doc/manual/api/error_report.md) | conversion of reports to [`marianoguerra/error-report`](https://mooncakes.io/docs/marianoguerra/error-report) for its gutter layout and JSON output |

`internal/ucd` holds the generated Unicode tables and the UAX #29 segmenter;
it is not part of the public API.

## Documentation

The manual is in [`doc/manual`](./doc/manual/index.md), in English with
Chinese and Japanese translations under [`doc/locale`](./doc/locale). Good
starting points:

- [Tutorial](./doc/manual/tutorial/core.md): from one marked argument to
  reports with several marks, and *Migrating from 0.1*.
- [Design](./doc/manual/design/core.md): the 0.2.0 contract — scalar
  positions, clamping as a retraction, snapping as a closure operator, the
  cursor monoid and the overlay semilattice.
- [cursor design](./doc/manual/design/cursor.md): why every cursor move has one
  of three normal forms.

Evidence is pinned and finite: the segmenter passes all 853 cases of
`GraphemeBreakTest.txt` (Unicode 18.0.0); the UCD input files are pinned by
sha256 in [`tools/ucd/SOURCES`](./tools/ucd/SOURCES); the cursor laws are
checked exhaustively on every text of up to four pieces for tab widths 1 to 4.

## Development

The repository uses [`just`](https://github.com/casey/just) as its task runner.

```bash
just fmt                                      # format MoonBit sources
just check-all                                # check every backend
just test-all                                 # wasm, wasm-gc, js, native; debug and release
just ready                                    # everything before a pull request
python3 tools/gen_unicode_tables.py --check   # generated Unicode tables are up to date
```

The demo above is a [Remotion](https://www.remotion.dev/) composition fed by
the real renderer; [`.github/demo`](./.github/demo/README.md) explains how to
regenerate it.

## Contributing

Contributions to correctness, documentation and test coverage are welcome.
Read [CONTRIBUTING](./CONTRIBUTING.md) for the workflow. The roadmap is tracked
in [#5](https://github.com/moonbit-community/err_marker/issues/5), and release
history is in [CHANGELOG](./CHANGELOG.md).

## License

Apache-2.0. See [LICENSE](./LICENSE).
