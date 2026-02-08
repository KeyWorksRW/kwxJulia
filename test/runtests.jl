# Test runner for kwxJulia

# Add parent directory to load path to find WxWidgets module
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

using Test

# Run all test files
@testset "kwxJulia Tests" begin
    include("test_strings.jl")
    include("test_constants.jl")
    include("test_widgets.jl")
end
