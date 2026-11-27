# Tests of giac-openmath.toml alone: no computer algebra system needed.

@testsnippet Table begin
    include(joinpath(@__DIR__, "..", "scripts", "table.jl"))
    using SHA, Downloads
    table = load_table()
    maps = table["map"]
    leaves = table["leaf"]
    refused = table["refused"]

    # The pinned CD files, downloaded once into test/.cd-cache and checked by SHA-256
    function cd_names(cd)
        src = table["cd_source"]
        entry = table["cd"][cd]
        cache = joinpath(@__DIR__, ".cd-cache", src["commit"])
        mkpath(cache)
        file = joinpath(cache, cd * ".ocd")
        if !isfile(file)
            url = replace(src["raw"], "{commit}" => src["commit"], "{path}" => entry["path"])
            Downloads.download(url, file)
        end
        @assert bytes2hex(open(sha256, file)) == entry["sha256"] "$cd.ocd does not match its SHA-256"
        text = read(file, String)
        Set(m.captures[1] for m in eachmatch(r"<CDDefinition>\s*<Name>\s*([^<\s]+)\s*</Name>", text))
    end
end

@testitem "the table has the expected format" setup = [Table] begin
    @test table["format"] == 1
    @test occursin(r"^\d+\.\d+\.\d+$", table["giac_version"])
    @test length(table["cd_source"]["commit"]) == 40
    for m in maps
        @test issubset(keys(m), ["giac", "om", "input", "aliases", "direction", "status", "note"])
        @test m["giac"] isa AbstractVector && m["giac"][1] isa AbstractString
        @test haskey(m, "om")
        @test get(m, "direction", "both") in ("both", "to_openmath", "from_openmath")
        @test get(m, "input", "call") in ("call", "infix", "prefix")
        @test get(m, "status", "names") in ("names", "checked")
    end
    for l in leaves
        @test issubset(keys(l), ["giac", "om", "direction", "status", "note"])
        @test get(l, "direction", "both") in ("both", "to_openmath", "from_openmath")
    end
    for r in refused
        @test issubset(keys(r), ["giac", "om", "reason", "example"])
        @test haskey(r, "reason") && (haskey(r, "giac") || haskey(r, "om"))
    end
end

@testitem "every OpenMath symbol is in its pinned Content Dictionary" setup = [Table] begin
    used = vcat([om_symbols(m["om"]) for m in maps]..., [om_symbols(l["om"]) for l in leaves]...,
                [om_symbols(r["om"]) for r in refused if haskey(r, "om")]...)
    @test !isempty(used)
    names = Dict(cd => cd_names(cd) for cd in keys(table["cd"]))
    for s in unique(used)
        cd, name = split(s, '.'; limit = 2)
        @test haskey(names, cd)
        haskey(names, cd) && @test name in names[cd]
    end
end

@testitem "no argument is lost in either direction" setup = [Table] begin
    for m in maps
        g, o = placeholders(m["giac"]), placeholders(m["om"])
        @test Set(g) == Set(o)
        # numbered from 1 without a gap; #* only last on the GIAC side
        nums = sort!(unique(parse(Int, p[2:end]) for p in g if p != "#*"))
        @test nums == collect(1:length(nums))
        @test !("#*" in g) || g[end] == "#*"
    end
end

@testitem "each direction is a function" setup = [Table] begin
    to = [m for m in maps if get(m, "direction", "both") != "from_openmath"]
    from = [m for m in maps if get(m, "direction", "both") != "to_openmath"]
    @test allunique(repr(m["giac"]) for m in to)
    @test allunique(repr(m["om"]) for m in from)
    lto = [l for l in leaves if get(l, "direction", "both") != "from_openmath"]
    lfrom = [l for l in leaves if get(l, "direction", "both") != "to_openmath"]
    @test allunique(l["giac"] for l in lto)
    @test allunique(l["om"] for l in lfrom)
end

@testitem "nothing is both mapped and refused" setup = [Table] begin
    mapped_giac = Set(m["giac"][1] for m in maps if get(m, "direction", "both") != "from_openmath")
    mapped_om = Set(m["om"] isa AbstractVector ? m["om"][1] : m["om"] for m in maps if get(m, "direction", "both") != "to_openmath")
    for r in refused
        haskey(r, "giac") && @test !(r["giac"] in mapped_giac)
        haskey(r, "om") && @test !(r["om"] in mapped_om)
    end
end

@testitem "giac-openmath.json is up to date" setup = [Table] begin
    @test isfile(JSON_PATH)
    @test read(JSON_PATH, String) == table_json(table)
end
