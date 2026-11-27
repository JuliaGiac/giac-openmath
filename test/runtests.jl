# The table's own tests. The tests that run GIAC are in test/giac/.
using TestItemRunner
TestItemRunner.run_tests(@__DIR__; filter = ti -> !(:giac in ti.tags))
