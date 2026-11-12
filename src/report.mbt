///|
/// How serious a report is. Ordered `Help < Note < Warning < Error`.
#derive(Eq, Compare, Debug)
pub(all) enum Severity {
  Help
  Note
  Warning
  Error
}

///|
/// The lower-case name used in rendered headers: `"error"`, `"warning"`,
/// `"note"` or `"help"`.
pub fn Severity::name(self : Severity) -> String {
  match self {
    Help => "help"
    Note => "note"
    Warning => "warning"
    Error => "error"
  }
}

///|
/// Whether a mark is the main place of the report (drawn with `^`) or a
/// related place (drawn with `-`).
#derive(Eq, Debug)
pub(all) enum Style {
  Primary
  Secondary
}

///|
/// A half-open interval `[start, end)` of positions in a sequence: element
/// indices for an array sequence, Unicode scalar indices for a string
/// sequence. Valid by construction: `0 <= start <= end`.
#derive(Eq, Debug)
pub struct Span {
  start : Int32
  end : Int32
}

///|
/// The span `[start, end)`. A negative end point counts as 0, and an `end`
/// before `start` counts as `start`.
pub fn Span::new(start : Int32, end : Int32) -> Span {
  let start = if start < 0 { 0 } else { start }
  let end = if end < start { start } else { end }
  { start, end, }
}

///|
/// The insertion point `[at, at)`, drawn as one marker: "something is missing
/// here".
pub fn Span::point(at : Int32) -> Span {
  Span::new(at, at)
}

///|
/// A place to mark: a span, a style, an optional message shown next to or
/// under the marker, and a priority that decides overlaps (higher wins).
#derive(Eq, Debug)
pub struct Mark {
  span : Span
  style : Style
  message : String?
  priority : Int32
}

///|
/// A primary mark (`^`) on `span`, with an optional message.
pub fn Mark::primary(span : Span, message? : String) -> Mark {
  { span, style: Primary, message, priority: 0, }
}

///|
/// A secondary mark (`-`) on `span`, with an optional message.
pub fn Mark::secondary(span : Span, message? : String) -> Mark {
  { span, style: Secondary, message, priority: 0, }
}

///|
/// The same mark with another priority.
pub fn Mark::with_priority(self : Mark, priority : Int32) -> Mark {
  { ..self, priority, }
}

///|
/// An error report: a severity, an optional code, a message, marks on the
/// sequence and notes printed after the header.
#derive(Eq, Debug)
pub struct Report {
  severity : Severity
  code : String?
  message : String
  marks : Array[Mark]
  notes : Array[String]
}

///|
/// A report with no code, marks or notes.
pub fn Report::new(severity : Severity, message : String) -> Report {
  { severity, code: None, message, marks: [], notes: [], }
}

///|
/// The same report with a code, shown as `error[CODE]`.
pub fn Report::with_code(self : Report, code : String) -> Report {
  { ..self, code: Some(code), }
}

///|
/// The same report with one more mark.
pub fn Report::with_mark(self : Report, mark : Mark) -> Report {
  { ..self, marks: [..self.marks, mark], }
}

///|
/// The same report with one more note.
pub fn Report::with_note(self : Report, note : String) -> Report {
  { ..self, notes: [..self.notes, note], }
}

///|
/// A command-line argument vector as a sequence: elements joined by a space,
/// quoted when needed so the line can be split back into arguments.
pub fn Sequence::from_args(args : Array[String]) -> Sequence[String] {
  Sequence::from_array(args)
}

///|
/// The Unicode scalar index of UTF-16 offset `offset` in `text`: the number of
/// scalars that start before it. An offset inside a surrogate pair counts
/// that pair as not yet passed. Offsets are clamped to `[0, text.length()]`.
pub fn utf16_to_scalar(text : String, offset : Int32) -> Int32 {
  let mut units = 0
  let mut scalars = 0
  for c in text {
    if units >= offset {
      break
    }
    let w = if c.to_int() > 0xFFFF { 2 } else { 1 }
    if units + w > offset {
      break
    }
    units += w
    scalars += 1
  }
  scalars
}
