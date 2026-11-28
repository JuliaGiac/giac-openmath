# The shared corpus test/fixtures/openmath-to-giac.json, checked against the table,
# without a computer algebra system (the GIAC side is in test/giac).

@testsnippet Fixtures begin
    include(joinpath(@__DIR__, "..", "scripts", "table.jl"))
    using JSON
    table = load_table()
    corpus = JSON.parsefile(joinpath(@__DIR__, "fixtures", "openmath-to-giac.json"))
    cases = corpus["cases"]

    # every OMS of an OpenMath JSON object, with its path
    function oms_paths(o, path = Any[])
        out = Tuple{String, Vector{Any}}[]
        if o isa AbstractDict
            get(o, "kind", nothing) == "OMS" && push!(out, (o["cd"] * "." * o["name"], path))
            for (k, v) in o
                append!(out, oms_paths(v, [path; k]))
            end
        elseif o isa AbstractVector
            for (i, v) in enumerate(o)
                append!(out, oms_paths(v, [path; i - 1]))
            end
        end
        return out
    end
    # the OpenMath symbols the table reads (from_openmath), and the leaf conventions
    om_heads = Set{String}()
    for m in table["map"]
        get(m, "direction", "both") == "to_openmath" && continue
        foreach(s -> push!(om_heads, s), om_symbols(m["om"]))
    end
    for l in table["leaf"]
        get(l, "direction", "both") == "to_openmath" || push!(om_heads, l["om"])
    end
    push!(om_heads, "nums1.rational", "complex1.complex_cartesian")   # number constructors
    refused_om = Dict(r["om"] => r["reason"] for r in table["refused"] if haskey(r, "om"))
    # walk a JSON path into an object
    at(o, path) = isempty(path) ? o : at(o[path[1] isa Integer ? path[1] + 1 : path[1]], path[2:end])
end

@testitem "the corpus has the expected format" setup = [Fixtures] begin
    @test corpus["format"] == 1
    @test corpus["table_commit"] isa String && length(corpus["table_commit"]) == 40
    @test !isempty(cases)
    @test allunique(c["name"] for c in cases)
    for c in cases
        @test issubset(keys(c), ["name", "om", "giac_source", "value", "refused", "options", "note"])
        @test haskey(c, "om") && (haskey(c, "value") ⊻ haskey(c, "refused"))
        if haskey(c, "refused")
            @test issubset(keys(c["refused"]), ["path", "reason_contains", "symbol", "kind"])
            @test c["refused"]["path"] isa AbstractVector
        else
            @test c["giac_source"] isa String && c["value"] isa String
        end
    end
end

@testitem "every symbol of an accepted case is one the table reads" setup = [Fixtures] begin
    for c in cases
        haskey(c, "value") || continue
        for (s, _) in oms_paths(c["om"])
            @test s in om_heads
        end
    end
end

@testitem "every refusal points at a node, and agrees with the table" setup = [Fixtures] begin
    for c in cases
        haskey(c, "refused") || continue
        r = c["refused"]
        node = at(c["om"], r["path"])                  # the path leads somewhere
        @test node isa AbstractDict
        if haskey(r, "symbol")
            # a refused symbol is refused by the table, or not read by it at all
            @test haskey(refused_om, r["symbol"]) || !(r["symbol"] in om_heads)
            haskey(refused_om, r["symbol"]) && haskey(r, "reason_contains") &&
                @test occursin(r["reason_contains"], refused_om[r["symbol"]])
        end
    end
end

@testitem "the corpus is pinned to a table at a commit of this repository" setup = [Fixtures] begin
    @test occursin(r"^[0-9a-f]{40}$", corpus["table_commit"])
end
