# cursor tutorial

This tutorial measures text the way a terminal lays it out. Import the
package as in the [API](../api/cursor.md).

## 1. Make a model

A `Model` fixes the tab width and how wide East Asian Ambiguous characters
are. The defaults are tab width 8 and narrow:

```moonbit
test "a default model" {
  let m = @cursor.Model::new()
  assert_eq(m.tab_width, 8)
  assert_eq(m.ambiguous_wide, false)
}
```

## 2. Measure a cluster

Characters a reader sees as one unit, such as `e` with an accent or a family
emoji, are one grapheme cluster. `cluster_width` gives its columns:

```moonbit
test "cluster widths" {
  let m = @cursor.Model::new()
  assert_eq(m.cluster_width("a"), 1)
  assert_eq(m.cluster_width("中"), 2)
  assert_eq(m.cluster_width("e\u{301}"), 1)
  assert_eq(m.cluster_width("\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}"), 2)
}
```

## 3. Find where a text ends

`text` turns a whole string into a move; `apply` runs it from a position.
Tabs go to the next tab stop, line breaks to column 0 of the next line:

```moonbit
test "where the cursor ends" {
  let m = @cursor.Model::new()
  assert_eq(m.apply(m.text("ab\tc"), { line: 0, col: 0 }), { line: 0, col: 9 })
  assert_eq(m.apply(m.text("x\r\n数"), { line: 2, col: 5 }), { line: 3, col: 2 })
}
```

## 4. Put a marker under part of a line

The column of the marker is where the text before the span ends:

```moonbit
test "marker column" {
  let m = @cursor.Model::new()
  let before = "数独 求解 "
  assert_eq(m.apply(m.text(before), { line: 0, col: 0 }).col, 10)
}
```

## 5. Combine moves

Moves compose, so the move of a long text can be built from its parts:

```moonbit
test "compose moves" {
  let m = @cursor.Model::new(tab_width=4)
  let whole = m.text("中\tx")
  let parts = m.compose(m.compose(m.text("中"), m.tab()), m.text("x"))
  assert_eq(whole, parts)
}
```

## Next

The [design](../design/cursor.md) explains why every move has one of three
forms.
