# Reading giac-openmath.toml: shared by the tests and scripts/export.jl.
# Uses the standard library only (TOML), so any consumer can include it.

using TOML

const ROOT = normpath(joinpath(@__DIR__, ".."))
const TABLE_PATH = joinpath(ROOT, "giac-openmath.toml")
const JSON_PATH = joinpath(ROOT, "giac-openmath.json")

load_table(path = TABLE_PATH) = TOML.parsefile(path)

# A placeholder "#1", "#2"…, or "#*" for all remaining arguments
isplaceholder(x) = x isa AbstractString && startswith(x, "#")
# An OpenMath symbol, "cd.name"
issymbol(x) = x isa AbstractString && !isplaceholder(x) && occursin('.', x) && x ∉ ("apply", "bind")

"Every placeholder of a pattern, in order of appearance."
placeholders(p) = p isa AbstractVector ? reduce(vcat, map(placeholders, p); init = String[]) :
                  isplaceholder(p) ? [String(p)] : String[]

"Every OpenMath symbol (`cd.name`) of an OpenMath pattern."
om_symbols(p) = p isa AbstractVector ? reduce(vcat, map(om_symbols, p); init = String[]) :
                issymbol(p) ? [String(p)] : String[]

# Deterministic JSON, keys sorted, for giac-openmath.json (no dependency)
function write_json(io::IO, x, indent = 0)
    pad(n) = " "^n
    if x isa AbstractDict
        ks = sort!(collect(keys(x)))
        isempty(ks) && return print(io, "{}")
        println(io, "{")
        for (i, k) in enumerate(ks)
            print(io, pad(indent + 2)); write_json(io, String(k)); print(io, ": ")
            write_json(io, x[k], indent + 2)
            println(io, i < length(ks) ? "," : "")
        end
        print(io, pad(indent), "}")
    elseif x isa AbstractVector
        # short arrays of scalars on one line, like the patterns
        if all(v -> !(v isa AbstractDict || v isa AbstractVector), x) || all(v -> !(v isa AbstractDict), x)
            print(io, "[")
            for (i, v) in enumerate(x)
                i > 1 && print(io, ", ")
                write_json(io, v, indent)
            end
            print(io, "]")
        else
            println(io, "[")
            for (i, v) in enumerate(x)
                print(io, pad(indent + 2)); write_json(io, v, indent + 2)
                println(io, i < length(x) ? "," : "")
            end
            print(io, pad(indent), "]")
        end
    elseif x isa AbstractString
        print(io, '"')
        for c in x
            c == '"' ? print(io, "\\\"") : c == '\\' ? print(io, "\\\\") :
            c == '\n' ? print(io, "\\n") : c < ' ' ? print(io, "\\u", string(UInt16(c); base = 16, pad = 4)) : print(io, c)
        end
        print(io, '"')
    elseif x isa Bool
        print(io, x ? "true" : "false")
    elseif x isa Integer
        print(io, x)
    else
        error("no JSON form for $(typeof(x))")
    end
end

"The table as JSON text, what giac-openmath.json must hold."
table_json(table = load_table()) = sprint(io -> (write_json(io, table); println(io)))
