///|
fn at(pos : Int32, offset : Int32) -> ErrorData {
  ErrorData::make("bad", err_pos=pos, err_offset=offset)
}

///|
test "column is counted from the start of the last line" {
  assert_eq(
    at(5, 0).mark(Sequence::from_string("ab\ncdef")),
    "cdef\n  ^\nError: bad",
  )
}

///|
test "only the line that holds the span is shown" {
  assert_eq(
    at(1, 0).mark(Sequence::from_string("ab\ncdef")),
    "ab\n ^\nError: bad",
  )
}

///|
test "span crossing a line break stops at the end of its first line" {
  assert_eq(
    at(1, 3).mark(Sequence::from_string("ab\ncdef")),
    "ab\n ^\nError: bad",
  )
}

///|
test "span starting on the newline marks the end of that line" {
  assert_eq(
    at(2, 0).mark(Sequence::from_string("ab\ncdef")),
    "ab\n  ^\nError: bad",
  )
}

///|
test "newline inside an array element" {
  assert_eq(
    at(1, 0).mark(Sequence::from_array(["x", "line1\nline2"])),
    "x \"line1\n  ^^^^^^\nError: bad",
  )
}

///|
test "point after text that ends with a newline is on the empty last line" {
  assert_eq(at(3, 0).mark(Sequence::from_string("ab\n")), "\n^\nError: bad")
}
