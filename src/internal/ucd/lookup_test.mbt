///|
/// Expected values below were read directly from the UCD 18.0.0 source files,
/// not from the generated tables.
test "unicode version" {
  assert_eq(@ucd.unicode_version, "18.0.0")
}

///|
test "East_Asian_Width wide and fullwidth" {
  assert_eq(@ucd.is_wide('\u{1100}'), true) // W
  assert_eq(@ucd.is_wide('\u{10FF}'), false) // N
  assert_eq(@ucd.is_wide('\u{4E00}'), true) // W
  assert_eq(@ucd.is_wide('\u{FF01}'), true) // F
  assert_eq(@ucd.is_wide('\u{1F600}'), true) // W
  assert_eq(@ucd.is_wide('a'), false) // Na
}

///|
test "East_Asian_Width ambiguous" {
  assert_eq(@ucd.is_ambiguous('\u{A1}'), true)
  assert_eq(@ucd.is_ambiguous('\u{2010}'), true)
  assert_eq(@ucd.is_ambiguous('\u{A0}'), false) // N
  assert_eq(@ucd.is_ambiguous('a'), false)
}

///|
test "zero width: Mn, Me, Cf and Default_Ignorable_Code_Point" {
  assert_eq(@ucd.is_zero_width('\u{300}'), true) // Mn
  assert_eq(@ucd.is_zero_width('\u{200B}'), true) // Cf, DI
  assert_eq(@ucd.is_zero_width('\u{AD}'), true) // Cf, DI
  assert_eq(@ucd.is_zero_width('\u{34F}'), true) // Mn, DI
  assert_eq(@ucd.is_zero_width('A'), false) // Lu
}

///|
test "Extended_Pictographic" {
  assert_eq(@ucd.is_extended_pictographic('\u{A9}'), true)
  assert_eq(@ucd.is_extended_pictographic('\u{1F600}'), true)
  assert_eq(@ucd.is_extended_pictographic('A'), false)
}

///|
test "Grapheme_Cluster_Break" {
  assert_eq(@ucd.gcb('\r'), CR)
  assert_eq(@ucd.gcb('\n'), LF)
  assert_eq(@ucd.gcb('\u{0}'), Control)
  assert_eq(@ucd.gcb('\u{300}'), Extend)
  assert_eq(@ucd.gcb('\u{200D}'), ZWJ)
  assert_eq(@ucd.gcb('\u{1F1E6}'), RegionalIndicator)
  assert_eq(@ucd.gcb('\u{600}'), Prepend)
  assert_eq(@ucd.gcb('\u{903}'), SpacingMark)
  assert_eq(@ucd.gcb('\u{1100}'), L)
  assert_eq(@ucd.gcb('\u{1160}'), V)
  assert_eq(@ucd.gcb('\u{11A8}'), T)
  assert_eq(@ucd.gcb('\u{AC00}'), LV)
  assert_eq(@ucd.gcb('\u{AC01}'), LVT)
  assert_eq(@ucd.gcb('a'), Other)
}

///|
test "Indic_Conjunct_Break" {
  assert_eq(@ucd.incb('\u{94D}'), Linker)
  assert_eq(@ucd.incb('\u{915}'), Consonant)
  assert_eq(@ucd.incb('\u{300}'), Extend)
  assert_eq(@ucd.incb('\u{200D}'), Extend)
  assert_eq(@ucd.incb('a'), None)
}
