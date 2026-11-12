///|
fn arg(pos : Int32) -> ErrorData {
  ErrorData::make("bad", err_pos=pos)
}

///|
test "element with a space is quoted and marked as one token" {
  assert_eq(
    arg(1).mark(Sequence::from_array(["solve", "my file.txt"])),
    "solve \"my file.txt\"\n      ^^^^^^^^^^^^^\nError: bad",
  )
}

///|
test "empty element is quoted and can be marked" {
  assert_eq(
    arg(1).mark(Sequence::from_array(["fmt", "", "x"])),
    "fmt \"\" x\n    ^^\nError: bad",
  )
}

///|
test "element containing the separator is quoted" {
  assert_eq(
    arg(0).mark(Sequence::from_array(["a,b", "c"], join=",")),
    "\"a,b\",c\n^^^^^\nError: bad",
  )
}

///|
test "quotes and backslashes inside a quoted element are escaped" {
  assert_eq(
    arg(0).mark(Sequence::from_array(["say \"hi\"", "a\\b"])),
    "\"say \\\"hi\\\"\" a\\b\n^^^^^^^^^^^^\nError: bad",
  )
}

///|
test "marker after a quoted element lines up" {
  assert_eq(
    arg(2).mark(Sequence::from_array(["cp", "a b", "c"])),
    "cp \"a b\" c\n         ^\nError: bad",
  )
}

///|
test "plain elements are not quoted" {
  assert_eq(
    arg(1).mark(Sequence::from_array(["solve", "a.txt"])),
    "solve a.txt\n      ^^^^^\nError: bad",
  )
}
