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
/// Locates the start and end character positions in a flattened string
/// representation of an array sequence.
///
/// Parameters:
///
/// * `seq` : The array of elements to locate positions within.
/// * `pos` : The starting index position in the array.
/// * `offset` : The number of additional elements to include after the starting
/// position.
/// * `join` : The number of characters used to join elements when flattening to
/// string (default: 1).
///
/// Returns a tuple `(start, end)` of UTF-16 offsets into the flattened string:
/// the target range is `start` (inclusive) to `end` (exclusive). Returns
/// `(-1, -1)` if `pos` is negative, `pos` is greater than or equal to the array
/// length, or `offset` is negative; it never panics. Callers clamp `offset`
/// first (see `locate_span`).
///
fn[T : Show] err_locate_arr(
  seq : Array[T],
  pos : Int32,
  offset : Int32,
  join~ : Int32 = 1,
) -> (Int32, Int32) {
  guard pos >= 0 && pos < seq.length() && offset >= 0 else { (-1, -1) }
  let start = seq.foldi(init=0, (i, acc, x) => {
      if i < pos {
        acc + x.to_string().length()
      } else {
        acc
      }
    }) +
    join * pos
  let end = start +
    seq.foldi(init=0, (i, acc, x) => {
      if i >= pos && i <= pos + offset {
        acc + x.to_string().length()
      } else {
        acc
      }
    }) +
    join * offset
  (start, end)
}

///|
/// Padding that puts the marker under code unit `to` of `text` when the marker
/// line starts at code unit `from`: one space per code unit in between, except
/// that a tab is copied as a tab. The marker then lines up with the text above
/// it whatever tab width the terminal uses (#8).
fn pad_like(text : String, from : Int32, to : Int32) -> String {
  let sb = StringBuilder()
  for i in from..<to {
    if i < text.length() && text[i] == '\t'.to_int().to_uint16() {
      sb.write_char('\t')
    } else {
      sb.write_char(' ')
    }
  }
  sb.to_string()
}

///|
/// Widens `[start, end)` (UTF-16 offsets into `text`) so that neither end
/// falls inside a surrogate pair: a character outside the Basic Multilingual
/// Plane is marked whole or not at all (#7). Element boundaries of an array
/// sequence are always code point boundaries, so this only moves spans of
/// string sequences.
fn snap_to_code_points(
  text : String,
  start : Int32,
  end : Int32,
) -> (Int32, Int32) {
  let start = if start > 0 &&
    start < text.length() &&
    is_low_surrogate(text[start]) &&
    is_high_surrogate(text[start - 1]) {
    start - 1
  } else {
    start
  }
  let end = if end > 0 &&
    end < text.length() &&
    is_high_surrogate(text[end - 1]) &&
    is_low_surrogate(text[end]) {
    end + 1
  } else {
    end
  }
  (start, if end < start { start } else { end })
}

///|
fn is_high_surrogate(u : UInt16) -> Bool {
  u >= (0xD800 : UInt16) && u <= (0xDBFF : UInt16)
}

///|
fn is_low_surrogate(u : UInt16) -> Bool {
  u >= (0xDC00 : UInt16) && u <= (0xDFFF : UInt16)
}

///|
/// Locates the marked span in the rendered `text` as UTF-16 offsets
/// `(start, end)`, `end` exclusive; `start == end` is a zero-width point.
/// Returns `None` when there is no position (`pos < 0`).
fn[T : Show] locate_span(
  seq : Sequence[T],
  text : String,
  pos : Int32,
  offset : Int32,
) -> (Int32, Int32)? {
  // One rule for both sequence kinds (#10): a negative `pos` means "no
  // position"; a negative `offset` counts as 0; a span that runs past the end
  // is clamped to the last element; a `pos` at or past the end is a zero-width
  // point after the text, drawn as one marker.
  if pos < 0 {
    return None
  }
  let offset = if offset < 0 { 0 } else { offset }
  let (start, end) = match seq {
    Arr(a, j) => {
      let n = a.length()
      if pos >= n {
        (text.length(), text.length())
      } else {
        // `offset >= n - pos` avoids overflowing `pos + offset`.
        let offset = if offset >= n - pos { n - 1 - pos } else { offset }
        err_locate_arr(render_parts(a, j), pos, offset, join=j.length())
      }
    }
    Str(s) => {
      let n = s.length()
      if pos >= n {
        (n, n)
      } else {
        let last = if offset >= n - pos { n - 1 } else { pos + offset }
        (pos, last + 1)
      }
    }
  }
  Some((start, end))
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
/// Generates a formatted error visualization string with sequence display,
/// position markers, and an error message.
///
/// Parameters:
///
/// * `self` : The error data containing position, offset, error type, and error
/// message information.
/// * `seq` : The sequence to visualize, either an array with join string or a
/// plain string.
/// * `marker` : The character used to create the visual position indicator
/// (default: '^').
/// * `gen_msg` : A function to format the error type and message into the final
/// error string (default: `gen_err_msg`).
///
/// Returns a multi-line string containing the sequence, position markers, and
/// formatted error message.
pub fn[T : Show] ErrorData::mark(
  self : ErrorData,
  seq : Sequence[T],
  marker~ : Char = '^',
  gen_msg~ : (String?, String) -> String = gen_err_msg,
) -> String {
  let (pos, offset) = (self.err_pos, self.err_offset)
  let seq_str = match seq {
    Arr(a, j) => render_parts(a, j).join(j)
    Str(s) => s
  }
  let msg = gen_msg(self.err_type, self.err_msg)
  guard locate_span(seq, seq_str, pos, offset) is Some((start, end)) else {
    return seq_str + "\n\n" + msg
  }
  let (start, end) = snap_to_code_points(seq_str, start, end)
  // The marker goes right under the line that holds the start of the span,
  // and its column is counted from the start of that line. A span that crosses
  // a line break is marked up to the end of its first line (#9).
  let newline = '\n'.to_int().to_uint16()
  let mut line_start = start
  while line_start > 0 && seq_str[line_start - 1] != newline {
    line_start -= 1
  }
  let mut line_end = start
  while line_end < seq_str.length() && seq_str[line_end] != newline {
    line_end += 1
  }
  let end = if end > line_end { line_end } else { end }
  let width = if end > start { end - start } else { 1 }
  let marker_str = pad_like(seq_str, line_start, start) +
    String::make(width, marker)
  let head = seq_str.unsafe_substring(start=0, end=line_end)
  if line_end >= seq_str.length() {
    head + "\n" + marker_str + "\n" + msg
  } else {
    let tail = seq_str.unsafe_substring(
      start=line_end + 1,
      end=seq_str.length(),
    )
    head + "\n" + marker_str + "\n" + tail + "\n" + msg
  }
}
