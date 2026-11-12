# Contribution guidelines

err_marker lives in moonbit-community but follows the Luna-Flow engineering
standards. The organisation-wide guide is published at
<https://lunaflow.cn/en/contribute/>.

## Toolchain

- MoonBit `moonc` 0.10 or later. Manifests use the `moon.mod` and `moon.pkg`
  syntax; do not add `moon.mod.json` or `moon.pkg.json` (`moon fmt` migrates
  old ones).
- [`just`](https://github.com/casey/just) for the local workflows in the
  `justfile`.
- Node.js and a clone of
  [Luna-Flow.github.io](https://github.com/Luna-Flow/Luna-Flow.github.io) for
  `lunadoc`, and [Typst](https://typst.app/) if the manual has attachments.

## Code style

- Format all MoonBit code with `just fmt`.
- Organise files by package boundary first, then by behaviour. Name files after
  what they do (`gauss_kronrod.mbt`), not `utils.mbt`.
- Separate top-level items with `///|`.
- Keep comments short and technical: contracts, invariants and non-obvious
  implementation choices.
- Use `derive(Debug)` for structural output. Implement `Show` only for types
  with a real text format.
- Keep deprecated items in the package's `deprecated.mbt`.

### Explicit method promotion

An `impl Trait for T` no longer turns the trait's methods into methods of `T`.
State every promotion you want in the package's `extends.mbt`:

```moonbit nocheck
///|
pub extend Vec2 with Eq::{equal}

///|
pub extend Vec2 with Add::{add}
```

Promote operators (`add`, `sub`, `mul`, `div`, `neg`, ...), `compare`, `equal`
and `hash`. Promote `to_string` only for types with a canonical text form. When
an existing promotion must stay for compatibility but should not be used, keep
it as a deprecated, hidden `pub extend`:

```moonbit nocheck
///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Vec2 with Eq::{not_equal}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend Vec2 with @debug.Debug::{to_repr}
```

The second form needs `"moonbitlang/core/debug"` in the package's `moon.pkg`
imports.

## Naming conventions

- Bindings and functions: lowercase with underscores, such as `scaled_value`.
- Types and traits: PascalCase, such as `Solver`. A trait name describes a
  capability, not an implementation.
- Files and directories: lowercase with underscores.
- Errors are structured values returned in `Result`, such as
  `pub struct SolverError { kind : SolverErrorKind, message : String }`. Use
  `abort("Type::fn: reason")` only for violated programmer contracts.

## Testing

- Add or update tests whenever behaviour changes.
- Put blackbox tests in `*_test.mbt` and whitebox tests in `*_wbtest.mbt`, next
  to the code they test.
- In blackbox tests, qualify every name from the package under test:
  `@err_marker.ErrorData::make("msg")`, `@pkg.Vec2::{ x: 1.0, y: 2.0 }`. Unqualified names
  trigger the `test_unqualified_package` warning. Method calls on values
  (`v.norm()`) and enum constructors need no prefix.
- Declare test-only fixture types as `priv`, so they do not become public API
  and need no promotion declarations.
- Prefer `assert_eq` for well-defined results and `inspect` / `debug_inspect`
  snapshots for rendered output; refresh snapshots with `moon test --update`.
- Run `just test` while working and `just ready` before opening a pull
  request. Run `just check-all` and `just test-all` when the change touches
  target-specific code; `moon check --target all` must report no warnings.

## Interface files

`pkg.generated.mbti` in each package is the authoritative record of the public
API, and it is committed. Regenerate it with `just info` (part of `just ready`)
and review its diff: a change there is a change to the public API, and belongs
in the same commit as the source change that caused it.

## Documentation

The manual follows the
[Luna-Flow documentation standard](https://lunaflow.cn/en/contribute/documentation_standard/).
The pages in `doc/manual` model it; keep their structure when you replace their
content.

### Layout

```text
doc/
├── conf.json                 title, one-sentence summary, locales
├── manual/                   English source pages (the only source)
│   ├── index.md              overview, package map, reading paths
│   ├── <guide>.md            optional guides (getting_started, architecture, ...)
│   ├── api/<package>.md      one page per package in each chapter
│   ├── tutorial/<package>.md
│   └── design/<package>.md
├── attachments/              Typst sources and images shared by all locales
└── locale/
    ├── manual.pot            generated, never edited
    ├── zh_CN/LC_MESSAGES/manual.po
    └── ja_JP/LC_MESSAGES/manual.po
```

A page is named after the package path under the source root: `src/backend/tui`
is documented in `api/backend/tui.md`, `tutorial/backend/tui.md` and
`design/backend/tui.md`. The package at the source root itself is documented as
`core`. Every documented package has a page in all three chapters.

### The three page kinds

- **API** (`api/`): every public name in `pkg.generated.mbti`, grouped by
  purpose, and nothing that is not in it. Each item gets a heading named after
  it in code (``### `Type::method` ``), a first sentence that says what it does,
  the exact signature in an `mbti` block, its semantics (arguments, result,
  preconditions, errors and aborts, complexity, laws in TeX), and a short
  example that compiles. Deprecated items go last under `## Deprecated`, each
  with its replacement.
- **Tutorial** (`tutorial/`): the goal in the first paragraph, then
  `## Quick start` (install line, `moon.pkg` import, a program of at most 15
  lines and its output), `## Everyday tasks` (three to six complete examples
  with output), `## Going further`, `## Common pitfalls`, and `## Next steps`
  with links to the API and design pages.
- **Design** (`design/`): `## Design goal`, `## Mathematical background`
  (definitions in TeX), `## Design decisions` (for each: the problem, the
  options, the choice and why, with derivations), `## Correctness / invariants`,
  `## Alternatives rejected`, and `## Boundaries` last: what the package
  deliberately does not do. Describe only what the code implements.

Write mathematics in TeX (`$...$` inline, `$$...$$` display). Put long proofs
in a Typst document `doc/attachments/<page-path>_<topic>.typ`, linked on a line
of its own, as `design/core.md` does.

### Code blocks

Fence MoonBit that compiles as `moonbit`, interface excerpts as `mbti`,
manifests, shell commands and program output as `text`, and intentionally
partial MoonBit as `moonbit nocheck`. Check every `moonbit` block by compiling
it in a scratch package that depends on this module through a `moon.work`
outside the repository.

### Translations and checks

English pages are the only source; Chinese and Japanese live in the gettext
catalogs under `doc/locale`. With the site repository cloned next to this one:

```text
node ../Luna-Flow.github.io/tools/lunadoc/cli.mjs update .           # after editing English pages
node ../Luna-Flow.github.io/tools/lunadoc/cli.mjs status --pages .   # translation coverage
node ../Luna-Flow.github.io/tools/lunadoc/cli.mjs check --compile .  # what CI runs
```

`update` regenerates `manual.pot` and merges it into every `manual.po`. Changed
English text keeps a `fuzzy` copy of the old translation; review it, fix it and
remove the flag. Keep inline code, mathematics and link targets unchanged in
translations. Commit the pages and the refreshed catalogs together. The `Docs`
workflow (`.github/workflows/docs.yml`) runs the same check on every pull
request that touches `doc/`.

## Dependencies

- Update dependencies with `just update-deps` and review the `moon.mod` diff.
- Do not change dependency or version declarations in unrelated pull requests.

## Commits

Follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):
`<type>(<scope>): <subject>`.

- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `build`, `ci`,
  `perf`, `style`.
- The scope is the package or area touched, such as `core` or `l10n`.
- The subject is imperative, in English, and at most 72 characters; details go
  in the body.
- Mark breaking changes with `!` after the type or scope, or with a
  `BREAKING CHANGE:` footer.
- Keep each commit to one logical change, for example
  `refactor(core): promote trait methods explicitly`,
  `docs(core): rewrite API, tutorial and design pages`,
  `docs(l10n): translate the manual into Chinese and Japanese`.

## Release checklist

- Update `version` in `moon.mod`.
- Make sure the README, the CHANGELOG and the manual describe the release.
- Run `just ready`.
- Run `just test-all` (wasm, wasm-gc, js and native; debug and release).
- The maintainer publishes from a clean checkout of the merged release commit:
  `moon publish --dry-run`, then `moon publish`, then tags `vX.Y.Z` and creates
  the GitHub release. There is no publishing workflow.
