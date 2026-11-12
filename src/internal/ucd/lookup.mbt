///|
/// Grapheme_Cluster_Break property values (UAX #29), in the order the
/// generator numbers them.
#derive(Eq, Debug)
pub(all) enum Gcb {
  Other
  CR
  LF
  Control
  Extend
  ZWJ
  RegionalIndicator
  Prepend
  SpacingMark
  L
  V
  T
  LV
  LVT
}

///|
/// Indic_Conjunct_Break property values (UAX #44, used by GB9c), in the order
/// the generator numbers them.
#derive(Eq, Debug)
pub(all) enum Incb {
  None
  Linker
  Consonant
  Extend
}

///|
/// Index of the range in `first`/`last` (sorted, disjoint) that contains
/// `cp`, or -1.
fn find_range(
  first : FixedArray[Int32],
  last : FixedArray[Int32],
  cp : Int32,
) -> Int32 {
  let mut lo = 0
  let mut hi = first.length() - 1
  while lo <= hi {
    let mid = lo + (hi - lo) / 2
    if cp < first[mid] {
      hi = mid - 1
    } else if cp > last[mid] {
      lo = mid + 1
    } else {
      return mid
    }
  }
  -1
}

///|
/// East_Asian_Width is Wide (W) or Fullwidth (F).
pub fn is_wide(c : Char) -> Bool {
  find_range(wide_first, wide_last, c.to_int()) >= 0
}

///|
/// East_Asian_Width is Ambiguous (A).
pub fn is_ambiguous(c : Char) -> Bool {
  find_range(ambiguous_first, ambiguous_last, c.to_int()) >= 0
}

///|
/// General_Category is Mn, Me or Cf, or the code point is
/// Default_Ignorable_Code_Point.
pub fn is_zero_width(c : Char) -> Bool {
  find_range(zero_width_first, zero_width_last, c.to_int()) >= 0
}

///|
/// Extended_Pictographic (UTS #51).
pub fn is_extended_pictographic(c : Char) -> Bool {
  find_range(
    extended_pictographic_first,
    extended_pictographic_last,
    c.to_int(),
  ) >=
  0
}

///|
/// Grapheme_Cluster_Break property of `c`.
pub fn gcb(c : Char) -> Gcb {
  let i = find_range(gcb_first, gcb_last, c.to_int())
  if i < 0 {
    return Other
  }
  match gcb_value[i] {
    1 => CR
    2 => LF
    3 => Control
    4 => Extend
    5 => ZWJ
    6 => RegionalIndicator
    7 => Prepend
    8 => SpacingMark
    9 => L
    10 => V
    11 => T
    12 => LV
    13 => LVT
    _ => Other
  }
}

///|
/// Indic_Conjunct_Break property of `c`.
pub fn incb(c : Char) -> Incb {
  let i = find_range(incb_first, incb_last, c.to_int())
  if i < 0 {
    return None
  }
  match incb_value[i] {
    1 => Linker
    2 => Consonant
    3 => Extend
    _ => None
  }
}
