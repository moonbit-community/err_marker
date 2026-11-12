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
which equal character indices only for text in the Basic Multilingual Plane
([#7](https://github.com/moonbit-community/err_marker/issues/7)).

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
