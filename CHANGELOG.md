# Changelog

All notable changes to `KCN-judu/err_marker` are recorded here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
module follows [semantic versioning](https://semver.org/spec/v2.0.0.html); in
0.x, a breaking change bumps the minor version. Each entry links its issue or
pull request. Breaking changes are marked **Breaking**.

The roadmap to 0.2.0 is tracked in
[#5](https://github.com/moonbit-community/err_marker/issues/5).

## [Unreleased]

### Fixed

- A tab before the marked span no longer shifts the marker: the marker line
  copies tabs from the text above instead of replacing them with one space,
  so the marker lines up whatever tab width the terminal uses
  ([#8](https://github.com/moonbit-community/err_marker/issues/8)).

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
