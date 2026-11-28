# Tests of giac-openmath.toml alone: no computer algebra system needed.

@testsnippet Table begin
    include(joinpath(@__DIR__, "..", "scripts", "table.jl"))
    using SHA, Downloads
    table = load_table()
    maps = table["map"]
    leaves = table["leaf"]
    refused = table["refused"]

    # The pinned CD files, downloaded once into test/.cd-cache and checked by SHA-256
    # the text of a CD: a private one from this repository, the others downloaded
    # once from OpenMath/CDs into test/.cd-cache; checked by SHA-256 either way
    function cd_text(cd)
        entry = table["cd"][cd]
        if get(entry, "local", false)
            file = joinpath(@__DIR__, "..", entry["path"])
        else
            src = table["cd_source"]
            cache = joinpath(@__DIR__, ".cd-cache", src["commit"])
            mkpath(cache)
            file = joinpath(cache, cd * ".ocd")
            if !isfile(file)
                url = replace(src["raw"], "{commit}" => src["commit"], "{path}" => entry["path"])
                Downloads.download(url, file)
            end
        end
        @assert bytes2hex(open(sha256, file)) == entry["sha256"] "$cd.ocd does not match its SHA-256"
        return read(file, String)
    end
    cd_names(cd) = Set(m.captures[1] for m in eachmatch(r"<CDDefinition>\s*<Name>\s*([^<\s]+)\s*</Name>", cd_text(cd)))
    cd_field(cd, field) = (m = match(Regex("<$field>\\s*([^<\\s]+)\\s*</$field>"), cd_text(cd)); m === nothing ? nothing : m.captures[1])
    procedures = get(table, "procedure", Any[])
    options = get(table, "procedure_option", Any[])
end

@testitem "the table has the expected format" setup = [Table] begin
    @test table["format"] == 2
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

@testitem "each Content Dictionary declares the status the table gives it" setup = [Table] begin
    for (cd, entry) in table["cd"]
        @test entry["status"] in ("official", "experimental", "private")
        # the status a CD declares, not the directory it is in (scscp1 is in
        # Official and declares itself experimental)
        @test cd_field(cd, "CDStatus") == entry["status"]
        # GIAC's options of a call change its meaning: a reader must not drop them
        if cd == "giac_procedures1"
            text = cd_text(cd)
            for name in ("premises", "complex_mode")
                m = match(Regex("<Name>$name</Name>\\s*<Role>([^<]+)</Role>"), text)
                @test m !== nothing && m.captures[1] == "semantic-attribution"
            end
        end
        if entry["status"] == "private"
            @test get(entry, "local", false)
            @test entry["cdbase"] != "http://www.openmath.org/cd"
            @test cd_field(cd, "CDBase") == entry["cdbase"]
            @test cd_field(cd, "CDName") == cd
        else
            @test !haskey(entry, "cdbase")
        end
    end
end

@testitem "procedures stay apart from mathematics" setup = [Table] begin
    proc_cds = Set(table["envelope"]["procedure_cds"])
    @test issubset(proc_cds, keys(table["cd"]))
    @test !isempty(procedures) && !isempty(proc_cds)
    for p in procedures
        @test issubset(keys(p), ["giac", "om", "note"])
        @test split(p["om"][1], '.')[1] in proc_cds
        @test Set(placeholders(p["giac"])) == Set(placeholders(p["om"]))
        # its arguments are mathematics: no procedure symbol inside
        @test all(s -> !(split(s, '.')[1] in proc_cds), om_symbols(p["om"][2:end]))
    end
    # and no map, leaf or refusal uses a procedure symbol
    for e in vcat(maps, leaves, refused)
        haskey(e, "om") || continue
        @test all(s -> !(split(s, '.')[1] in proc_cds), om_symbols(e["om"]))
    end
    env = table["envelope"]
    @test Set(keys(env)) == Set(["procedure_cds", "call", "completed", "terminated", "message", "error"])
    for o in options
        @test issubset(keys(o), ["om", "giac", "note"])
    end
end

@testitem "every OpenMath symbol is in its pinned Content Dictionary" setup = [Table] begin
    used = vcat([om_symbols(m["om"]) for m in maps]..., [om_symbols(l["om"]) for l in leaves]...,
                [om_symbols(r["om"]) for r in refused if haskey(r, "om")]...,
                [om_symbols(p["om"]) for p in procedures]..., [o["om"] for o in options]...,
                [v for (k, v) in table["envelope"] if k != "procedure_cds"])
    @test !isempty(used)
    names = Dict(cd => cd_names(cd) for cd in keys(table["cd"]))
    for s in unique(used)
        cd, name = split(s, '.'; limit = 2)
        @test haskey(names, cd)
        haskey(names, cd) && @test name in names[cd]
    end
end

@testitem "no argument is lost in either direction" setup = [Table] begin
    for m in vcat(maps, procedures)
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
