///|
test "tab before the span is copied into the padding (string)" {
  let e = @err_marker.ErrorData::make("bad", err_pos=2, err_offset=1)
  assert_eq(
    e.mark(@err_marker.Sequence::from_string("\tabcdef")),
    "\tabcdef\n\t ^^\nError: bad",
  )
}

///|
test "tab separator before the span is copied into the padding (array)" {
  let e = @err_marker.ErrorData::make("bad", err_pos=1)
  assert_eq(
    e.mark(@err_marker.Sequence::from_array(["a", "b"], join="\t")),
    "a\tb\n \t^\nError: bad",
  )
}

///|
test "padding without tabs is unchanged" {
  let e = @err_marker.ErrorData::make("bad", err_pos=4)
  assert_eq(
    e.mark(@err_marker.Sequence::from_string("ab cdef")),
    "ab cdef\n    ^\nError: bad",
  )
}
