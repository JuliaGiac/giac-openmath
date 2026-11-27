# giac-openmath: the table of GIAC nodes and OpenMath symbols.
# Requires: https://github.com/casey/just and Julia.

# List available recipes
default:
    @just --list

# Test the table alone (format, pinned CDs, directions, JSON up to date)
test:
    julia --project=test -e 'using Pkg; Pkg.instantiate(); include("test/runtests.jl")'

# Test the table against GIAC, through Giac.jl's main branch
test-giac:
    julia --project=test/giac -e 'using Pkg; Pkg.add(url="https://github.com/JuliaGiac/Giac.jl"); Pkg.instantiate(); include("test/giac/runtests.jl")'

# Regenerate giac-openmath.json from giac-openmath.toml
export:
    julia scripts/export.jl
