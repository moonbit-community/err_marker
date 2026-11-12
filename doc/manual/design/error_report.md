# error_report design

## Why an adapter

`err_marker` 0.2.0 draws one compact layout for sequences such as
command-line arguments. `marianoguerra/error-report` draws reports over
source files, with a gutter, several sources and JSON output. Rather than
grow a second general renderer, `err_marker` converts its reports into
`error-report` reports, and users choose the output they need.

## Same places in both renderers

The conversion does not recompute positions. It asks the sequence where each
span lands with `Sequence::locate`, which runs the same steps as
`Report::render`: the hull of the elements, clamping, and snapping to
grapheme clusters. It then converts the scalar span into UTF-16 offsets with
`Source::span_of_chars` of `error-report`. A mark therefore covers the same
characters in both layouts, including whole emoji and combining sequences.

## Mapping

| `err_marker` | `error-report` |
| --- | --- |
| `Error`, `Warning` | `Error`, `Warning` |
| `Note`, `Help` | `Advice` |
| `Mark::primary` / `secondary` | `Label::primary` / `secondary`, with the priority |
| notes | notes |

## Dependency

The adapter is the only package that imports `error-report`, but a MoonBit
module declares dependencies for all its packages, so installing
`err_marker` also fetches `error-report`. It has no dependencies of its own.
