# cursor API

<!-- API page: Purpose, Importing, then every public name in pkg.generated.mbti, grouped by purpose, and nothing else. -->

## Purpose

`KCN-judu/err_marker/cursor` computes where text puts a terminal cursor. A
piece of text becomes a `Move`, moves compose like functions, and applying a
move to a `Pos` gives the line and column where the text ends. Widths follow
Unicode 18.0.0: grapheme clusters (UAX #29) and East Asian Width (UAX #11).
The mathematics is in the [design](../design/cursor.md).

## Importing

```moonbit nocheck
import {
  "KCN-judu/err_marker/cursor",
}
```

The examples call it as `@cursor`.

## Positions and moves

### `Pos`

A zero-based line and column, in terminal columns.

```mbti
pub(all) struct Pos {
  line : Int32
  col : Int32
}
```

### `Move`

How a piece of text moves the cursor, in one of three normal forms.

```mbti
pub enum Move {
  Shift(Int32)
  Tab(Int32, Int32)
  Break(Int32, Int32)
}
```

With $T(x) = t(\lfloor x/t \rfloor + 1)$, the next tab stop after column $x$
for tab width $t$: `Shift(k)` maps column $c$ to $c + k$; `Tab(a, b)` maps
$c$ to $T(c + a) + b$ with $0 \le a < t$; `Break(n, k)` maps $(\ell, c)$ to
$(\ell + n, k)$. Moves can be matched on but only built through a `Model`,
which keeps them in normal form, so two moves are equal exactly when they act
the same on every position.

## Models

### `Model`

The layout model: the tab width and whether East Asian Ambiguous characters
are wide.

```mbti
pub struct Model {
  tab_width : Int32
  ambiguous_wide : Bool
}
```

Moves are composed and applied within one model.

### `Model::new`

```mbti
pub fn Model::new(tab_width? : Int32, ambiguous_wide? : Bool) -> Self
```

The defaults are tab width 8 and narrow Ambiguous characters. A tab width
below 1 counts as 1.

### `Model::identity`, `Model::shift`, `Model::tab`, `Model::newline`

```mbti
pub fn Model::identity(Self) -> Move
pub fn Model::shift(Self, Int32) -> Move
pub fn Model::tab(Self) -> Move
pub fn Model::newline(Self) -> Move
```

The move that does nothing; `k` columns to the right (a negative `k` counts
as 0); one tab; one line break to column 0. With tab width 1, `tab` is
`shift(1)`.

### `Model::compose`

```mbti
pub fn Model::compose(Self, Move, Move) -> Move
```

`compose(first, then)` is the move of `first` followed by `then`. It is
associative, has `identity` as unit, and satisfies

$$
\texttt{apply}(\texttt{compose}(f, g), p) = \texttt{apply}(g, \texttt{apply}(f, p)).
$$

### `Model::apply`

```mbti
pub fn Model::apply(Self, Move, Pos) -> Pos
```

Applies a move to a position.

## Text

### `clusters`

```mbti
pub fn clusters(String) -> Array[String]
```

Splits a string into extended grapheme clusters (UAX #29, Unicode 18.0.0).

### `Model::cluster_width`

```mbti
pub fn Model::cluster_width(Self, String) -> Int32
```

The display width of one cluster that is not a tab or a line break. A flag,
an emoji ZWJ sequence and a cluster with U+FE0F are 2. Otherwise the base
character decides: 0 for controls, combining and format characters, default
ignorables and Hangul medial and final jamo; 2 for East Asian Wide and
Fullwidth, and for Ambiguous when the model says so; 1 otherwise.

### `Model::cluster`, `Model::text`

```mbti
pub fn Model::cluster(Self, String) -> Move
pub fn Model::text(Self, String) -> Move
```

`cluster` is the move of one cluster: `"\t"` is a tab, `"\n"`, `"\r"` and
`"\r\n"` are line breaks, anything else shifts by its width. `text` composes
the moves of all clusters of a string; it is a monoid homomorphism.

```moonbit
test "where a text ends" {
  let m = @cursor.Model::new()
  let end = m.apply(m.text("数独\tsudoku\n中"), { line: 0, col: 0 })
  assert_eq(end, { line: 1, col: 2 })
  assert_eq(m.text("数独\t"), m.compose(m.text("数独"), m.tab()))
}
```
