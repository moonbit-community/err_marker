///|
/// Converts an `err_marker` report on a sequence into a
/// `marianoguerra/error-report` report, together with the `Sources` that hold
/// the rendered sequence under `name`. Spans are located exactly as
/// `Report::render` locates them (clamped and snapped to grapheme clusters)
/// and converted to the UTF-16 offsets that `error-report` uses. `Error` and
/// `Warning` keep their severity; `Note` and `Help` become `Advice`. Marks
/// keep their style, message and priority; notes stay notes.
pub fn[T : Show] to_error_report(
  report : @err_marker.Report,
  seq : @err_marker.Sequence[T],
  name~ : String = "input",
) -> (@report.Report, @report.Sources) {
  let sources = @report.Sources::new()
  let id = sources.add(name, seq.rendered())
  let source = sources.fetch(id).unwrap()
  let severity : @report.Severity = match report.severity {
    Error => Error
    Warning => Warning
    Note | Help => Advice
  }
  let mut out = @report.Report::new(severity, report.message)
  if report.code is Some(code) {
    out = out.with_code(code)
  }
  for m in report.marks {
    let (a, b) = seq.locate(m.span)
    let span = source.span_of_chars(a, b)
    let label = match m.style {
      Primary => @report.Label::primary(id, span, message?=m.message)
      Secondary => @report.Label::secondary(id, span, message?=m.message)
    }
    out = out.with_label(label.with_priority(m.priority))
  }
  for n in report.notes {
    out = out.with_note(n)
  }
  (out, sources)
}
