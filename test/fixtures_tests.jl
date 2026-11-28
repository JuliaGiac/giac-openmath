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

    # format 2: statuses, bases and requests
    const STANDARD_CDBASE = "http://www.openmath.org/cd"
    cd_of(s) = first(split(s, '.'))
    status(cd) = haskey(table["cd"], cd) ? table["cd"][cd]["status"] : nothing
    base(cd) = haskey(table["cd"], cd) ? get(table["cd"][cd], "cdbase", STANDARD_CDBASE) : STANDARD_CDBASE
    enabled(c) = Set{String}(get(get(c, "options", Dict()), "enable", String[]))
    procedure_cds = Set{String}(table["envelope"]["procedure_cds"])
    # every OMS with its path and its base: its own cdbase, or the nearest
    # enclosing object's, or OpenMath's
    function oms_bases(o, path = Any[], b = STANDARD_CDBASE)
        out = Tuple{String, Vector{Any}, String}[]
        if o isa AbstractDict
            b = get(o, "cdbase", b)
            get(o, "kind", nothing) == "OMS" && push!(out, (o["cd"] * "." * o["name"], path, b))
            for (k, v) in o
                append!(out, oms_bases(v, [path; k], b))
            end
        elseif o isa AbstractVector
            for (i, v) in enumerate(o)
                append!(out, oms_bases(v, [path; i - 1], b))
            end
        end
        return out
    end
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

@testitem "the options are those of the reading rules" setup = [Fixtures] begin
    for c in cases
        o = get(c, "options", Dict())
        @test issubset(keys(o), ["exact", "enable"])
        # only CDs that are not official need enabling
        for cd in enabled(c)
            @test status(cd) in ("experimental", "private")
        end
    end
end

@testitem "an accepted case uses official CDs, or enabled ones, at their base" setup = [Fixtures] begin
    for c in cases
        haskey(c, "value") || continue
        for (s, _, b) in oms_bases(c["om"])
            cd = cd_of(s)
            @test status(cd) == "official" || cd in enabled(c)
            @test b == base(cd)
            @test !(cd in procedure_cds)       # requests are not evaluated as mathematics
        end
    end
end

@testitem "the format 2 refusals have their cases" setup = [Fixtures] begin
    # a symbol of a CD that is not enabled, at another base, or a request out of place
    why(c) = begin
        r = c["refused"]
        haskey(r, "symbol") || return nothing
        node = at(c["om"], r["path"])
        b = only(b for (s, p, b) in oms_bases(c["om"]) if p == r["path"])
        cd = cd_of(r["symbol"])
        status(cd) in ("experimental", "private") && !(cd in enabled(c)) && return :status
        b != base(cd) && return :base
        cd in procedure_cds && return :placement
        return nothing
    end
    kinds = Set(why(c) for c in cases if haskey(c, "refused"))
    @test issubset([:status, :base, :placement], kinds)
    for c in cases
        haskey(c, "refused") || continue
        w = why(c)
        w === :status && @test occursin(status(cd_of(c["refused"]["symbol"])), c["refused"]["reason_contains"])
        w === :base && @test c["refused"]["reason_contains"] == "base"
        w === :placement && @test c["refused"]["reason_contains"] == "procedure_call"
    end
end

@testitem "every refusal points at a node, and agrees with the table" setup = [Fixtures] begin
    for c in cases
        haskey(c, "refused") || continue
        r = c["refused"]
        node = at(c["om"], r["path"])                  # the path leads somewhere
        @test node isa AbstractDict
        if haskey(r, "symbol")
            # a refused symbol is refused by the table, or not read by it at all,
            # or refused by the format 2 rules (its CD not enabled, another base,
            # a request out of place)
            cd = cd_of(r["symbol"])
            b = only(b for (s, p, b) in oms_bases(c["om"]) if p == r["path"])
            format2 = (status(cd) in ("experimental", "private") && !(cd in enabled(c))) ||
                      b != base(cd) || cd in procedure_cds
            @test haskey(refused_om, r["symbol"]) || !(r["symbol"] in om_heads) || format2
            haskey(refused_om, r["symbol"]) && haskey(r, "reason_contains") &&
                @test occursin(r["reason_contains"], refused_om[r["symbol"]])
        end
    end
end

@testitem "the corpus is pinned to a table at a commit of this repository" setup = [Fixtures] begin
    @test occursin(r"^[0-9a-f]{40}$", corpus["table_commit"])
end
