///|
/// Whether an element must be quoted so that the joined line can be split
/// back into its elements (#11): it is empty, or contains whitespace, a double
/// quote, or the (non-empty) separator.
fn needs_quotes(part : String, join : String) -> Bool {
  if part.is_empty() {
    return true
  }
  if join != "" && part.contains(join) {
    return true
  }
  for c in part {
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '"' {
      return true
    }
  }
  false
}

///|
/// Renders each element with `Show`, wrapping it in double quotes when
/// `needs_quotes` says so; inside quotes, `\` and `"` are escaped with a
/// backslash. Line breaks stay literal, so multi-line elements still render on
/// several lines (#9).
fn[T : Show] render_parts(a : Array[T], join : String) -> Array[String] {
  a.map(x => {
    let part = x.to_string()
    if !needs_quotes(part, join) {
      return part
    }
    let sb = StringBuilder()
    sb.write_char('"')
    for c in part {
      if c == '\\' || c == '"' {
        sb.write_char('\\')
      }
      sb.write_char(c)
    }
    sb.write_char('"')
    sb.to_string()
  })
}

///|
/// Formats an error type and error message into a standardized error string.
///
/// Parameters:
///
/// * `err_type` : An optional error type identifier that will be included in
/// parentheses if present.
/// * `err_msg` : The main error message to be displayed.
///
/// Returns a formatted error string in the format "Error(type): message" if
/// error type is provided, or "Error: message" if no error type is specified.
fn gen_err_msg(err_type : String?, err_msg : String) -> String {
  let et = match err_type {
    Some(s) => "(\{s})"
    None => ""
  }
  "Error\{et}: \{err_msg}"
}

///|
/// The number of scalars of `text` that start before UTF-16 offset `offset`:
/// a scalar that the half-open range `[_, offset)` touches counts.
fn scalars_starting_before(text : String, offset : Int32) -> Int32 {
  let mut units = 0
  let mut scalars = 0
  for c in text {
    if units >= offset {
      break
    }
    units += if c.to_int() > 0xFFFF { 2 } else { 1 }
    scalars += 1
  }
  scalars
}

///|
/// Renders the sequence, a marker line under the span and the message, in
/// the compact layout of `Report::render`.
///
/// Kept for one release (0.2.x) for compatibility; use `Report::render`. The
/// 0.1 units are kept: the span is `err_pos` to `err_pos + err_offset`, both
/// included; for a string sequence the positions are UTF-16 offsets, and every
/// character the span touches is marked; a negative `err_pos` means no
/// position; a negative `err_offset` counts as 0. The last line is
/// `gen_msg(err_type, err_msg)`, and `marker` is the marker character.
#deprecated("Use `Report::render` instead (see the section Migrating from 0.1 in the manual)", skip_current_package=true)
pub fn[T : Show] ErrorData::mark(
  self : ErrorData,
  seq : Sequence[T],
  marker~ : Char = '^',
  gen_msg~ : (String?, String) -> String = gen_err_msg,
) -> String {
  let msg = gen_msg(self.err_type, self.err_msg)
  if self.err_pos < 0 {
    return seq.rendered() + "\n\n" + msg
  }
  let pos = self.err_pos
  let offset = if self.err_offset < 0 { 0 } else { self.err_offset }
  // Exclusive end of the inclusive 0.1 span, without overflowing.
  let last = if offset >= 2147483646 - pos {
    2147483647
  } else {
    pos + offset + 1
  }
  let span = match seq {
    Arr(_, _) => Span::new(pos, last)
    Str(s) =>
      Span::new(utf16_to_scalar(s, pos), scalars_starting_before(s, last))
  }
  Report::new(Error, self.err_msg)
  .with_mark(Mark::primary(span))
  .render_impl(seq, @cursor.Model::new(), false, marker, Some(msg))
}
