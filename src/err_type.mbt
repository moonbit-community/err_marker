///|
/// Generic sequence that can hold either an array of elements or a string of
/// characters.
///
/// Constructors:
///
/// * `Arr(Array[T], String)` : Array-based sequence with a join separator for
/// string representation.
/// * `Str(String)` : String-based sequence of characters.
enum Sequence[T] {
  Arr(Array[T], String)
  Str(String)
}

///|
pub fn[T : Show] Sequence::from_array(
  arr : Array[T],
  join~ : String = " "
) -> Sequence[T] {
  Arr(arr, join)
}

///|
pub fn Sequence::from_string(str : String) -> Sequence[Char] {
  Str(str)
}

///|
pub struct ErrorData {
  err_type : String?
  err_msg : String
  err_pos : Int
  err_offset : Int
}

///|
pub fn ErrorData::make(
  err_type~ : String? = None,
  err_msg : String,
  err_pos~ : Int = -1,
  err_offset~ : Int = 0
) -> ErrorData {
  ErrorData::{ err_type, err_msg, err_pos, err_offset }
}
