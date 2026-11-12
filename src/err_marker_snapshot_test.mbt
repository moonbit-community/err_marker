///|
/// Snapshot tests that pin the 0.1.3 behaviour for ASCII input. They are the
/// baseline for the 0.1.4 fixes and the 0.2 migration (see #5). Inputs that
/// trigger the known bugs (#6–#11) are deliberately not covered here; each fix
/// brings its own test.

///|
priv struct Point {
  x : Int32
  y : Int32
}

///|
impl Show for Point with fn output(self, logger) {
  logger.write_string("(\{self.x},\{self.y})")
}

///|
fn ed(pos : Int32, offset : Int32) -> @err_marker.ErrorData {
  @err_marker.ErrorData::make(
    "bad value",
    err_type=Some("Arg"),
    err_pos=pos,
    err_offset=offset,
  )
}

///|
test "array: first element" {
  inspect(
    ed(0, 0).mark(@err_marker.Sequence::from_array(["solve", "a.txt", "out"])),
    content=(
      #|solve a.txt out
      #|^^^^^
      #|Error(Arg): bad value
    ),
  )
}

///|
test "array: middle span" {
  inspect(
    ed(1, 1).mark(
      @err_marker.Sequence::from_array(["export", "a.txt", "fmt", "out"]),
    ),
    content=(
      #|export a.txt fmt out
      #|       ^^^^^^^^^
      #|Error(Arg): bad value
    ),
  )
}

///|
test "array: last element" {
  inspect(
    ed(2, 0).mark(@err_marker.Sequence::from_array(["solve", "a.txt", "out"])),
    content=(
      #|solve a.txt out
      #|            ^^^
      #|Error(Arg): bad value
    ),
  )
}

///|
test "array: multi-character separator" {
  inspect(
    ed(1, 1).mark(@err_marker.Sequence::from_array([1, 22, 333, 4], join=", ")),
    content=(
      #|1, 22, 333, 4
      #|   ^^^^^^^
      #|Error(Arg): bad value
    ),
  )
}

///|
test "array: elements with a custom Show" {
  inspect(
    ed(1, 0).mark(
      @err_marker.Sequence::from_array([{ x: 1, y: 2, }, { x: 30, y: 40, }]),
    ),
    content=(
      #|(1,2) (30,40)
      #|      ^^^^^^^
      #|Error(Arg): bad value
    ),
  )
}

///|
test "string: start, middle and end" {
  let s = @err_marker.Sequence::from_string("sudoku solve")
  inspect(
    ed(0, 5).mark(s),
    content=(
      #|sudoku solve
      #|^^^^^^
      #|Error(Arg): bad value
    ),
  )
  inspect(
    ed(7, 1).mark(s),
    content=(
      #|sudoku solve
      #|       ^^
      #|Error(Arg): bad value
    ),
  )
  inspect(
    ed(11, 0).mark(s),
    content=(
      #|sudoku solve
      #|           ^
      #|Error(Arg): bad value
    ),
  )
}

///|
test "default position draws no marker" {
  inspect(
    @err_marker.ErrorData::make("no position").mark(
      @err_marker.Sequence::from_string("abc"),
    ),
    content=(
      #|abc
      #|
      #|Error: no position
    ),
  )
}

///|
test "custom marker character" {
  inspect(
    ed(1, 0).mark(
      @err_marker.Sequence::from_array(["a", "bb", "c"]),
      marker='~',
    ),
    content=(
      #|a bb c
      #|  ~~
      #|Error(Arg): bad value
    ),
  )
}

///|
test "custom message formatter and missing error type" {
  let gen_msg = fn(t : String?, m : String) -> String {
    match t {
      Some(t) => "[\{t}] \{m}"
      None => "[-] \{m}"
    }
  }
  inspect(
    ed(0, 0).mark(@err_marker.Sequence::from_string("xy"), gen_msg~),
    content=(
      #|xy
      #|^
      #|[Arg] bad value
    ),
  )
  inspect(
    @err_marker.ErrorData::make("plain", err_pos=1).mark(
      @err_marker.Sequence::from_string("xy"),
      gen_msg~,
    ),
    content=(
      #|xy
      #| ^
      #|[-] plain
    ),
  )
  inspect(
    @err_marker.ErrorData::make("plain", err_pos=1).mark(
      @err_marker.Sequence::from_string("xy"),
    ),
    content=(
      #|xy
      #| ^
      #|Error: plain
    ),
  )
}
