# core tutorial

This tutorial builds the error reporting of a small command-line program, one
step at a time. You need a MoonBit toolchain (`moonc` ≥ 0.10) and a module of
your own to add the dependency to.

## 1. Add the dependency

```bash
moon add KCN-judu/err_marker@0.1.4
```

and import the package in the `moon.pkg` of the package that reports errors:

```moonbit nocheck
import {
  "KCN-judu/err_marker",
}
```

## 2. Mark one argument

A program receives its arguments as an array of strings. Wrap the array in a
`Sequence`, describe the error with `ErrorData::make`, and call `mark`.
`err_pos` is the index of the bad argument:

```moonbit
test "mark the unknown command" {
  let argv = ["sudoku", "sovle", "a.txt"]
  let e = @err_marker.ErrorData::make(
    "unknown command 'sovle'",
    err_type=Some("ArgError"),
    err_pos=1,
  )
  inspect(
    e.mark(@err_marker.Sequence::from_array(argv)),
    content=(
      #|sudoku sovle a.txt
      #|       ^^^^^
      #|Error(ArgError): unknown command 'sovle'
    ),
  )
}
```

`mark` returns a `String`; print it with `println` in a real program.

## 3. Mark several arguments

`err_offset` extends the span to the following elements. With `err_pos=1` and
`err_offset=1`, the marker covers elements 1 and 2 and the space between them:

```moonbit
test "mark two arguments" {
  let argv = ["sudoku", "export", "a.txt"]
  let e = @err_marker.ErrorData::make(
    "export needs an output path",
    err_pos=1,
    err_offset=1,
  )
  inspect(
    e.mark(@err_marker.Sequence::from_array(argv)),
    content=(
      #|sudoku export a.txt
      #|       ^^^^^^^^^^^^
      #|Error: export needs an output path
    ),
  )
}
```

## 4. Mark a place in a string

For a single string, use `Sequence::from_string`; positions are offsets into
the string:

```moonbit
test "mark a column in a puzzle line" {
  let line = "53..7....6..195..."
  let e = @err_marker.ErrorData::make("expected a digit or 0", err_pos=2)
  inspect(
    e.mark(@err_marker.Sequence::from_string(line)),
    content=(
      #|53..7....6..195...
      #|  ^
      #|Error: expected a digit or 0
    ),
  )
}
```

## 5. Use your own error format

`gen_msg` receives the error type and message and returns the last line;
`marker` changes the marker character:

```moonbit
test "custom format" {
  let fmt = fn(t : String?, m : String) -> String {
    match t {
      Some(t) => "[\{t}] \{m}"
      None => m
    }
  }
  let e = @err_marker.ErrorData::make(
    "not a number",
    err_type=Some("E01"),
    err_pos=1,
  )
  inspect(
    e.mark(@err_marker.Sequence::from_array(["x", "ten"]), marker='-', gen_msg=fmt),
    content=(
      #|x ten
      #|  ---
      #|[E01] not a number
    ),
  )
}
```

## 6. Know the limits

In 0.1 the marker column is counted in UTF-16 code units. It is right for
ASCII text: tabs are copied into the marker line so they do not shift it, and
in text with several lines the marker goes under the line that holds the
span. With Chinese or Japanese text or emoji it drifts.
The [design](../design/core.md) explains why, and 0.2.0
fixes these cases
([#5](https://github.com/moonbit-community/err_marker/issues/5)).

## Next

Read the [API](../api/core.md) for every parameter and edge case.
