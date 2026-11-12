# core API

<!-- API page: Purpose, Importing, then every public name in pkg.generated.mbti, grouped by purpose, and nothing else. Each item: a heading named after it in code, a first sentence saying what it does, the exact signature in an `mbti` block, its laws and edge behaviour, and a short example that compiles. -->

## Purpose

The root package of `KCN-judu/err_marker` turns a sequence, a position and a
message into a three-line error report: the rendered sequence, a marker line
under the position, and the message. Its public surface is recorded in
`src/pkg.generated.mbti`; how the marker column is computed, and where that
computation is wrong in 0.1, is explained in the [design](../design/core.md).

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
implement `Show` when the sequence is rendered by `ErrorData::mark`.

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
rendered line can always be split back into its elements; the marker then
covers the quoted token ([#11](https://github.com/moonbit-community/err_marker/issues/11)).

```moonbit
test "from_array joins elements with the separator" {
  let seq = @err_marker.Sequence::from_array([1, 22, 333], join=", ")
  let e = @err_marker.ErrorData::make("too big", err_pos=2)
  inspect(
    e.mark(seq),
    content=(
      #|1, 22, 333
      #|       ^^^
      #|Error: too big
    ),
  )
}
```

### `Sequence::from_string`

Builds a sequence from a string.

```mbti
pub fn Sequence::from_string(String) -> Self[Char]
```

Positions in this sequence are UTF-16 code-unit offsets into the string,
which equal character indices only for text in the Basic Multilingual Plane.
A span whose start or end falls inside a surrogate pair is widened to the
whole character, so a character outside that plane, such as most emoji, is
never split ([#7](https://github.com/moonbit-community/err_marker/issues/7)). From 0.2.0, positions are Unicode scalar indices.

```moonbit
test "from_string marks code units" {
  let seq = @err_marker.Sequence::from_string("let x = 1 +")
  let e = @err_marker.ErrorData::make("missing operand", err_pos=10)
  inspect(
    e.mark(seq),
    content=(
      #|let x = 1 +
      #|          ^
      #|Error: missing operand
    ),
  )
}
```

## Error data

### `ErrorData`

What went wrong and where: an optional error type, a message, a start
position and an offset.

```mbti
pub struct ErrorData {
  err_type : String?
  err_msg : String
  err_pos : Int32
  err_offset : Int32
}
```

The marked span is `err_pos` through `err_pos + err_offset`, both ends
included, in the units of the sequence it is marked in. The fields are
readable from outside the package; build values with `ErrorData::make`.

### `ErrorData::make`

Builds an `ErrorData` from a message and optional type, position and offset.

```mbti
pub fn ErrorData::make(err_type? : String?, String, err_pos? : Int32, err_offset? : Int32) -> Self
```

The defaults are `err_type = None`, `err_pos = -1` and `err_offset = 0`. A
negative `err_pos` means "no position": `mark` then prints an empty marker
line. `make` never fails; positions are only checked when the error is
marked.

```moonbit
test "make fills in the defaults" {
  let e = @err_marker.ErrorData::make("no input")
  assert_eq(e.err_type, None)
  assert_eq(e.err_msg, "no input")
  assert_eq(e.err_pos, -1)
  assert_eq(e.err_offset, 0)
}
```

## Rendering

### `ErrorData::mark`

Renders the sequence, a marker line under the span, and the formatted
message, separated by newlines.

```mbti
pub fn[T : Show] ErrorData::mark(Self, Sequence[T], marker? : Char, gen_msg? : (String?, String) -> String) -> String
```

- `marker` is the character repeated under the span; it defaults to `^`.
- `gen_msg` formats the last line from `err_type` and `err_msg`. The default
  prints `Error(type): message`, or `Error: message` when `err_type` is
  `None`.
- If `err_pos` is negative, the marker line is empty. A negative
  `err_offset` counts as 0. A span that runs past the end is clamped to the
  last element or character. A start at or past the end marks the point just
  after the text with one marker character, which is how a missing argument
  is shown ([#10](https://github.com/moonbit-community/err_marker/issues/10)).
- The marker column counts UTF-16 code units, not terminal columns, so it
  is only correct for ASCII-width text ([#6](https://github.com/moonbit-community/err_marker/issues/6)).
- If the text has several lines, the marker line goes right under the line
  that holds the start of the span, with its column counted from the start of
  that line, and the remaining lines follow it. A span that crosses a line
  break is marked up to the end of its first line ([#9](https://github.com/moonbit-community/err_marker/issues/9)).
- Tabs before the span are copied into the marker line, so the marker lines
  up whatever tab width the terminal uses; a tab inside the span still gets a
  single marker character ([#8](https://github.com/moonbit-community/err_marker/issues/8)).

```moonbit
test "mark with a custom marker and formatter" {
  let args = @err_marker.Sequence::from_array(["solve", "x.txt"])
  let e = @err_marker.ErrorData::make(
    "file not found",
    err_type=Some("IOError"),
    err_pos=1,
  )
  let out = e.mark(args, marker='~', gen_msg=(t, m) => match t {
    Some(t) => "\{t}: \{m}"
    None => m
  })
  inspect(
    out,
    content=(
      #|solve x.txt
      #|      ~~~~~
      #|IOError: file not found
    ),
  )
}
```

## Reports

The report API is new in 0.2.0. It replaces `ErrorData::mark`, which stays
for one release. Positions in a `Span` are element indices for an array
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
