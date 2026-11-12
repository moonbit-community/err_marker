///|
fn span(pos : Int32, offset : Int32) -> ErrorData {
  ErrorData::make("bad", err_pos=pos, err_offset=offset)
}

///|
test "array span past the end is clamped to the last element" {
  assert_eq(
    span(2, 10).mark(Sequence::from_array([1, 2, 3, 4])),
    "1 2 3 4\n    ^^^\nError: bad",
  )
}

///|
test "string span past the end is clamped to the last character" {
  assert_eq(
    span(2, 10).mark(Sequence::from_string("abcd")),
    "abcd\n  ^^\nError: bad",
  )
}

///|
test "array start past the end is a point after the text" {
  assert_eq(
    span(9, 0).mark(Sequence::from_array([1, 2])),
    "1 2\n   ^\nError: bad",
  )
  assert_eq(
    span(2, 0).mark(Sequence::from_array(["solve", "a.txt"])),
    "solve a.txt\n           ^\nError: bad",
  )
}

///|
test "string start past the end is a point after the text" {
  assert_eq(
    span(4, 3).mark(Sequence::from_string("abcd")),
    "abcd\n    ^\nError: bad",
  )
}

///|
test "empty sequences get a point at column 0" {
  let empty : Array[String] = []
  assert_eq(span(0, 0).mark(Sequence::from_array(empty)), "\n^\nError: bad")
  assert_eq(span(0, 0).mark(Sequence::from_string("")), "\n^\nError: bad")
}

///|
test "negative offset counts as zero" {
  assert_eq(
    span(1, -3).mark(Sequence::from_array(["a", "bb", "c"])),
    "a bb c\n  ^^\nError: bad",
  )
  assert_eq(
    span(1, -3).mark(Sequence::from_string("abc")),
    "abc\n ^\nError: bad",
  )
}

///|
test "huge offset does not overflow" {
  assert_eq(
    span(1, 2147483647).mark(Sequence::from_string("abc")),
    "abc\n ^^\nError: bad",
  )
  assert_eq(
    span(1, 2147483647).mark(Sequence::from_array([1, 2, 3])),
    "1 2 3\n  ^^^\nError: bad",
  )
}

///|
test "negative position still draws nothing" {
  assert_eq(span(-1, 0).mark(Sequence::from_string("abc")), "abc\n\nError: bad")
}
