# error_report API

## Purpose

`KCN-judu/err_marker/error_report` converts an `err_marker` report into a
[`marianoguerra/error-report`](https://mooncakes.io/docs/marianoguerra/error-report)
report, for programs that want its gutter layout, JSON output or fixes. It is
the only package of the module that uses `error-report`; the design is in
[design](../design/error_report.md).

## Importing

```moonbit nocheck
import {
  "KCN-judu/err_marker",
  "KCN-judu/err_marker/error_report",
  "marianoguerra/error-report" @report,
  "marianoguerra/error-report/render",
}
```

## Conversion

### `to_error_report`

```mbti
pub fn[T : Show] to_error_report(@err_marker.Report, @err_marker.Sequence[T], name? : String) -> (@report.Report, @report.Sources)
```

Returns the converted report and the `Sources` that hold the rendered
sequence under `name` (default `"input"`). Spans are located exactly as
`Report::render` locates them and converted to the UTF-16 offsets that
`error-report` uses. `Error` and `Warning` keep their severity; `Note` and
`Help` become `Advice`. Marks keep their style, message and priority; notes
stay notes. Render the result with any `error-report` renderer.
