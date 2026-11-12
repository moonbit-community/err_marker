///|
/// A cursor position: zero-based line and column, in terminal columns.
#derive(Eq, Debug)
pub(all) struct Pos {
  line : Int32
  col : Int32
}

///|
/// How a piece of text moves the cursor, in one of three normal forms. With
/// `T(x) = t * (x / t + 1)` the next tab stop after column `x` for tab width
/// `t`:
///
/// - `Shift(k)` maps `(l, c)` to `(l, c + k)`, with `k >= 0`;
/// - `Tab(a, b)` maps `(l, c)` to `(l, T(c + a) + b)`, with `0 <= a < t` and
///   `b >= 0`;
/// - `Break(n, k)` maps `(l, c)` to `(l + n, k)`, with `n >= 1` and `k >= 0`.
///
/// Values can only be built through a `Model`, which keeps them in normal
/// form, so two moves are equal exactly when they act the same on every
/// position.
#derive(Eq, Debug)
pub enum Move {
  Shift(Int32)
  Tab(Int32, Int32)
  Break(Int32, Int32)
}

///|
/// The layout model: the tab width and whether East Asian Ambiguous
/// characters are wide. Moves are only composed within one model.
#derive(Eq, Debug)
pub struct Model {
  tab_width : Int32
  ambiguous_wide : Bool
}

///|
/// A model with tab width `tab_width` (at least 1; smaller values count as 1)
/// and, if `ambiguous_wide`, East Asian Ambiguous characters two columns wide.
pub fn Model::new(
  tab_width~ : Int32 = 8,
  ambiguous_wide~ : Bool = false,
) -> Model {
  { tab_width: if tab_width < 1 { 1 } else { tab_width }, ambiguous_wide, }
}

///|
/// The move that changes nothing.
pub fn Model::identity(_self : Model) -> Move {
  Shift(0)
}

///|
/// `k` columns to the right (`k < 0` counts as 0).
pub fn Model::shift(_self : Model, k : Int32) -> Move {
  Shift(if k < 0 { 0 } else { k })
}

///|
/// One tab: to the next tab stop.
pub fn Model::tab(self : Model) -> Move {
  // With tab width 1 a tab is one column; keeping it a shift keeps normal
  // forms unique.
  if self.tab_width == 1 {
    Shift(1)
  } else {
    Tab(0, 0)
  }
}

///|
/// One line break: to column 0 of the next line.
pub fn Model::newline(_self : Model) -> Move {
  Break(1, 0)
}

///|
fn next_stop(t : Int32, x : Int32) -> Int32 {
  t * (x / t + 1)
}

///|
/// Applies a move to a position.
pub fn Model::apply(self : Model, m : Move, p : Pos) -> Pos {
  match m {
    Shift(k) => { line: p.line, col: p.col + k, }
    Tab(a, b) =>
      { line: p.line, col: next_stop(self.tab_width, p.col + a) + b, }
    Break(n, k) => { line: p.line + n, col: k, }
  }
}

///|
/// The move of `first` followed by `then`:
/// `apply(compose(first, then), p) == apply(then, apply(first, p))`.
pub fn Model::compose(self : Model, first : Move, then : Move) -> Move {
  let t = self.tab_width
  match (first, then) {
    (_, Break(n, k)) =>
      match first {
        Break(n1, _) => Break(n1 + n, k)
        _ => Break(n, k)
      }
    (Break(n1, k1), _) => Break(n1, self.apply(then, { line: 0, col: k1, }).col)
    (Shift(k1), Shift(k2)) => Shift(k1 + k2)
    (Shift(k1), Tab(a, b)) => {
      // T(x + q t + r) = T(x + r) + q t
      let a1 = k1 + a
      Tab(a1 % t, b + t * (a1 / t))
    }
    (Tab(a, b), Shift(k)) => Tab(a, b + k)
    // T(T(x) + d) = T(x) + T(d), because T(x) is a multiple of t
    (Tab(a1, b1), Tab(a2, b2)) => Tab(a1, next_stop(t, b1 + a2) + b2)
  }
}

///|
/// Display width of one extended grapheme cluster that is not a tab or a line
/// break, in terminal columns. Rules, in order (see the design page):
///
/// 1. a cluster of two regional indicators (a flag), a cluster that contains
///    U+200D ZERO WIDTH JOINER after an Extended_Pictographic base, or a
///    cluster that contains U+FE0F VARIATION SELECTOR-16 is 2;
/// 2. otherwise the width of the base (first) scalar: 0 for controls, for
///    General_Category Mn, Me, Cf, Default_Ignorable_Code_Point and Hangul
///    medial vowels and final consonants (convention); 2 for East_Asian_Width
///    W and F; 2 for Ambiguous if the model says so; 1 otherwise.
pub fn Model::cluster_width(self : Model, cluster : String) -> Int32 {
  let chars = cluster.to_array()
  if chars.is_empty() {
    return 0
  }
  let base = chars[0]
  if @ucd.gcb(base) == RegionalIndicator {
    return if chars.length() >= 2 { 2 } else { 1 }
  }
  if chars.contains('\u{FE0F}') {
    return 2
  }
  if @ucd.is_extended_pictographic(base) && chars.contains('\u{200D}') {
    return 2
  }
  let g = @ucd.gcb(base)
  if g == Control || g == CR || g == LF || g == V || g == T {
    0
  } else if @ucd.is_zero_width(base) {
    0
  } else if @ucd.is_wide(base) {
    2
  } else if self.ambiguous_wide && @ucd.is_ambiguous(base) {
    2
  } else {
    1
  }
}

///|
/// The move of one extended grapheme cluster: a tab, a line break (`"\n"`,
/// `"\r"` or `"\r\n"`), or a shift by its display width.
pub fn Model::cluster(self : Model, cluster : String) -> Move {
  match cluster {
    "\t" => self.tab()
    "\n" | "\r" | "\r\n" => self.newline()
    _ => Shift(self.cluster_width(cluster))
  }
}

///|
/// The extended grapheme clusters of `text` (UAX #29).
pub fn clusters(text : String) -> Array[String] {
  let chars = text.to_array()
  let bounds = @ucd.cluster_boundaries(text)
  let out = []
  for i in 0..<(bounds.length() - 1) {
    let sb = StringBuilder()
    for k in bounds[i]..<bounds[i + 1] {
      sb.write_char(chars[k])
    }
    out.push(sb.to_string())
  }
  out
}

///|
/// The move of a whole text: the composition of the moves of its clusters.
/// This is a monoid homomorphism: `text(u + v)` equals
/// `compose(text(u), text(v))` whenever `u` ends on a cluster boundary of
/// `u + v`.
pub fn Model::text(self : Model, text : String) -> Move {
  clusters(text).fold(init=Shift(0), (acc, g) => {
    self.compose(acc, self.cluster(g))
  })
}
