///|
/// #6: the deprecated `ErrorData::mark` now uses the 0.2.0 engine, so wide
/// characters line up while the 0.1 units (UTF-16 offsets, inclusive offset)
/// are kept.
test "CJK string: the marker covers the right characters" {
  let e = ErrorData::make("bad", err_pos=2, err_offset=1)
  assert_eq(
    e.mark(Sequence::from_string("数独求解器")),
    "数独求解器\n    ^^^^\nError: bad",
  )
}

///|
test "CJK elements: the marker covers the right elements" {
  let e = ErrorData::make("bad", err_pos=2, err_offset=1)
  assert_eq(
    e.mark(Sequence::from_array(["数独", "求解", "目标", "文件"])),
    "数独 求解 目标 文件\n          ^^^^^^^^^\nError: bad",
  )
}

///|
test "emoji before the span counts two columns" {
  // UTF-16 offset 2 is the "a" after the two code units of the emoji
  let e = ErrorData::make("bad", err_pos=2)
  assert_eq(e.mark(Sequence::from_string("😀ab")), "😀ab\n  ^\nError: bad")
}
