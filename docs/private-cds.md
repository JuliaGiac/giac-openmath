# Private Content Dictionaries and requests to GIAC

The table maps GIAC to the official OpenMath Content Dictionaries first. What
they lack comes in two kinds, which are kept apart:

| Kind | What it is | Where |
|---|---|---|
| Mathematics | functions, defined by formal properties (`sign`) | `giac_math1`, a private CD |
| Requests to GIAC | commands whose answer depends on GIAC's version and settings (simplify, expand, factor, solve, evalf, series, desolve) | `giac_procedures1`, a private CD, inside `scscp1.procedure_call` |

Both are files of this repository (`docs/cd/`), with their own base,
`https://juliagiac.github.io/giac-openmath/cd`. The table pins each by SHA-256,
like the official CDs, and gives the status each CD declares in its file.
`scscp1` is in OpenMath's Official directory but declares itself
`experimental`. What counts is the declared status, not the directory or the
base.

The rules below were agreed with the MathInterchange study. They follow its
ADR 0001: local agreements on existing formats, explicit scope, and refusal
outside it.

## Readers

- **By default, a reader uses only `official` CDs.** Experimental and private
  CDs are used only when the caller enables them. They are pinned by digest,
  with their exact base and name: two dictionaries with the same name and
  revision at another base, or with one changed byte, gave opposite answers
  in MathInterchange's experiments.
- **A reader whose output feeds claims or evidence** (MathInterfaceGiac.jl,
  proof checkers) keeps to the official CDs.
- **Applications** that drive GIAC (CAScad, Progressive Web Office) may enable
  `giac_math1`, `giac_procedures1` and `scscp1`.

## Requests

A request to GIAC is written as SCSCP writes a procedure call, even without
an SCSCP network:

```
scscp1.procedure_call(
  OMATTR(giac_procedures1.premises    → relation1.gt(x, 0),
         giac_procedures1.complex_mode → logic1.false,
         giac_procedures1.factor(x^4 - 1)))
```

- **Where procedure symbols may appear.** Only as the head of the argument of
  `scscp1.procedure_call`. A reader refuses them anywhere else, and always in
  a result: an unevaluated command is not an answer.
- **The arguments are mathematics**, in official symbols (or `giac_math1` if
  enabled).
- **Options are attributions on the argument** (`[[procedure_option]]`):
  - premises (GIAC's `assume`, for the call only);
  - complex mode;
  - `scscp1.option_runtime` (GIAC's time limit).

  They are part of the call, because they change GIAC's answers.
- **The answer is `scscp1.procedure_completed`**, holding the result in
  official symbols, with GIAC's messages as `scscp1.info_message`. A failure
  is `scscp1.procedure_terminated` with `scscp1.error_system_specific`.
- **The result carries the claim, with its relation to the request explicit:**
  - equal under the premises (simplify, expand, factor);
  - the solutions of (solve, desolve);
  - an approximation of (evalf), never an equality;
  - an expansion with its order term (series).
- **Assignment and definitions** change a session's state, so they are
  requests too. Applications compose them themselves. For instance,
  `a := <value>` uses the GIAC source of the value, and a function uses a
  lambda.

## The status of each CD

| CD | Status | Use |
|---|---|---|
| arith1, transc1, relation1, logic1, nums1, rounding1, minmax1, complex1, integer1, calculus1, limit1, set1, interval1, fns1 | official | default |
| scscp1 | experimental (declared) | the envelope of requests, when enabled |
| giac_math1 | private | when enabled |
| giac_procedures1 | private | requests, inside `scscp1.procedure_call`, when enabled |
