# Changelog

All notable changes to `KCN-judu/err_marker` are recorded here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
module follows [semantic versioning](https://semver.org/spec/v2.0.0.html); in
0.x, a breaking change bumps the minor version. Each entry links its issue or
pull request. Breaking changes are marked **Breaking**.

The roadmap to 0.2.0 is tracked in
[#5](https://github.com/moonbit-community/err_marker/issues/5).

## [Unreleased]

## [0.2.0] — 2026-11-12

The report API replaces `ErrorData::mark`, which is deprecated and kept for
the 0.2.x releases; columns follow Unicode 18.0.0 display widths. See
"Migrating from 0.1" in the tutorial.

### Changed

- **Breaking:** `ErrorData::mark` now renders with the 0.2.0 engine. Columns
  follow display widths, so CJK text and emoji line up
  ([#6](https://github.com/moonbit-community/err_marker/issues/6)); tabs are
  expanded instead of copied; for text with several lines only the marked line
  is shown. Its units are unchanged (UTF-16 offsets for strings, inclusive
  `err_offset`), as are `marker` and `gen_msg`
  ([#31](https://github.com/moonbit-community/err_marker/issues/31)).
- The manual now teaches the report API and has a "Migrating from 0.1"
  section; the README shows 0.2.0 usage.

### Deprecated

- `ErrorData::mark`: use `Report::render`. It stays for the 0.2.x releases
  ([#31](https://github.com/moonbit-community/err_marker/issues/31)).

### Added

- New package `KCN-judu/err_marker/error_report` with `to_error_report`,
  which converts a report into a `marianoguerra/error-report` report (marks
  land on exactly the same characters), and `Sequence::rendered` /
  `Sequence::locate`, which expose where `render` draws a span. The module now
  depends on `marianoguerra/error-report@0.1.1`, used only by the adapter
  ([#30](https://github.com/moonbit-community/err_marker/issues/30)).
- Report API (the 0.2.0 replacement for `ErrorData::mark`): `Severity`,
  `Style`, `Span`, `Mark`, `Report` with builders, and `Report::render` in the
  compact layout. Several marks per sequence overlay as a semilattice
  (priority, later start, earlier end, primary, message), messages are placed
  after the rightmost marker and on as few rows as possible below, spans are
  clamped and snapped to grapheme clusters, columns follow Unicode 18.0.0
  widths, multi-line text shows the primary line with `line:col`, and ANSI
  colour is optional. Also `Sequence::from_args` and `utf16_to_scalar`
  ([#33](https://github.com/moonbit-community/err_marker/issues/33)).
- New public package `KCN-judu/err_marker/cursor`: terminal layout of text
  as a monoid of cursor moves (`Shift`, `Tab`, `Break` normal forms) under a
  `Model` (tab width, ambiguous width), grapheme clusters (`clusters`, UAX #29)
  and cluster widths (`Model::cluster_width`, UAX #11), all from Unicode
  18.0.0 tables generated from the UCD. The renderer will use it in 0.2.0
  ([#32](https://github.com/moonbit-community/err_marker/issues/32),
  [#28](https://github.com/moonbit-community/err_marker/issues/28),
  [#29](https://github.com/moonbit-community/err_marker/issues/29)).

## [0.1.4] — 2026-11-12

Bug-fix release. No public API change; rendered output changes only in the
cases listed below.

### Fixed

- A tab before the marked span no longer shifts the marker: the marker line
  copies tabs from the text above instead of replacing them with one space,
  so the marker lines up whatever tab width the terminal uses
  ([#8](https://github.com/moonbit-community/err_marker/issues/8)).
- Out-of-range spans follow one rule for arrays and strings: a span that
  runs past the end is clamped to the last element or character (arrays used
  to draw markers past the text, strings drew none); a start at or past the
  end marks the point after the text with one marker; a negative
  `err_offset` counts as 0; a huge `err_offset` no longer overflows. The doc
  comment of `err_locate_arr` no longer claims that it panics
  ([#10](https://github.com/moonbit-community/err_marker/issues/10)).
- Text with several lines: the marker line now goes right under the line that
  holds the start of the span, with its column counted from the start of that
  line, and the remaining lines follow it. It used to be printed after the
  last line with the column counted from the start of the whole text. A span
  that crosses a line break is marked up to the end of its first line
  ([#9](https://github.com/moonbit-community/err_marker/issues/9)).
- `Sequence::from_array` quotes an element that is empty or contains
  whitespace, a double quote or the separator (`\` and `"` are escaped inside
  the quotes), so the rendered line can be split back into its elements and
  an empty element can be marked. The marker covers the quoted token. Output
  for other elements is unchanged
  ([#11](https://github.com/moonbit-community/err_marker/issues/11)).
- A string span whose start or end falls inside a surrogate pair is widened
  to the whole character, so an emoji or another character outside the Basic
  Multilingual Plane is never split by the marker. The manual now states that
  string positions are UTF-16 code units
  ([#7](https://github.com/moonbit-community/err_marker/issues/7)).

## [0.1.3] — 2026-11-12

Toolchain compatibility release. No change in rendered output.

### Changed

- Manifests migrated from `moon.mod.json` / `moon.pkg.json` to `moon.mod` /
  `moon.pkg`. Current MoonBit toolchains refuse the old format, including in
  dependencies, so 0.1.2 cannot be installed with them
  ([#3](https://github.com/moonbit-community/err_marker/pull/3)).
- `Sequence::from_array` no longer requires `T : Show`; the bound is only
  needed by `ErrorData::mark`
  ([#1](https://github.com/moonbit-community/err_marker/pull/1)).
- The repository moved to
  [moonbit-community/err_marker](https://github.com/moonbit-community/err_marker);
  the module name `KCN-judu/err_marker` is unchanged.

## [0.1.2] — 2025-07-19

### Changed

- Source updated to the MoonBit beta syntax.

## [0.1.1] — 2025-06-30

### Fixed

- Documentation fixes.

## [0.1.0] — 2025-06-28

First release (preceded by 0.1.0-beta-1 on the same day).

### Added

- `ErrorData`: an optional error type, a message, a position (`err_pos`) and
  an offset (`err_offset`), built with `ErrorData::make`.
- `Sequence::from_array` (elements joined by a separator, default `" "`) and
  `Sequence::from_string`.
- `ErrorData::mark`: renders the sequence, a marker line under the span
  `err_pos ..= err_pos + err_offset`, and the message, with a custom marker
  character (`marker~`) and message formatter (`gen_msg~`).
