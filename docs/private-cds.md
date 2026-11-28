# Private Content Dictionaries and requests to GIAC

The table maps GIAC to the official OpenMath Content Dictionaries first. What
they lack comes in two kinds, which are kept apart:

| Kind | What it is | Where |
|---|---|---|
| Mathematics | functions, defined by formal properties (`sign`) | `giac_math1`, a private CD |
| Requests to GIAC | commands whose answer depends on GIAC's version and settings (simplify, expand, factor, solve, evalf, series, desolve), and assignment | `giac_procedures1`, a private CD, and `prog1.assignment`, inside `scscp1.procedure_call` |

The private CDs are files of this repository (`docs/cd/`), with their own
base, `https://juliagiac.github.io/giac-openmath/cd`. The table pins each by
SHA-256, like the official CDs, and gives the status each CD declares in its
file. `scscp1` is in OpenMath's Official directory but declares itself
`experimental`. What counts is the declared status, not the directory or the
base.

These rules were reviewed, and approved by the maintainer. They are local
agreements on existing formats: their scope is explicit, and a reader refuses
what falls outside it.

## Readers

- **By default, a reader uses only `official` CDs.** Experimental and private
  CDs are used only when the caller enables them. They are pinned by digest,
  with their exact base and name: a dictionary with the same name and
  revision at another base, or with one changed byte, is another dictionary,
  and may mean something else.
- **A reader whose output feeds claims or evidence** (as MathInterfaceGiac.jl
  or a proof checker would) uses only the official CDs by default. It may accept
  `giac_math1` through an explicit option, pinned by its digest. It never
  accepts procedure symbols: a request is not a mathematical statement.
- **Applications** that drive GIAC (CAScad, Progressive Web Office) may enable
  `giac_math1`, `giac_procedures1`, `prog1` and `scscp1`.

## Requests

A request to GIAC is written as SCSCP writes a procedure call, even without
an SCSCP network:

```
OMATTR(scscp1.call_id              → "42",
       scscp1.option_return_object → "",
       scscp1.option_runtime       → 5000,
  scscp1.procedure_call(
    OMATTR(giac_procedures1.premises     → relation1.gt(x, 0),
           giac_procedures1.complex_mode → logic1.false,
      giac_procedures1.factor(x^4 - 1))))
```

- **Where procedure symbols may appear.** Only as the head of the argument of
  `scscp1.procedure_call`. Only `scscp1.procedure_call` is the envelope:
  `prog1` has its own `procedure_call` symbol, which is not, and a reader
  matches the CD as well as the name. The CDs whose symbols are requests are listed in
  the table (`envelope.procedure_cds`: `giac_procedures1`, `prog1`). A reader
  refuses them anywhere else, and always in a result: an unevaluated command
  is not an answer.
- **The arguments are mathematics**, in official symbols (or `giac_math1` if
  enabled).
- **Options** (`[[procedure_option]]`) are placed as SCSCP places them:
  - `scscp1`'s options (`option_runtime`, GIAC's time limit; `call_id`,
    `option_return_object`) are attributions on the `procedure_call`
    application;
  - GIAC's settings are semantic attributions on the call's argument:
    premises (GIAC's `assume`, for the call only; relations, `logic1.and`,
    `logic1.or`, and `set1.in(x, setname1.R)` to declare `x` real) and
    complex mode (`logic1.true` or `logic1.false`; it changes, for
    instance, which factors `factor` finds).

  GIAC's settings are declared with the role `semantic-attribution`: they
  change GIAC's answers, so a reader must not drop them.
- **The answer is `scscp1.procedure_completed`**, holding the result in
  official symbols, with GIAC's messages as `scscp1.info_message`. A failure
  is `scscp1.procedure_terminated` with `scscp1.error_system_specific`.
- **The result's relation to the request is the one the CD gives, under the
  premises.** It is what a result is checked against; GIAC does not
  guarantee it:
  - simplify, expand, factor: wherever the request's expression is defined,
    the result is defined there and equal to it. The result may be defined
    at more points (`x+1` for `(x^2-1)/(x-1)`, at 1); a result undefined
    where the expression is defined fails;
  - solve: each listed value can be checked against the equations; the list
    is not implied to be complete;
  - factor: GIAC chooses the coefficients (square roots, and `i` in complex
    mode); no field is stated;
  - desolve: solutions, whose constants (GIAC's `c_0`, `c_1`…) are new names
    bound by the result; not implied to be the general solution;
  - series: the part before GIAC's order term, which may contain negative or
    fractional powers, with no order term when the expansion is exact. It
    agrees with the expression to order `n`, with a remainder
    `O((v-a)^(n+1))`;
  - evalf: an approximation, never an equality; it can be checked only with
    an enclosure.
- **Assignment** changes a session's state, so it is a request too:
  `a := value` is `scscp1.procedure_call(prog1.assignment(a, value))`
  (GIAC's `sto(value, a)`). `prog1` is experimental: a reader uses it only
  when enabled. A definition `f(x) := body` needs a lambda as the value,
  which the table does not map yet.

## The status of each CD

| CD | Status | Use |
|---|---|---|
| arith1, transc1, relation1, logic1, nums1, rounding1, minmax1, complex1, integer1, calculus1, limit1, set1, interval1, fns1, quant1, setname1 | official | default |
| scscp1 | experimental (declared) | the envelope of requests, when enabled |
| prog1 | experimental | assignment, inside `scscp1.procedure_call`, when enabled |
| giac_math1 | private | when enabled |
| giac_procedures1 | private | requests, inside `scscp1.procedure_call`, when enabled |
