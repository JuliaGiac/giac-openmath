# The table against GIAC itself, through Giac.jl: node names, aliases and the
# examples of refused nodes are what GIAC reads. Run with test/giac/runtests.jl.

@testsnippet GiacTable begin
    include(joinpath(@__DIR__, "..", "..", "scripts", "table.jl"))
    using Giac
    table = load_table()

    # GIAC input for a GIAC pattern: placeholders become names a1, a2…, #* two of them
    function sample(pattern, input)
        head = pattern[1]
        args = String[]
        for a in pattern[2:end]
            if a == "#*"
                append!(args, ["a$(length(args) + 1)", "a$(length(args) + 2)"])
            elseif isplaceholder(a)
                push!(args, "a" * a[2:end])
            else
                push!(args, string(a))
            end
        end
        input == "call" && return string(head, "(", join(args, ", "), ")")
        (input == "prefix" || length(args) == 1) && return string(strip(head), "(", only(args), ")")
        return join(("(" * a * ")" for a in args), " " * strip(head) * " ")
    end
    # GIAC's tree of `src`, read but not evaluated
    quoted(src) = giac_eval("'" * src * "'")
    node(src) = (g = quoted(src); Giac.iscall(g) ? Giac.symb_funcname(g) : nothing)
end

@testitem "the table was read from this GIAC" tags = [:giac] setup = [GiacTable] begin
    @test table["giac_version"] == string(Giac.giac_version())
end

@testitem "each node name is the one GIAC reads" tags = [:giac] setup = [GiacTable] begin
    for m in table["map"]
        get(m, "direction", "both") == "from_openmath" && continue
        src = sample(m["giac"], get(m, "input", "call"))
        @test node(src) == m["giac"][1]
        g = quoted(src)
        # literal arguments (limit's direction, infinity) are where the pattern says
        for (k, a) in enumerate(m["giac"][2:end])
            (a isa Integer || (a isa AbstractString && !isplaceholder(a))) || continue
            @test string(Giac.arguments(g)[k]) == string(a)
        end
    end
end

@testitem "each alias is read as its node" tags = [:giac] setup = [GiacTable] begin
    for m in table["map"], alias in get(m, "aliases", String[])
        @test node(sample([alias; m["giac"][2:end]], "call")) == m["giac"][1]
    end
end

@testitem "OpenMath to GIAC writes input GIAC reads back" tags = [:giac] setup = [GiacTable] begin
    for m in table["map"]
        get(m, "direction", "both") == "to_openmath" && continue
        src = sample(m["giac"], get(m, "input", "call"))
        @test quoted(src) isa Giac.GiacExpr
    end
    for l in table["leaf"]
        get(l, "direction", "both") == "to_openmath" && continue
        @test string(quoted(l["giac"])) != "undef"
    end
end

@testitem "leaves are GIAC values of their own" tags = [:giac] setup = [GiacTable] begin
    for l in table["leaf"]
        get(l, "direction", "both") == "from_openmath" && continue
        @test !Giac.iscall(quoted(l["giac"]))
    end
end

@testitem "each refused example is read as the refused node" tags = [:giac] setup = [GiacTable] begin
    for r in table["refused"]
        haskey(r, "example") || continue
        @test node(r["example"]) == r["giac"]
    end
end

@testitem "each accepted case of the corpus: its GIAC source has its value" tags = [:giac] setup = [GiacTable] begin
    using JSON
    corpus = JSON.parsefile(joinpath(@__DIR__, "..", "fixtures", "openmath-to-giac.json"))
    # the same value: their difference simplifies to 0, or, for relations and
    # booleans, they print the same
    function same(a, b)
        x, y = giac_eval(a), giac_eval(b)
        string(x) == string(y) && return true
        d = try string(Giac.Commands.simplify(x - y)) catch; "" end
        return d in ("0", "0.0")
    end
    for c in corpus["cases"]
        haskey(c, "value") || continue
        @test same(c["giac_source"], c["value"])
    end
end
