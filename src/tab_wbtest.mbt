///|
test "tab before the span is expanded with the marker under it (string)" {
  let e = ErrorData::make("bad", err_pos=2, err_offset=1)
  assert_eq(
    e.mark(Sequence::from_string("\tabcdef")),
    "        abcdef\n         ^^\nError: bad",
  )
}

///|
test "tab separator before the span is expanded (array)" {
  let e = ErrorData::make("bad", err_pos=1)
  assert_eq(
    e.mark(Sequence::from_array(["a", "b"], join="\t")),
    "a       b\n        ^\nError: bad",
  )
}

///|
test "padding without tabs is unchanged" {
  let e = ErrorData::make("bad", err_pos=4)
  assert_eq(
    e.mark(Sequence::from_string("ab cdef")),
    "ab cdef\n    ^\nError: bad",
  )
}
