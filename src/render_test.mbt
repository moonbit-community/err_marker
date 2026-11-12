///|
fn err(msg : String) -> @err_marker.Report {
  @err_marker.Report::new(Error, msg)
}

///|
test "argv: one primary mark with a message" {
  let r = err("unknown mode 'sovle'")
    .with_code("E01")
    .with_mark(
      @err_marker.Mark::primary(
        @err_marker.Span::new(3, 4),
        message="did you mean 'solve'?",
      ),
    )
  inspect(
    r.render(
      @err_marker.Sequence::from_args([
        "sudoku", "export", "a.txt", "sovle", "out.txt",
      ]),
    ),
    content=(
      #|sudoku export a.txt sovle out.txt
      #|                    ^^^^^ did you mean 'solve'?
      #|error[E01]: unknown mode 'sovle'
    ),
  )
}

///|
test "argv: missing argument is a point after the text" {
  let r = err("export needs an output path").with_mark(
    @err_marker.Mark::primary(@err_marker.Span::point(4), message="here"),
  )
  inspect(
    r.render(
      @err_marker.Sequence::from_args(["sudoku", "export", "a.txt", "solve"]),
    ),
    content=(
      #|sudoku export a.txt solve
      #|                         ^ here
      #|error: export needs an output path
    ),
  )
}

///|
test "CJK text: columns follow East Asian Width" {
  let r = err("bad").with_mark(
    @err_marker.Mark::primary(@err_marker.Span::new(2, 4)),
  )
  inspect(
    r.render(@err_marker.Sequence::from_string("数独求解器")),
    content=(
      #|数独求解器
      #|    ^^^^
      #|error: bad
    ),
  )
}

///|
test "CJK elements" {
  let r = err("bad").with_mark(
    @err_marker.Mark::primary(@err_marker.Span::new(2, 4)),
  )
  inspect(
    r.render(
      @err_marker.Sequence::from_array(["数独", "求解", "目标", "文件"]),
    ),
    content=(
      #|数独 求解 目标 文件
      #|          ^^^^^^^^^
      #|error: bad
    ),
  )
}

///|
test "emoji, ZWJ sequence and combining mark are whole clusters" {
  let s = @err_marker.Sequence::from_string(
    "a\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}e\u{301}z",
  )
  // scalar 2 is inside the family emoji: the mark widens to the cluster
  let r1 = err("bad").with_mark(
    @err_marker.Mark::primary(@err_marker.Span::new(2, 3)),
  )
  inspect(
    r1.render(s),
    content=(
      #|a👨‍👩‍👧éz
      #| ^^
      #|error: bad
    ),
  )
  // scalar 7 is the combining accent: the mark widens to "e\u{301}"
  let r2 = err("bad").with_mark(
    @err_marker.Mark::primary(@err_marker.Span::new(7, 8)),
  )
  inspect(
    r2.render(s),
    content=(
      #|a👨‍👩‍👧éz
      #|   ^
      #|error: bad
    ),
  )
}

///|
test "tabs are expanded by the model" {
  let r = err("bad").with_mark(
    @err_marker.Mark::primary(@err_marker.Span::new(2, 3)),
  )
  let s = @err_marker.Sequence::from_string("\tab")
  inspect(
    r.render(s),
    content=(
      #|        ab
      #|         ^
      #|error: bad
    ),
  )
  inspect(
    r.render(s, model=@cursor.Model::new(tab_width=4)),
    content=(
      #|    ab
      #|     ^
      #|error: bad
    ),
  )
}

///|
test "several lines: only the line of the primary mark, with line:col" {
  let r = err("unexpected token")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(11, 12)))
    .with_mark(@err_marker.Mark::secondary(@err_marker.Span::new(0, 3)))
  inspect(
    r.render(@err_marker.Sequence::from_string("let\nx = 1 +;\n")),
    content=(
      #|x = 1 +;
      #|       ^
      #|error at 2:8: unexpected token
    ),
  )
}

///|
test "out of range spans are clamped" {
  let r = err("bad").with_mark(
    @err_marker.Mark::primary(@err_marker.Span::new(2, 99)),
  )
  inspect(
    r.render(@err_marker.Sequence::from_string("abcd")),
    content=(
      #|abcd
      #|  ^^
      #|error: bad
    ),
  )
  inspect(
    r.render(@err_marker.Sequence::from_array([1, 2, 3, 4])),
    content=(
      #|1 2 3 4
      #|    ^^^
      #|error: bad
    ),
  )
}

///|
test "empty input" {
  let r = err("nothing to read").with_mark(
    @err_marker.Mark::primary(@err_marker.Span::point(0)),
  )
  inspect(
    r.render(@err_marker.Sequence::from_string("")),
    content=(
      #|
      #|^
      #|error: nothing to read
    ),
  )
}

///|
test "overlapping marks and several messages" {
  let r = @err_marker.Report::new(Warning, "suspicious call")
    .with_mark(
      @err_marker.Mark::secondary(@err_marker.Span::new(0, 9), message="call"),
    )
    .with_mark(
      @err_marker.Mark::primary(@err_marker.Span::new(4, 7), message="argument"),
    )
    .with_mark(
      @err_marker.Mark::secondary(@err_marker.Span::new(0, 3), message="callee"),
    )
    .with_note("arguments are evaluated first")
  inspect(
    r.render(@err_marker.Sequence::from_string("foo(bar);")),
    content=(
      #|foo(bar);
      #|----^^^-- call
      #|callee
      #|    argument
      #|warning: suspicious call
      #|note: arguments are evaluated first
    ),
  )
}

///|
test "no marks: the whole text and the header" {
  inspect(
    @err_marker.Report::new(Help, "try --help")
    .with_code("H1")
    .render(@err_marker.Sequence::from_string("a\nb")),
    content=(
      #|a
      #|b
      #|help[H1]: try --help
    ),
  )
}

///|
test "colour" {
  let r = err("bad")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(0, 1)))
    .with_mark(@err_marker.Mark::secondary(@err_marker.Span::new(2, 3)))
  inspect(
    r.render(@err_marker.Sequence::from_string("abc"), color=true),
    content=(
      #|abc
      #|[1;31m^[0m [34m-[0m
      #|[1;31merror[0m: bad
    ),
  )
}

///|
test "utf16_to_scalar" {
  let s = "a\u{1F600}b"
  assert_eq(@err_marker.utf16_to_scalar(s, 0), 0)
  assert_eq(@err_marker.utf16_to_scalar(s, 1), 1)
  assert_eq(@err_marker.utf16_to_scalar(s, 2), 1) // inside the pair
  assert_eq(@err_marker.utf16_to_scalar(s, 3), 2)
  assert_eq(@err_marker.utf16_to_scalar(s, 4), 3)
  assert_eq(@err_marker.utf16_to_scalar(s, 99), 3)
}

///|
test "Span::new normalises" {
  assert_eq(@err_marker.Span::new(-3, -1), @err_marker.Span::point(0))
  assert_eq(@err_marker.Span::new(5, 2), @err_marker.Span::point(5))
}
