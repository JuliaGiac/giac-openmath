# The shared corpus: test/fixtures/openmath-to-giac.json

Cases of OpenMath read into GIAC through this table, for every program that
does it, so that they agree: giac-wasm's `giac-wasm/openmath` (`evalOpenMath`,
`giacSource`), Giac.jl's GiacOpenMathExt (`Giac.from_openmath`), and producers
such as `mathjson-openmath`, whose output they read.

```json
{
  "format": 1,
  "table_commit": "d7311e73ec014589259d03febc9d152b4b2b5dbd",
  "cases": [
    { "name": "log to a base",
      "om": { "kind": "OMA", "applicant": { "kind": "OMS", "cd": "transc1", "name": "log" },
              "arguments": [ { "kind": "OMI", "integer": 2 }, { "kind": "OMV", "name": "x" } ] },
      "giac_source": "logb(x, 2)",
      "value": "ln(x)/ln(2)" },
    { "name": "remainder is a false friend",
      "om": { "kind": "OMA", "applicant": { "kind": "OMS", "cd": "integer1", "name": "remainder" },
              "arguments": [ { "kind": "OMI", "integer": 7 }, { "kind": "OMI", "integer": 3 } ] },
      "refused": { "path": ["applicant"], "symbol": "integer1.remainder", "reason_contains": "residue class" } }
  ]
}
```

## Fields

| Field | Meaning |
|---|---|
| `table_commit` | The commit of this repository's table the cases are written for. |
| `name` | Unique. |
| `om` | The input, in the OpenMath 2.0 JSON encoding (the root object, without an `OMOBJ` wrapper). |
| `options` | Optional reader options: `{"exact": true}` refuses floats; `{"enable": ["giac_math1", …]}` enables CDs that are not official. |
| `giac_source` | For an accepted case: GIAC input a reader may write. Informative: readers may parenthesize differently. |
| `value` | For an accepted case: GIAC input of the value. The reader's GIAC result must equal it: their difference simplifies to 0, or they print the same (relations, booleans). |
| `refused` | For a refused case: `path` is the JSON path of the refused node from the root of `om`, with array indices from 0 (`[]` is the root); `symbol` (`cd.name`) or `kind` (`OMV`, `OMI`, `OMA`…) names it; `reason_contains`, when given, is a substring of the reason. |
| `note` | Why the case is there, when it is not obvious. |

A case has either `value` or `refused`.

## The reading rules the cases follow

These are the input contract of `giac-wasm/openmath` (JuliaGiac/giac#22):

- **Kinds.** Only `OMA`, `OMBIND`, `OMS`, `OMV`, `OMI` and `OMF` are read. The other kinds are refused.
- **Integers.** An integer beyond ±2^53 must be given as `decimal`, a string. A JSON-number `integer` that is not a safe integer is refused, since it may already have been rounded.
- **Variables.** A variable is a GIAC identifier, `[A-Za-z][A-Za-z0-9_]*`. A free variable whose name GIAC reads as a constant (`e`, `i`, `pi`, …) or as a command is refused.
- **Bound variables named as constants.** A variable bound by an `OMBIND` (`fns1.lambda`: sums, products, integrals, limits) whose name GIAC reads as a constant is renamed, since renaming a bound variable keeps the meaning (alpha-conversion). The fresh name is the name followed by `_1`, `_2`…: the first that no variable of the object uses. So `sum` over `i` of `i^2` is written `sum(i_1^2, i_1, 1, n)`. A result that still holds the binding shows the fresh name. A bound variable named as a GIAC command is still refused.
- **Bound variables.** In the table's `bind`/`apply` patterns, the applied variable must be the bound one.
- **Content Dictionaries (format 2).** By default only the table's `official` CDs are read. A symbol of an `experimental` or `private` CD is refused, unless the caller enables its CD (`"enable"`), with a reason that names the status.
- **Bases.** A symbol's base is its own `cdbase`, or else the nearest enclosing object's, or else `http://www.openmath.org/cd`. It must be the table's base for its CD (`cd.<name>.cdbase`, or OpenMath's): the same name at another base is another dictionary. Otherwise the symbol is refused, with a reason that contains "base".
- **Requests.** A symbol of a CD in `envelope.procedure_cds` is valid only as the head of the argument of `scscp1.procedure_call`; anywhere else it is refused, with a reason that contains "procedure_call". Evaluating requests is not part of this corpus yet.
- **Order.** A reader refuses the first symbol, in document order (an application's head before its arguments), that breaks one of these rules.
- **Refusals.** A refused symbol gives the table's `reason`.

## Tests

`just test` checks the corpus against the table, without GIAC:
- its format;
- that every symbol of an accepted case is one the table reads;
- that every refusal's path leads to a node, and that a refused symbol is refused by the table or not read by it.

`just test-giac` checks, through Giac.jl, that every accepted case's `giac_source` gives its `value`.

A reader tests itself against the corpus: from each `om`, it must give the `value`, or refuse at `path`.
