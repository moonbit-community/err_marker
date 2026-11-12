///|
test "rendered text of sequences" {
  assert_eq(
    @err_marker.Sequence::from_args(["cp", "a b", ""]).rendered(),
    "cp \"a b\" \"\"",
  )
  assert_eq(@err_marker.Sequence::from_string("x\ty").rendered(), "x\ty")
}

///|
test "locate: hull of elements, clamp, snap" {
  let args = @err_marker.Sequence::from_args(["cp", "a b", "c"])
  assert_eq(args.locate(@err_marker.Span::new(1, 2)), (3, 8))
  assert_eq(args.locate(@err_marker.Span::new(1, 9)), (3, 10))
  assert_eq(args.locate(@err_marker.Span::point(3)), (10, 10))
  let s = @err_marker.Sequence::from_string("ae\u{301}z")
  assert_eq(s.locate(@err_marker.Span::new(2, 3)), (1, 3))
}
