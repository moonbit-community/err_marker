# core tutorial

This tutorial builds the error reporting of a small command-line program, one
step at a time. You need a MoonBit toolchain (`moonc` ≥ 0.10) and a module of
your own to add the dependency to.

## 1. Add the dependency

```bash
moon add KCN-judu/err_marker@0.2.0
```

and import the package in the `moon.pkg` of the package that reports errors:

```moonbit nocheck
import {
  "KCN-judu/err_marker",
}
```

## 2. Mark one argument

A program receives its arguments as an array of strings. Turn it into a
sequence with `Sequence::from_args`, describe the error with a `Report`, mark
the bad argument with a `Span` of element indices, and call `render`:

```moonbit
test "mark the unknown command" {
  let argv = ["sudoku", "sovle", "a.txt"]
  let report = @err_marker.Report::new(Error, "unknown command 'sovle'")
    .with_code("ArgError")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(1, 2)))
  inspect(
    report.render(@err_marker.Sequence::from_args(argv)),
    content=(
      #|sudoku sovle a.txt
      #|       ^^^^^
      #|error[ArgError]: unknown command 'sovle'
    ),
  )
}
```

`render` returns a `String`; print it with `println` in a real program.

## 3. Mark several arguments, or a missing one

A span `[start, end)` covers elements `start` to `end - 1` and the spaces
between them. `Span::point` marks the place right after an element, which is
how a missing argument is shown; a message can say what is expected:

```moonbit
test "mark two arguments and a missing one" {
  let argv = ["sudoku", "export", "a.txt"]
  let report = @err_marker.Report::new(Error, "export needs an output path")
    .with_mark(@err_marker.Mark::secondary(@err_marker.Span::new(1, 3)))
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::point(3), message="here"))
  inspect(
    report.render(@err_marker.Sequence::from_args(argv)),
    content=(
      #|sudoku export a.txt
      #|       ------------^ here
      #|error: export needs an output path
    ),
  )
}
```

## 4. Mark a place in a string

For a single string, use `Sequence::from_string`. Positions are character
(Unicode scalar) indices, and columns follow the display width, so Chinese,
Japanese and emoji line up:

```moonbit
test "mark a cell in a puzzle line" {
  let line = "数独: 53..7"
  let report = @err_marker.Report::new(Error, "expected a digit or 0")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(6, 7)))
  inspect(
    report.render(@err_marker.Sequence::from_string(line)),
    content=(
      #|数独: 53..7
      #|        ^
      #|error: expected a digit or 0
    ),
  )
}
```

## 5. Several marks and notes

A primary mark (`^`) shows the place that is wrong, secondary marks (`-`)
related places; each may carry a message. Notes go after the header:

```moonbit
test "a report with two marks and a note" {
  let report = @err_marker.Report::new(Warning, "duplicate cell")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(4, 5), message="again here"))
    .with_mark(@err_marker.Mark::secondary(@err_marker.Span::new(1, 2), message="first"))
    .with_note("each digit appears once per row")
  inspect(
    report.render(@err_marker.Sequence::from_string("数5独.5")),
    content=(
      #|数5独.5
      #|  -   ^ again here
      #|  first
      #|warning: duplicate cell
      #|note: each digit appears once per row
    ),
  )
}
```

## 6. Tabs and colour

Tabs are expanded with the tab width of a `@cursor.Model` (8 by default), and
`color=true` adds ANSI colours for terminals:

```moonbit
test "tab width" {
  let report = @err_marker.Report::new(Error, "bad")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(1, 2)))
  inspect(
    report.render(
      @err_marker.Sequence::from_string("\tx"),
      model=@cursor.Model::new(tab_width=4),
    ),
    content=(
      #|    x
      #|    ^
      #|error: bad
    ),
  )
}
```

## 7. Migrating from 0.1

`ErrorData::mark` still works in 0.2.x but is deprecated. Replace

- `ErrorData::make(msg, err_type=Some(t), err_pos=p, err_offset=k)` with
  `Report::new(Error, msg).with_code(t)` and
  `Mark::primary(Span::new(p, p + k + 1))`: spans are half-open now;
- string positions, which were UTF-16 offsets, with character indices;
  `utf16_to_scalar` converts an offset you already have;
- `err_pos = -1` (no position) with a report without marks;
- `gen_msg`, which formatted the last line, with `Report`'s fields: the header
  is `severity[code]: message`;
- `marker`, which changed the marker character, with the two built-in styles
  `^` and `-`.

The output also changes: tabs are expanded instead of copied, and for text
with several lines only the line of the primary mark is shown, with its
`line:col` in the header. `ErrorData::mark` already renders this way in 0.2.x.

## Next

Read the [API](../api/core.md) for every parameter and edge case, and the
[design](../design/core.md) for the contract behind the columns.
