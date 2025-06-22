///|
fn[T : Show] err_locate_arr(
  seq : Array[T],
  pos : Int,
  offset : Int,
  join~ : Int = 1
) -> (Int, Int) {
  guard pos >= 0 && pos < seq.length() && offset >= 0 else { (-1, -1) }
  let start = seq.foldi(init=0, (i, acc, x) => if i < pos {
      acc + x.to_string().length()
    } else {
      acc
    }) +
    join * pos
  let end = start +
    seq.foldi(init=0, (i, acc, x) => if i >= pos && i <= pos + offset {
      acc + x.to_string().length()
    } else {
      acc
    }) +
    join * offset
  (start, end)
}

///|
fn[T : Show] gen_marker(
  seq : Sequence[T],
  pos : Int,
  offset : Int,
  marker : Char
) -> String {
  match seq {
    Arr(a, j) => {
      let (start, end) = err_locate_arr(a, pos, offset, join=j.length())
      if start == -1 {
        return ""
      }
      String::make(start, ' ') + String::make(end - start, marker)
    }
    Str(s) => {
      let (start, end) = (pos, pos + offset)
      if start >= s.length() || end >= s.length() || start < 0 || end < 0 {
        return ""
      }
      String::make(start, ' ') + String::make(end - start + 1, marker)
    }
  }
}

///|
fn gen_err_msg(err_type : String?, err_msg : String) -> String {
  let et = match err_type {
    Some(s) => "(\{s})"
    None => ""
  }
  "Error\{et}: \{err_msg}"
}

///|
pub fn[T : Show] ErrorData::mark(
  self : ErrorData,
  seq : Sequence[T],
  marker~ : Char = '^',
  gen_msg~ : (String?, String) -> String = gen_err_msg
) -> String {
  let (pos, offset) = (self.err_pos, self.err_offset)
  let seq_str = match seq {
    Arr(a, j) => a.map(Show::to_string).join(j)
    Str(s) => s
  }
  let marker_str = gen_marker(seq, pos, offset, marker)
  $|\{seq_str}
  $|\{marker_str}
  $|\{gen_msg(self.err_type, self.err_msg)}
}
