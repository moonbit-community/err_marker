///|
/// A mark placed in the rendered text: its index in the report, its span in
/// scalar indices after clamping and snapping, and where it is drawn.
priv struct Placed {
  index : Int32
  start : Int32
  end : Int32
  line : Int32
  col : Int32
  width : Int32
}

///|
/// The rendered text of a sequence, and for an array sequence the scalar span
/// `[start, end)` of each element in it.
fn[T : Show] layout(seq : Sequence[T]) -> (String, Array[(Int32, Int32)]?) {
  match seq {
    Str(s) => (s, None)
    Arr(a, j) => {
      let parts = render_parts(a, j)
      let join_len = j.to_array().length()
      let spans = []
      let mut pos = 0
      for i, p in parts {
        if i > 0 {
          pos += join_len
        }
        let len = p.to_array().length()
        spans.push((pos, pos + len))
        pos += len
      }
      (parts.join(j), Some(spans))
    }
  }
}

///|
/// The scalar span of `span` in the text: element spans become the hull of
/// their elements; then clamping (kappa) and snapping (sigma) of the 0.2.0
/// contract.
fn scalar_span(
  span : Span,
  elements : Array[(Int32, Int32)]?,
  scalars : Int32,
  bounds : Array[Int32],
) -> (Int32, Int32) {
  let (a, b) = match elements {
    None => {
      let a = if span.start > scalars { scalars } else { span.start }
      let b = if span.end > scalars { scalars } else { span.end }
      (a, b)
    }
    Some(els) => {
      let n = els.length()
      let i = if span.start > n { n } else { span.start }
      let j = if span.end > n { n } else { span.end }
      if i == j {
        let p = if i < n { els[i].0 } else { scalars }
        (p, p)
      } else {
        (els[i].0, els[j - 1].1)
      }
    }
  }
  @ucd.snap(bounds, a, b)
}

///|
/// Compares two strings by code point (not by UTF-16 code unit).
fn compare_code_points(x : String, y : String) -> Int32 {
  let xs = x.to_array()
  let ys = y.to_array()
  let n = if xs.length() < ys.length() { xs.length() } else { ys.length() }
  for i in 0..<n {
    if xs[i] != ys[i] {
      return if xs[i].to_int() < ys[i].to_int() { -1 } else { 1 }
    }
  }
  xs.length() - ys.length()
}

///|
/// Whether mark `x` wins a column over mark `y` (D-E6): higher priority, then
/// later start, then earlier end, then primary over secondary, then the
/// message that is smaller in code-point order. The order depends only on the
/// marks, so overlaying them is commutative.
fn beats(x : Mark, xp : Placed, y : Mark, yp : Placed) -> Bool {
  if x.priority != y.priority {
    return x.priority > y.priority
  }
  if xp.start != yp.start {
    return xp.start > yp.start
  }
  if xp.end != yp.end {
    return xp.end < yp.end
  }
  if x.style != y.style {
    return x.style == Primary
  }
  let mx = x.message.unwrap_or("")
  let my = y.message.unwrap_or("")
  compare_code_points(mx, my) < 0
}

///|
/// One rendered line of the text: its displayed form (tabs expanded) and its
/// width in columns.
priv struct Line {
  text : StringBuilder
  mut width : Int32
}

///|
fn sgr(code : String, s : String, color : Bool) -> String {
  if color {
    "\u{1B}[" + code + "m" + s + "\u{1B}[0m"
  } else {
    s
  }
}

///|
fn severity_sgr(s : Severity) -> String {
  match s {
    Error => "1;31"
    Warning => "1;33"
    Note => "1;36"
    Help => "1;32"
  }
}

