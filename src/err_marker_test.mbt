///|
test {
  let ed = ErrorData::make(
    "Error_Test",
    err_type=Some("Test"),
    err_pos=2,
    err_offset=3,
  )
  let ed1 = ErrorData::make(
    "Error_Test",
    err_type=Some("Test"),
    err_pos=0,
    err_offset=3,
  )
  let ed2 = ErrorData::make(
    "Error_Test",
    err_type=Some("Test"),
    err_pos=4,
    err_offset=0,
  )
  let raw_seq = [0, 1, 2, 3, 4, 5, 6, 7]
  let arr_seq = Sequence::from_array(raw_seq)
  let str_seq = Sequence::from_string(
    raw_seq
    .map(x => x + 'A'.to_int())
    .map(Int::unsafe_to_char)
    .map(Char::to_string)
    .join(""),
  )
  assert_eq(
    (
      #|0 1 2 3 4 5 6 7
      #|    ^^^^^^^
      #|Error(Test): Error_Test
    ),
    ed.mark(arr_seq),
  )
  assert_eq(
    (
      #|0 1 2 3 4 5 6 7
      #|^^^^^^^
      #|Error(Test): Error_Test
    ),
    ed1.mark(arr_seq),
  )
  assert_eq(
    (
      #|0 1 2 3 4 5 6 7
      #|        ^
      #|Error(Test): Error_Test
    ),
    ed2.mark(arr_seq),
  )
  assert_eq(
    (
      #|ABCDEFGH
      #|  ^^^^
      #|Error(Test): Error_Test
    ),
    ed.mark(str_seq),
  )
  assert_eq(
    (
      #|ABCDEFGH
      #|^^^^
      #|Error(Test): Error_Test
    ),
    ed1.mark(str_seq),
  )
  assert_eq(
    (
      #|ABCDEFGH
      #|    ^
      #|Error(Test): Error_Test
    ),
    ed2.mark(str_seq),
  )
}
