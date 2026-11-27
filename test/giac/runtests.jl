# The tests that run GIAC: `just test-giac`. They need Giac.jl in this environment.
using TestItemRunner
TestItemRunner.run_tests(joinpath(@__DIR__, ".."); filter = ti -> :giac in ti.tags)