///|
/// Renders the report on `seq` in the compact layout:
///
/// 1. the line of text that holds the primary mark (the whole text if there
///    are no marks), with tabs expanded by `model`;
/// 2. a marker row: `^` under primary marks and `-` under secondary marks;
///    where marks overlap, the winner is decided by priority, then the later
///    start, then the earlier end, then primary over secondary, then the
///    message (so the result does not depend on the order of the marks); the
///    message of the mark that ends rightmost follows the markers on the same
///    row;
/// 3. the other messages, each under the start of its mark, on as few rows as
///    possible (greedy by left end point);
/// 4. the header `severity[code]: message`, with ` at line:column` (1-based)
///    of the primary mark when the text has several lines;
/// 5. one `note: ...` line per note.
///
/// Marks whose start lies on another line than the primary mark are not
/// drawn. Positions are element indices for array sequences and Unicode
/// scalar indices for string sequences; spans are clamped to the sequence and
/// snapped outward to grapheme clusters. Widths follow Unicode 18.0.0 through
/// `model`. With `color`, ANSI SGR colours are used (ECMA-48).
pub fn[T : Show] Report::render(
  self : Report,
  seq : Sequence[T],
  model~ : @cursor.Model = @cursor.Model::new(),
  color~ : Bool = false,
) -> String {
  self.render_impl(seq, model, color, '^', None)
}

