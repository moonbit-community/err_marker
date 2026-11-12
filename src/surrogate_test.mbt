///|
fn su(pos : Int32, offset : Int32) -> @err_marker.ErrorData {
  @err_marker.ErrorData::make("bad", err_pos=pos, err_offset=offset)
}

///|
test "start on a low surrogate is widened to the whole character" {
  assert_eq(
    su(1, 0).mark(@err_marker.Sequence::from_string("😀abc")),
    "😀abc\n^^\nError: bad",
  )
}

///|
test "end inside a surrogate pair is widened to the whole character" {
  assert_eq(
    su(0, 0).mark(@err_marker.Sequence::from_string("😀abc")),
    "😀abc\n^^\nError: bad",
  )
  assert_eq(
    su(2, 0).mark(@err_marker.Sequence::from_string("a😀b")),
    "a😀b\n ^^\nError: bad",
  )
}

///|
test "spans on code point boundaries are unchanged" {
  assert_eq(
    su(2, 1).mark(@err_marker.Sequence::from_string("😀abc")),
    "😀abc\n  ^^\nError: bad",
  )
  assert_eq(
    su(1, 0).mark(@err_marker.Sequence::from_array(["😀", "x"])),
    "😀 x\n   ^\nError: bad",
  )
}
