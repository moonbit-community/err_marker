///|
fn plain(r : @report.Report, sources : @report.Sources) -> String {
  @render.render_string(r, sources, {
    ..@render.default_config,
    theme: @style.mono_theme,
    color: Never,
  })
}

///|
test "argv report renders through error-report" {
  let report = @err_marker.Report::new(Error, "unknown mode 'sovle'")
    .with_code("E01")
    .with_mark(
      @err_marker.Mark::primary(
        @err_marker.Span::new(3, 4),
        message="did you mean 'solve'?",
      ),
    )
    .with_note("modes are solve and fmt")
  let args = @err_marker.Sequence::from_args([
    "sudoku", "export", "a.txt", "sovle", "out.txt",
  ])
  let (r, sources) = @error_report.to_error_report(report, args, name="argv")
  inspect(
    plain(r, sources),
    content=(
      #|error[E01]: unknown mode 'sovle'
      #|  ╭─[ argv:1:21 ]
      #|  │
      #|1 │ sudoku export a.txt sovle out.txt
      #|  │                     ──┬──
      #|  │                       ╰─ did you mean 'solve'?
      #|  │
      #|  ├─ note: modes are solve and fmt
      #|  ╰─
      #|
    ),
  )
}

///|
test "spans are converted to UTF-16 offsets after snapping" {
  // "😀" is two UTF-16 code units; the mark covers scalar 1 (the "x")
  let seq = @err_marker.Sequence::from_string("😀xy")
  let report = @err_marker.Report::new(Warning, "w").with_mark(
    @err_marker.Mark::secondary(@err_marker.Span::new(1, 2)),
  )
  let (r, _) = @error_report.to_error_report(report, seq)
  assert_eq(r.labels.length(), 1)
  assert_eq(r.labels[0].span.start, 2)
  assert_eq(r.labels[0].span.end(), 3)
  assert_eq(r.labels[0].style, Secondary)
  assert_eq(r.severity, Warning)
}

///|
test "note and help become advice" {
  let seq = @err_marker.Sequence::from_string("x")
  let (r1, _) = @error_report.to_error_report(
    @err_marker.Report::new(Note, "n"),
    seq,
  )
  let (r2, _) = @error_report.to_error_report(
    @err_marker.Report::new(Help, "h"),
    seq,
  )
  assert_eq(r1.severity, Advice)
  assert_eq(r2.severity, Advice)
}