///|
/// `Report::render` with the primary marker character `glyph`, and, if
/// `header` is given, that line in place of the header (used by the
/// deprecated `ErrorData::mark`).
fn[T : Show] Report::render_impl(
  self : Report,
  seq : Sequence[T],
  model : @cursor.Model,
  color : Bool,
  glyph : Char,
  header : String?,
) -> String {
  // Marks equal in every field are one mark, so overlaying is idempotent.
  let marks : Array[Mark] = []
  for m in self.marks {
    if !marks.contains(m) {
      marks.push(m)
    }
  }
  let (text, elements) = layout(seq)
  let scalars = text.to_array().length()
  let bounds = @ucd.cluster_boundaries(text)
  // Lay out the text cluster by cluster: displayed lines, and the (line,
  // column) of every cluster boundary.
  let lines : Array[Line] = [{ text: StringBuilder(), width: 0, }]
  let at : Map[Int32, (Int32, Int32)] = Map([])
  let mut s = 0
  for g in @cursor.clusters(text) {
    let line = lines.length() - 1
    at[s] = (line, lines[line].width)
    match g {
      "\n" | "\r" | "\r\n" => lines.push({ text: StringBuilder(), width: 0, })
      "\t" => {
        let to = model.apply(model.tab(), { line: 0, col: lines[line].width, }).col
        for _ in lines[line].width..<to {
          lines[line].text.write_char(' ')
        }
        lines[line].width = to
      }
      _ => {
        lines[line].text.write_string(g)
        lines[line].width += model.cluster_width(g)
      }
    }
    s += g.to_array().length()
  }
  at[scalars] = (lines.length() - 1, lines[lines.length() - 1].width)
  // Place the marks.
  let placed = marks.mapi((i, m) => {
    let (a, b) = scalar_span(m.span, elements, scalars, bounds)
    let (la, ca) = at.get(a).unwrap_or((0, 0))
    let (lb, cb) = at.get(b).unwrap_or((0, 0))
    let end_col = if lb != la { lines[la].width } else { cb }
    let width = if end_col > ca { end_col - ca } else { 1 }
    { index: i, start: a, end: b, line: la, col: ca, width, }
  })
  // The primary mark: highest priority, then earliest start, among primary
  // marks if there are any.
  let mut primary : Placed? = None
  for p in placed {
    let m = marks[p.index]
    match primary {
      None => primary = Some(p)
      Some(q) => {
        let n = marks[q.index]
        let better = if m.style != n.style {
          m.style == Primary
        } else if m.priority != n.priority {
          m.priority > n.priority
        } else if p.start != q.start {
          p.start < q.start
        } else {
          p.end < q.end
        }
        if better {
          primary = Some(p)
        }
      }
    }
  }
  let out = []
  let header_sev = sgr(severity_sgr(self.severity), self.severity.name(), color)
  let code = match self.code {
    Some(c) => "[" + c + "]"
    None => ""
  }
  match primary {
    None => {
      for l in lines {
        out.push(l.text.to_string())
      }
      out.push(header.unwrap_or(header_sev + code + ": " + self.message))
    }
    Some(pm) => {
      let shown = pm.line
      out.push(lines[shown].text.to_string())
      let on_line = placed.filter(p => p.line == shown)
      // Marker row: overlay as a semilattice.
      let mut cols = 0
      for p in on_line {
        if p.col + p.width > cols {
          cols = p.col + p.width
        }
      }
      let winner : Array[Int32] = Array::make(cols, -1)
      for p in on_line {
        for c in p.col..<(p.col + p.width) {
          let w = winner[c]
          if w < 0 ||
            beats(marks[p.index], p, marks[placed[w].index], placed[w]) {
            winner[c] = p.index
          }
        }
      }
      let row = StringBuilder()
      let mut c = 0
      while c < cols {
        let w = winner[c]
        if w < 0 {
          row.write_char(' ')
          c += 1
          continue
        }
        // A run of cells won by the same mark.
        let mut e = c
        while e < cols && winner[e] == w {
          e += 1
        }
        let m = marks[w]
        let g = if m.style == Primary { glyph } else { '-' }
        let code = if m.style == Primary {
          severity_sgr(self.severity)
        } else {
          "34"
        }
        row.write_string(sgr(code, String::make(e - c, g), color))
        c = e
      }
      // Messages: the mark that ends rightmost keeps its message on the
      // marker row; the others go below, greedy by left end point.
      let labelled = on_line.filter(p => marks[p.index].message is Some(_))
      let mut tail : Placed? = None
      for p in labelled {
        match tail {
          None => tail = Some(p)
          Some(q) => {
            let pe = p.col + p.width
            let qe = q.col + q.width
            if pe > qe ||
              (pe == qe && beats(marks[p.index], p, marks[q.index], q)) {
              tail = Some(p)
            }
          }
        }
      }
      let mut marker_row = row.to_string()
      if tail is Some(t) {
        marker_row = marker_row + " " + marks[t.index].message.unwrap()
      }
      out.push(marker_row)
      let rest = labelled.filter(p => {
        match tail {
          Some(t) => p.index != t.index
          None => true
        }
      })
      rest.sort_by((p, q) => {
        if p.col != q.col {
          return p.col - q.col
        }
        if beats(marks[p.index], p, marks[q.index], q) {
          -1
        } else if beats(marks[q.index], q, marks[p.index], p) {
          1
        } else {
          0
        }
      })
      let rows : Array[StringBuilder] = []
      // `free[r]`: first column where row `r` can take a label (one column
      // of gap after the previous label); `written[r]`: columns written.
      let free : Array[Int32] = []
      let written : Array[Int32] = []
      for p in rest {
        let msg = marks[p.index].message.unwrap()
        let w = model.apply(model.text(msg), { line: 0, col: 0, }).col
        let mut r = 0
        while r < rows.length() && free[r] > p.col {
          r += 1
        }
        if r == rows.length() {
          rows.push(StringBuilder())
          free.push(0)
          written.push(0)
        }
        for _ in written[r]..<p.col {
          rows[r].write_char(' ')
        }
        rows[r].write_string(msg)
        written[r] = p.col + w
        free[r] = p.col + w + 1
      }
      for r in rows {
        out.push(r.to_string())
      }
      let loc = if lines.length() > 1 {
        " at \{shown + 1}:\{pm.col + 1}"
      } else {
        ""
      }
      out.push(header.unwrap_or(header_sev + code + loc + ": " + self.message))
    }
  }
  for n in self.notes {
    out.push(sgr("1", "note", color) + ": " + n)
  }
  out.join("\n")
}

///|
/// The text that `Report::render` draws for this sequence: a string as it
/// is, or the elements of an array (quoted when needed) joined by the
/// separator.
pub fn[T : Show] Sequence::rendered(self : Sequence[T]) -> String {
  layout(self).0
}

///|
/// Where `span` lands in `rendered()`, as Unicode scalar indices
/// `(start, end)`: element spans become the hull of their elements, then the
/// span is clamped to the text and snapped outward to grapheme clusters, as
/// `Report::render` does.
pub fn[T : Show] Sequence::locate(
  self : Sequence[T],
  span : Span,
) -> (Int32, Int32) {
  let (text, elements) = layout(self)
  scalar_span(
    span,
    elements,
    text.to_array().length(),
    @ucd.cluster_boundaries(text),
  )
}
