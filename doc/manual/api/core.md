# core API

<!-- API page: Purpose, Importing, then every public name in pkg.generated.mbti, grouped by purpose, and nothing else. Each item: a heading named after it in code, a first sentence saying what it does, the exact signature in an `mbti` block, its laws and edge behaviour, and a short example that compiles. -->

## Purpose

The root package of `KCN-judu/err_marker` turns a report (a severity, a
message and marks on places) and a sequence (command-line arguments, tokens or
a string) into a few lines of text: the line with the marks, a marker row,
messages and the header. Its public surface is recorded in
`src/pkg.generated.mbti`; the contract behind the columns is in the
[design](../design/core.md). The 0.1 API, `ErrorData::mark`, is deprecated and
listed at the end.

## Importing

Add the package to your `moon.pkg`:

```moonbit nocheck
import {
  "KCN-judu/err_marker",
}
```

The examples on this page call it as `@err_marker`.

## Sequences

### `Sequence`

The text that an error is marked in: an array of elements joined by a
separator, or a string.

```mbti
type Sequence[T]
```

The type is abstract; build values with `Sequence::from_array` or
`Sequence::from_string`. The type parameter is the element type, which must
implement `Show` when the sequence is rendered.

### `Sequence::from_array`

Builds a sequence from an array whose elements are rendered with `Show` and
joined by `join`.

```mbti
pub fn[T] Sequence::from_array(Array[T], join? : String) -> Self[T]
```

`join` defaults to a single space. Positions in this sequence are element
indices: position `i` covers the rendered text of element `i`. An element
that is empty, or contains whitespace, a double quote or the separator, is
wrapped in double quotes, with `\` and `"` escaped by a backslash, so the
rendered line can always be split back into its elements; marks then cover
the quoted token.

```moonbit
test "from_array joins elements with the separator" {
  let seq = @err_marker.Sequence::from_array([1, 22, 333], join=", ")
  let report = @err_marker.Report::new(Error, "too big")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::new(2, 3)))
  inspect(
    report.render(seq),
    content=(
      #|1, 22, 333
      #|       ^^^
      #|error: too big
    ),
  )
}
```

### `Sequence::from_string`

Builds a sequence from a string. Positions in this sequence are Unicode
scalar (character) indices; `utf16_to_scalar` converts a UTF-16 offset.

```moonbit
test "from_string marks characters" {
  let seq = @err_marker.Sequence::from_string("let x = 1 +")
  let report = @err_marker.Report::new(Error, "missing operand")
    .with_mark(@err_marker.Mark::primary(@err_marker.Span::point(11)))
  inspect(
    report.render(seq),
    content=(
      #|let x = 1 +
      #|           ^
      #|error: missing operand
    ),
  )
}
```

## Reports

The report API is new in 0.2.0 and replaces `ErrorData::mark`. Positions in a `Span` are element indices for an array
sequence and Unicode scalar indices for a string sequence.

### `Severity`

How serious a report is, ordered `Help < Note < Warning < Error`.

```mbti
pub(all) enum Severity {
  Help
  Note
  Warning
  Error
}
pub fn Severity::name(Self) -> String
```

`name` gives the lower-case word used in the header.

### `Style`

```mbti
pub(all) enum Style {
  Primary
  Secondary
}
```

A primary mark is drawn with `^`, a secondary mark with `-`.

### `Span`

A half-open interval `[start, end)` of positions, valid by construction.

```mbti
pub struct Span {
  start : Int32
  end : Int32
}
pub fn Span::new(Int32, Int32) -> Self
pub fn Span::point(Int32) -> Self
```

`new` turns a negative end point into 0 and an `end` before `start` into
`start`. `point(at)` is the insertion point `[at, at)`, drawn as one marker.

### `Mark`

A place to mark: a span, a style, an optional message and a priority.

```mbti
pub struct Mark {
  span : Span
  style : Style
  message : String?
  priority : Int32
}
pub fn Mark::primary(Span, message? : String) -> Self
pub fn Mark::secondary(Span, message? : String) -> Self
pub fn Mark::with_priority(Self, Int32) -> Self
```

Where marks overlap, each column goes to the higher priority, then the later
start, then the earlier end, then the primary mark, then the message that is
smaller in code-point order. The result does not depend on the order in which
marks are added, and marks equal in every field count once.

