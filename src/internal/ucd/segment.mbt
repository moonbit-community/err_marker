///|
/// Extended grapheme cluster boundaries of `text` (UAX #29, Unicode
/// `unicode_version`), as Unicode scalar indices in increasing order. Both
/// ends are included: an empty text has the single boundary `0`, any other
/// text starts with `0` and ends with its number of scalars.
pub fn cluster_boundaries(text : String) -> Array[Int32] {
  let chars = text.to_array()
  let n = chars.length()
  let out = [0]
  if n == 0 {
    return out
  }
  // State carried across positions, updated after each scalar:
  // GB9c: an InCB=Linker followed only by InCB=Extend so far.
  let mut after_linker = incb(chars[0]) == Linker
  // GB11: Extended_Pictographic Extend* so far, then whether a ZWJ followed.
  let mut after_pict = is_extended_pictographic(chars[0])
  let mut after_pict_zwj = false
  // GB12/GB13: number of consecutive Regional_Indicator scalars so far.
  let mut ri_run = if gcb(chars[0]) == RegionalIndicator { 1 } else { 0 }
  for i in 1..<n {
    let prev = gcb(chars[i - 1])
    let cur = gcb(chars[i])
    let cur_incb = incb(chars[i])
    let cur_pict = is_extended_pictographic(chars[i])
    let no_break = if prev == CR && cur == LF {
      true // GB3
    } else if prev == Control || prev == CR || prev == LF {
      false // GB4
    } else if cur == Control || cur == CR || cur == LF {
      false // GB5
    } else if prev == L && (cur == L || cur == V || cur == LV || cur == LVT) {
      true // GB6
    } else if (prev == LV || prev == V) && (cur == V || cur == T) {
      true // GB7
    } else if (prev == LVT || prev == T) && cur == T {
      true // GB8
    } else if cur == Extend || cur == ZWJ {
      true // GB9
    } else if cur == SpacingMark {
      true // GB9a
    } else if prev == Prepend {
      true // GB9b
    } else if after_linker && cur_incb == Consonant {
      true // GB9c
    } else if after_pict_zwj && cur_pict {
      true // GB11
    } else if prev == RegionalIndicator &&
      cur == RegionalIndicator &&
      ri_run % 2 == 1 {
      true // GB12, GB13
    } else {
      false // GB999
    }
    if !no_break {
      out.push(i)
    }
    // Update the carried state with chars[i].
    after_linker = match cur_incb {
      Linker => true
      Extend => after_linker
      _ => false
    }
    if cur_pict {
      after_pict = true
      after_pict_zwj = false
    } else if cur == Extend && after_pict && !after_pict_zwj {
      ()
    } else if cur == ZWJ && after_pict && !after_pict_zwj {
      after_pict_zwj = true
    } else {
      after_pict = false
      after_pict_zwj = false
    }
    ri_run = if cur == RegionalIndicator { ri_run + 1 } else { 0 }
  }
  out.push(n)
  out
}

///|
/// Snaps the span `[start, end)` outward to the boundaries `bounds` (sorted,
/// containing the first and last position): the start moves to the greatest
/// boundary `<= start` and the end to the least boundary `>= end`. This is a
/// closure operator on spans ordered by inclusion: the result contains the
/// span, larger spans snap to larger spans, and snapping twice changes
/// nothing. Positions outside `[first, last]` are clamped first.
pub fn snap(
  bounds : Array[Int32],
  start : Int32,
  end : Int32,
) -> (Int32, Int32) {
  let lo = bounds[0]
  let hi = bounds[bounds.length() - 1]
  let start = if start < lo { lo } else if start > hi { hi } else { start }
  let end = if end < start { start } else if end > hi { hi } else { end }
  (floor_bound(bounds, start), ceil_bound(bounds, end))
}

///|
/// Greatest element of `bounds` that is `<= x` (`bounds[0] <= x`).
fn floor_bound(bounds : Array[Int32], x : Int32) -> Int32 {
  let mut lo = 0
  let mut hi = bounds.length() - 1
  while lo < hi {
    let mid = lo + (hi - lo + 1) / 2
    if bounds[mid] <= x {
      lo = mid
    } else {
      hi = mid - 1
    }
  }
  bounds[lo]
}

///|
/// Least element of `bounds` that is `>= x` (`x <= last`).
fn ceil_bound(bounds : Array[Int32], x : Int32) -> Int32 {
  let mut lo = 0
  let mut hi = bounds.length() - 1
  while lo < hi {
    let mid = lo + (hi - lo) / 2
    if bounds[mid] >= x {
      hi = mid
    } else {
      lo = mid + 1
    }
  }
  bounds[lo]
}
