///|
fn permutations(xs : Array[@err_marker.Mark]) -> Array[Array[@err_marker.Mark]] {
  if xs.length() <= 1 {
    return [xs.copy()]
  }
  let out = []
  for i in 0..<xs.length() {
    let rest = []
    for j in 0..<xs.length() {
      if j != i {
        rest.push(xs[j])
      }
    }
    for p in permutations(rest) {
      out.push([xs[i], ..p])
    }
  }
  out
}

///|
fn render_marks(
  marks : Array[@err_marker.Mark],
  seq : @err_marker.Sequence[Char],
) -> String {
  marks
  .fold(init=@err_marker.Report::new(Error, "x"), (r, m) => r.with_mark(m))
  .render(seq)
}

///|
/// Overlapping marks with ties at every level of the tie-break: the same
/// span with different messages, the same start with different ends, and a
/// higher priority.
fn tricky_marks() -> Array[@err_marker.Mark] {
  [
    @err_marker.Mark::secondary(@err_marker.Span::new(0, 6), message="b"),
    @err_marker.Mark::secondary(@err_marker.Span::new(0, 6), message="a"),
    @err_marker.Mark::primary(@err_marker.Span::new(0, 3), message="p"),
    @err_marker.Mark::secondary(@err_marker.Span::new(2, 5)).with_priority(1),
  ]
}

///|
test "overlay is commutative: every order of the marks renders the same" {
  let seq = @err_marker.Sequence::from_string("abcdefgh")
  let marks = tricky_marks()
  let expected = render_marks(marks, seq)
  for p in permutations(marks) {
    assert_eq(render_marks(p, seq), expected)
  }
}

///|
test "overlay is idempotent: repeating marks changes nothing" {
  let seq = @err_marker.Sequence::from_string("abcdefgh")
  let marks = tricky_marks()
  assert_eq(render_marks([..marks, ..marks], seq), render_marks(marks, seq))
}

///|
test "the tie-break decides each column" {
  let seq = @err_marker.Sequence::from_string("abcdefgh")
  inspect(
    render_marks(tricky_marks(), seq),
    content=(
      #|abcdefgh
      #|^^---- a
      #|p
      #|b
      #|error: x
    ),
  )
}
