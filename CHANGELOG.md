# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
The table's `format` number changes only with an incompatible change of its
structure.

## [Unreleased]

### Changed
- The corpus is written for the format 2 table (`table_commit` at the merge
  of the private CDs); its cases are unchanged.
- **Format 2** (format 1 readers keep working on the official part, but should
  move): each CD gives the `status` its file declares (`scscp1`, in
  OpenMath's Official directory, declares `experimental`).

### Added
- **Private CDs of JuliaGiac**, in `docs/cd/`, with their own base
  `https://juliagiac.github.io/giac-openmath/cd`, pinned by SHA-256:
  `giac_math1` (`sign`, defined by formal properties) and `giac_procedures1`
  (requests to GIAC: simplify, expand, factor, solve, evalf, series,
  desolve, each with the relation a result is checked against: defined and
  equal wherever the request's expression is defined; no field stated for
  factor; series results may hold negative or fractional powers; options
  premises and complex_mode, as semantic attributions).
- **Requests to GIAC** (`[[procedure]]`, `[envelope]`,
  `[[procedure_option]]`): written in an `scscp1.procedure_call`, answered by
  `procedure_completed` or `procedure_terminated`; procedure symbols (the CDs
  in `envelope.procedure_cds`) are refused anywhere else and in results.
  Assignment is a request, `prog1.assignment` (experimental). The rules are
  in `docs/private-cds.md`.
- `quant1`, `setname1` (official) and `prog1` (experimental) pinned.
- `sign` ↔ `giac_math1.sign`.
- `test/fixtures/openmath-to-giac.json`: 59 cases of OpenMath (OpenMath 2.0 JSON
  encoding) read into GIAC, for every reader and producer to test against.
  Each accepted case gives a GIAC source and the value GIAC must give; each
  refused case gives the JSON path of the refused node, its symbol or kind,
  and a substring of the reason. The format is in `docs/fixtures.md`. The
  tests check the corpus against the table (`just test`) and its values in
  GIAC (`just test-giac`).
- The corpus's format 2 rules, with 7 cases: only official CDs unless the
  caller enables others (`options.enable`); each symbol at its CD's base,
  inherited from the enclosing object; procedure symbols only inside
  `scscp1.procedure_call`. The tests check that the cases follow them.
- The corpus's rule for bound variables named as GIAC constants: a reader
  renames them to a fresh name (`i` bound in a sum becomes `i_1`), and still
  refuses free ones; 4 cases.
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
