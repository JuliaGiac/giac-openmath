# giac-openmath

What the expression trees of [Giac](https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac.html)
mean in [OpenMath](https://openmath.org/) Content Dictionaries, and back: one
table, so that each program that talks to Giac maps Giac's names once, to a
common language, instead of once per pair of programs.

```toml
[[map]]
giac = ["ln", "#1"]
om = ["transc1.ln", "#1"]
aliases = ["log"]

[[map]]
giac = ["integrate", "#1", "#2", "#3", "#4"]
om = ["calculus1.defint", ["interval1.interval", "#3", "#4"], ["bind", "fns1.lambda", ["#2"], "#1"]]
```

It is data, with no code to run: `giac-openmath.toml`, and the same as JSON in
`giac-openmath.json`. Its format is described in [docs/format.md](docs/format.md).

## What it maps

The `giac` side is GIAC itself, the C++ library, at the version in
`giac_version`: the names of the nodes of its expression trees, which every
binding sees (Giac.jl, giac-wasm, Xcas…). Names in other languages, such as
Julia's `log`, belong to their own OpenMath phrasebook (for Julia,
[OpenMath.jl](https://github.com/s-celles/OpenMath.jl)).

The first version covers the official Content Dictionaries arith1, transc1,
relation1, logic1, nums1, rounding1, minmax1, complex1, integer1, calculus1
and limit1, with set1, interval1 and fns1 for their arguments, pinned at one
commit of [OpenMath/CDs](https://github.com/OpenMath/CDs) and checked by
SHA-256.

What has no Content Dictionary symbol is refused, and so are false friends,
each with the reason. For instance:

- GIAC's `irem(-7, 3)` is 2, `integer1.remainder` gives -1;
- GIAC's `x mod 3` is a residue class, not a remainder;
- GIAC's `a => b` is an assignment, not an implication.

An entry says that a GIAC node and an OpenMath symbol name the same operation
with the same arguments (`status = "names"`). It does not say that their
domains, branch cuts and conventions agree; the notes record what is known to
differ (GIAC evaluates `trunc(x)` to `floor(x)`, `acot(x)` to `atan(1/x)`…).

## Tests

```bash
just test        # the table alone: format, symbols in the pinned CDs, no lost
                 # argument, each direction a function, JSON up to date
just test-giac   # against GIAC through Giac.jl: node names, aliases, and the
                 # examples of refused nodes are what GIAC reads
just export      # regenerate giac-openmath.json
```

## Using it

Read the JSON (or the TOML) and walk an expression tree:

- to OpenMath: find the entry whose GIAC pattern matches the node (literal
  patterns first), and build its OpenMath pattern from the converted
  arguments;
- from OpenMath: find the entry whose OpenMath pattern matches, and write the
  GIAC input of its GIAC pattern;
- refuse anything the table does not list.

## License

MIT (see `LICENSE`). The OpenMath Content Dictionaries are not copied here:
the tests download them from OpenMath/CDs at the pinned commit.
