set shell := ["sh", "-eu", "-c"]

default:
    just --list

fmt:
    moon fmt

update-deps:
    moon update
    awk ' \
      $1 == "import" && $2 == "{" { in_import = 1; next } \
      in_import && $1 == "}" { in_import = 0; next } \
      in_import { \
        gsub(/[",]/, "", $1); \
        sub(/@.*/, "", $1); \
        if ($1 != "") print $1; \
      } \
    ' moon.mod | while IFS= read -r dep; do \
      moon add --upgrade --no-update "$dep"; \
    done
    moon build

build:
    moon build

check:
    moon check

check-all:
    moon check --target all

test:
    moon test

test-all:
    for target in wasm wasm-gc js native; do moon test --target "$target"; moon test --target "$target" --release; done

test-coverage:
    moon clean
    moon coverage clean
    moon test --enable-coverage
    if moon coverage report -f summary > coverage_summary.txt 2>/dev/null; then \
      moon coverage report -f html 2>/dev/null; \
    else \
      printf '%s\n' "coverage report generation failed with the current MoonBit toolchain" > coverage_summary.txt; \
      printf '%s\n' "warning: moon coverage report failed; tests still passed" >&2; \
    fi

info:
    moon info

tree:
    moon tree

ready:
    moon fmt
    moon check --target all
    moon info
    moon clean
    moon coverage clean
    moon test --enable-coverage
    if moon coverage report -f summary > coverage_summary.txt 2>/dev/null; then \
      moon coverage report -f html 2>/dev/null; \
    else \
      printf '%s\n' "coverage report generation failed with the current MoonBit toolchain" > coverage_summary.txt; \
      printf '%s\n' "warning: moon coverage report failed; tests still passed" >&2; \
    fi

publish-dry-run:
    moon publish --dry-run
