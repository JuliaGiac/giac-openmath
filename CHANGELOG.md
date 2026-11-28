# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The table's `format` number changes only with an incompatible change of its
structure.

## [Unreleased]

### Added
- `test/fixtures/openmath-to-giac.json`: 48 cases of OpenMath (OpenMath 2.0 JSON
  encoding) read into GIAC, for every reader and producer to test against.
  Each accepted case gives a GIAC source and the value GIAC must give; each
  refused case gives the JSON path of the refused node, its symbol or kind,
  and a substring of the reason. The format is in `docs/fixtures.md`. The
  tests check the corpus against the table (`just test`) and its values in
  GIAC (`just test-giac`).
- `giac-openmath.toml`, format 1: GIAC's expression-tree nodes (GIAC 2.0.0)
  and the OpenMath symbols they mean, in both directions, for arith1,
  transc1, relation1, logic1, nums1, rounding1, minmax1, complex1, integer1,
  calculus1 and limit1 (with set1, interval1 and fns1), pinned at
  OpenMath/CDs commit cbf6075 and checked by SHA-256. Patterns keep every
  argument, and bind variables where OpenMath works on functions
  (integrals, derivatives, limits, sums).
- Refused entries with their reasons: GIAC's `%` (a residue class), `irem`
  and `iquo` (other sign conventions than integer1), `=>` (an assignment),
  unsigned `infinity`, `undef`, and functions (`program`).
- `giac-openmath.json`, the same data as JSON with sorted keys.
- `docs/format.md`, the format.
- Tests of the table alone (`just test`) and against GIAC through Giac.jl
  (`just test-giac`), and CI running both.
