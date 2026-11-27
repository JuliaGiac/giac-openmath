# Write giac-openmath.json from giac-openmath.toml: `just export`.
include(joinpath(@__DIR__, "table.jl"))
write(JSON_PATH, table_json())
println("wrote ", JSON_PATH)
