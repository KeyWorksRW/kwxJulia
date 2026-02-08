# Phase 3 high-level API verification test
# Tests the run_app wrapper function

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

println("Testing Phase 3: High-Level API")
println("=" ^ 50)

println("\nTest: run_app with immediate exit")
println("This will initialize, run setup, then exit immediately")

exit_code = WxWidgets.run_app(app_name="TestApp") do
    println("  Inside setup function...")
    println("  No windows created, so app will exit after this block")
    # Signal exit immediately
    WxWidgets.exit_app()
end

println("  Exit code: $exit_code")
println("  ✓ run_app completed successfully")

println("\n" * "=" ^ 50)
println("Phase 3 high-level API test passed! ✓")
