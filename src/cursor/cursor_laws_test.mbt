///|
/// All strings of length 0..=max over a small alphabet of single-cluster
/// pieces: a narrow letter, a wide character, a tab and a line break.
fn all_texts(max : Int32) -> Array[String] {
  let alphabet = ["a", "中", "\t", "\n"]
  let out = [""]
  let mut layer = [""]
  for _ in 0..<max {
    let next = []
    for s in layer {
      for p in alphabet {
        next.push(s + p)
      }
    }
    out.append(next)
    layer = next
  }
  out
}

///|
/// Independent reference: step the cursor scalar by scalar, straight from
/// the definitions, without moves.
fn simulate(t : Int32, text : String, p : @cursor.Pos) -> @cursor.Pos {
  let mut line = p.line
  let mut col = p.col
  for c in text {
    if c == '\t' {
      col = t * (col / t + 1)
    } else if c == '\n' {
      line += 1
      col = 0
    } else if c == '中' {
      col += 2
    } else {
      col += 1
    }
  }
  { line, col, }
}

///|
test "apply(text(s)) agrees with stepping, for every short text" {
  for t in 1..<=4 {
    let m = @cursor.Model::new(tab_width=t)
    for s in all_texts(4) {
      let mv = m.text(s)
      for c in 0..<(3 * t + 2) {
        let p : @cursor.Pos = { line: 0, col: c, }
        assert_eq(m.apply(mv, p), simulate(t, s, p))
      }
    }
  }
}

///|
test "homomorphism: text(u + v) == compose(text(u), text(v))" {
  for t in 1..<=4 {
    let m = @cursor.Model::new(tab_width=t)
    let texts = all_texts(3)
    for u in texts {
      for v in texts {
        assert_eq(m.text(u + v), m.compose(m.text(u), m.text(v)))
      }
    }
  }
}

///|
test "monoid: associativity and identity" {
  for t in 1..<=4 {
    let m = @cursor.Model::new(tab_width=t)
    let moves = all_texts(2).map(s => m.text(s))
    for x in moves {
      assert_eq(m.compose(m.identity(), x), x)
      assert_eq(m.compose(x, m.identity()), x)
      for y in moves {
        for z in moves {
          assert_eq(
            m.compose(m.compose(x, y), z),
            m.compose(x, m.compose(y, z)),
          )
        }
      }
    }
  }
}

///|
test "normal forms are canonical: equal actions give equal moves" {
  for t in 1..<=4 {
    let m = @cursor.Model::new(tab_width=t)
    let texts = all_texts(3)
    let moves = texts.map(s => m.text(s))
    for i in 0..<moves.length() {
      for j in 0..<moves.length() {
        let mut same = true
        for line in 0..<2 {
          for c in 0..<(3 * t + 2) {
            let p : @cursor.Pos = { line, col: c, }
            if m.apply(moves[i], p) != m.apply(moves[j], p) {
              same = false
            }
          }
        }
        assert_eq(same, moves[i] == moves[j])
      }
    }
  }
}

///|
test "tab width below 1 counts as 1" {
  assert_eq(@cursor.Model::new(tab_width=0).tab_width, 1)
  let m = @cursor.Model::new(tab_width=1)
  assert_eq(m.tab(), m.shift(1))
}
