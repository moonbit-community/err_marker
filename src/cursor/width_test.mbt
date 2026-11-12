///|
fn w(s : String) -> Int32 {
  @cursor.Model::new().cluster_width(s)
}

///|
test "cluster widths" {
  assert_eq(w("a"), 1)
  assert_eq(w("中"), 2) // East_Asian_Width W
  assert_eq(w("Ａ"), 2) // F
  assert_eq(w("e\u{301}"), 1) // base + combining mark
  assert_eq(w("\u{301}"), 0) // lone Mn
  assert_eq(w("\u{200B}"), 0) // Cf, Default_Ignorable
  assert_eq(w("\u{7}"), 0) // control
  assert_eq(w("가"), 2) // Hangul syllable
  assert_eq(w("\u{1100}\u{1161}\u{11A8}"), 2) // conjoining jamo L V T
  assert_eq(w("\u{1F600}"), 2) // emoji, W
  assert_eq(w("\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}"), 2) // ZWJ sequence
  assert_eq(w("\u{1F1EF}\u{1F1F5}"), 2) // flag
  assert_eq(w("\u{2764}"), 1) // N, text presentation
  assert_eq(w("\u{2764}\u{FE0F}"), 2) // VS16
}

///|
test "ambiguous width follows the model" {
  assert_eq(w("\u{A1}"), 1)
  assert_eq(@cursor.Model::new(ambiguous_wide=true).cluster_width("\u{A1}"), 2)
}

///|
test "clusters and text moves of mixed text" {
  assert_eq(@cursor.clusters("e\u{301}中\r\nx"), [
    "e\u{301}", "中", "\r\n", "x",
  ])
  let m = @cursor.Model::new()
  assert_eq(m.apply(m.text("数独\t!"), { line: 0, col: 0, }), {
    line: 0,
    col: 9,
  })
  assert_eq(m.apply(m.text("ab\r\n中"), { line: 3, col: 7, }), {
    line: 4,
    col: 2,
  })
  assert_eq(
    m.apply(m.text("\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}x"), {
      line: 0,
      col: 0,
    }),
    { line: 0, col: 3, },
  )
}
