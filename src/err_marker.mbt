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
/// Returns a tuple `(start, end)` where `start` is the character position of the
/// beginning of the target range and `end` is the character position of the end
/// of the target range in the flattened string. Returns `(-1, -1)` if the
/// position or offset parameters are invalid.
///
/// Panics if `pos` is negative, `pos` is greater than or equal to the array
/// length, or `offset` is negative.
///
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
/// Generates a visual marker string to highlight a specific position and range
/// within a sequence.
///
/// Parameters:
///
/// * `seq` : The sequence to generate markers for, either an array with join
/// string or a plain string.
/// * `pos` : The starting position index to mark within the sequence.
/// * `offset` : The number of additional positions to include in the marker
/// range after the starting position.
/// * `marker` : The character used to create the visual marker.
///
/// Returns a string containing spaces followed by marker characters positioned
/// to align with the target range in the sequence. Returns an empty string if
/// the position or range is invalid.
///
/// Examples:
///
/// ```moonbit
/// // For array sequences
/// let arr = ["hello", "world", "test"]
/// let seq = Sequence::Arr(arr, " ")
/// inspect(@err_marker.gen_marker(seq, 1, 0, '^'), content="      ^^^^^")
///
/// // For string sequences  
/// let str_seq = Sequence::Str("hello world")
/// inspect(@err_marker.gen_marker(str_seq, 6, 4, '~'), content="      ~~~~~")
/// ```
///
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
///
/// Examples:
///
/// ```moonbit
/// inspect(@err_marker.gen_err_msg(Some("TypeError"), "Invalid argument"), content="Error(TypeError): Invalid argument")
/// inspect(@err_marker.gen_err_msg(None, "Something went wrong"), content="Error: Something went wrong")
/// ```
///
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
///
/// Examples:
///
/// ```moonbit
/// // With array sequence
/// let data = @err_marker.ErrorData::{ err_pos: 1, err_offset: 0, err_type: Some("TypeError"), err_msg: "Invalid token" }
/// let arr_seq = @err_marker.Sequence::Arr(["hello", "world"], " ")
/// inspect(data.mark(arr_seq), content=
///   "hello world\n      ^^^^^\nError(TypeError): Invalid token")
///
/// // With string sequence
/// let str_data = @err_marker.ErrorData::{ err_pos: 6, err_offset: 4, err_type: None, err_msg: "Unexpected character" }
/// let str_seq = @err_marker.Sequence::Str("hello world test")
/// inspect(str_data.mark(str_seq), content=
///   "hello world test\n      ~~~~~\nError: Unexpected character")
/// ```
///
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
