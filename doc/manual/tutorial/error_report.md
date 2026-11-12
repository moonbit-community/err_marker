# error_report tutorial

Use this package when you already build `err_marker` reports but want
`error-report` to print them. Import it as in the [API](../api/error_report.md).

## 1. Build a report as usual

```moonbit nocheck
let report = @err_marker.Report::new(Error, "unknown mode 'sovle'")
  .with_code("E01")
  .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(3, 4), message="did you mean 'solve'?"))
let args = @err_marker.Sequence::from_args(["sudoku", "export", "a.txt", "sovle", "out.txt"])
```

## 2. Convert and render

```moonbit nocheck
let (r, sources) = @error_report.to_error_report(report, args, name="argv")
println(@render.render_string(r, sources, @render.default_config))
```

This prints the `error-report` layout with a gutter, the location `argv:1:21`
and the message under the marked argument. The marked place is the same one
`report.render(args)` marks, because both use `Sequence::locate`.