### `Report`

```mbti
pub struct Report {
  severity : Severity
  code : String?
  message : String
  marks : Array[Mark]
  notes : Array[String]
}
pub fn Report::new(Severity, String) -> Self
pub fn Report::with_code(Self, String) -> Self
pub fn Report::with_mark(Self, Mark) -> Self
pub fn Report::with_note(Self, String) -> Self
```

### `Report::render`

Renders the report on a sequence in the compact layout.

```mbti
pub fn[T : Show] Report::render(Self, Sequence[T], model? : @cursor.Model, color? : Bool) -> String
```

The output is, in order:

- the line of text that holds the primary mark (the whole text when there
  are no marks), with tabs expanded by `model`;
- the marker row, followed by the message of the mark that ends rightmost;
- the other messages, each under the start of its mark, on as few rows as
  possible;
- the header `severity[code]: message`, with ` at line:column` (1-based) when
  the text has several lines;
- one `note: ...` line per note.

Marks that start on another line than the primary mark are not drawn. Spans
are clamped to the sequence and snapped outward to grapheme clusters, and
columns follow Unicode 18.0.0 widths (`@cursor`). With `color`, ANSI SGR
colours are used.

```moonbit
test "render a report on command-line arguments" {
  let report = @err_marker.Report::new(Error, "unknown mode 'sovle'")
    .with_code("E01")
    .with_mark(
      @err_marker.Mark::primary(
        @err_marker.Span::new(3, 4),
        message="did you mean 'solve'?",
      ),
    )
  let args = @err_marker.Sequence::from_args([
    "sudoku", "export", "a.txt", "sovle", "out.txt",
  ])
  inspect(
    report.render(args),
    content=(
      #|sudoku export a.txt sovle out.txt
      #|                    ^^^^^ did you mean 'solve'?
      #|error[E01]: unknown mode 'sovle'
    ),
  )
}
```

### `Sequence::from_args`

```mbti
pub fn Sequence::from_args(Array[String]) -> Sequence[String]
```

A command-line argument vector as a sequence: arguments joined by a space and
quoted when needed.

### `utf16_to_scalar`

```mbti
pub fn utf16_to_scalar(String, Int32) -> Int32
```

The Unicode scalar index of a UTF-16 offset, for callers whose positions come
from `String` indexing. An offset inside a surrogate pair counts that pair as
not yet passed.

### `Sequence::rendered`, `Sequence::locate`

```mbti
pub fn[T : Show] Sequence::rendered(Self[T]) -> String
pub fn[T : Show] Sequence::locate(Self[T], Span) -> (Int32, Int32)
```

`rendered` is the text that `Report::render` draws for the sequence, with
elements quoted when needed. `locate` gives the scalar span in that text
where a span lands after the hull, clamping and snapping steps of `render`.
Together they let other renderers, such as the
[`error_report`](error_report.md) adapter, draw exactly the same places.

```moonbit
test "locate a span" {
  let args = @err_marker.Sequence::from_args(["cp", "a b", "c"])
  assert_eq(args.rendered(), "cp \"a b\" c")
  assert_eq(args.locate(@err_marker.Span::new(1, 2)), (3, 8))
}
```

## Deprecated

Kept for the 0.2.x releases for compatibility. The tutorial's "Migrating from
0.1" section shows the replacements.

### `ErrorData`

```mbti
pub struct ErrorData {
  err_type : String?
  err_msg : String
  err_pos : Int32
  err_offset : Int32
}
pub fn ErrorData::make(err_type? : String?, String, err_pos? : Int32, err_offset? : Int32) -> Self
```

The 0.1 description of an error. Replaced by `Report` and `Mark`.

### `ErrorData::mark`

```mbti
pub fn[T : Show] ErrorData::mark(Self, Sequence[T], marker? : Char, gen_msg? : (String?, String) -> String) -> String
```

Deprecated: use `Report::render`. It renders with the 0.2.0 engine, so
columns follow display widths, but keeps the 0.1 units: the span is `err_pos`
to `err_pos + err_offset`, both included; string positions are UTF-16 offsets
and every character the span touches is marked; a negative `err_pos` means no
position; a negative `err_offset` counts as 0. The last line is
`gen_msg(err_type, err_msg)`, by default `Error(type): message`, and `marker`
replaces `^`.

