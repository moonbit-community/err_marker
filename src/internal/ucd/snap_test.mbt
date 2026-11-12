///|
/// Exhaustive check of the closure-operator laws of `snap` for every set of
/// boundaries on `0..=n` (with `0` and `n` included) and every pair of spans,
/// for n up to 6.
test "snap is extensive, monotone and idempotent" {
  for n in 1..<=6 {
    for mask in 0..<(1 << (n - 1)) {
      let bounds = [0]
      for k in 1..<n {
        if ((mask >> (k - 1)) & 1) == 1 {
          bounds.push(k)
        }
      }
      bounds.push(n)
      let spans = []
      for a in 0..<=n {
        for b in a..<=n {
          spans.push((a, b))
        }
      }
      for s in spans {
        let (a, b) = s
        let (sa, sb) = @ucd.snap(bounds, a, b)
        // extensive
        assert_true(sa <= a && b <= sb)
        // results are boundaries
        assert_true(bounds.contains(sa) && bounds.contains(sb))
        // idempotent
        assert_eq(@ucd.snap(bounds, sa, sb), (sa, sb))
        // monotone
        for t in spans {
          let (c, d) = t
          if c <= a && b <= d {
            let (tc, td) = @ucd.snap(bounds, c, d)
            assert_true(tc <= sa && sb <= td)
          }
        }
      }
    }
  }
}

///|
test "zero-width span inside a cluster widens to the cluster" {
  assert_eq(@ucd.snap([0, 2, 3], 1, 1), (0, 2))
  assert_eq(@ucd.snap([0, 2, 3], 2, 2), (2, 2))
}

///|
test "cluster boundaries of common sequences" {
  // e + combining acute
  assert_eq(@ucd.cluster_boundaries("e\u{301}x"), [0, 2, 3])
  // CR LF stays together
  assert_eq(@ucd.cluster_boundaries("a\r\nb"), [0, 1, 3, 4])
  // family emoji: man ZWJ woman ZWJ girl
  assert_eq(
    @ucd.cluster_boundaries("\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}!"),
    [0, 5, 6],
  )
  // two flags = four regional indicators
  assert_eq(@ucd.cluster_boundaries("\u{1F1EF}\u{1F1F5}\u{1F1FA}\u{1F1F8}"), [
    0, 2, 4,
  ])
  assert_eq(@ucd.cluster_boundaries(""), [0])
}
