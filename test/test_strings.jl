# String conversion tests

using Test
using WxWidgets

@testset "String Conversion" begin
    @testset "Basic String Round-trip" begin
        # Test simple ASCII string
        original = "Hello, World!"
        ws = WxString(original)
        result = String(ws)
        @test result == original
        delete!(ws)
    end

    @testset "UTF-8 String Round-trip" begin
        # Test UTF-8 string with special characters
        original = "Hello, 世界! Привет! 你好!"
        ws = WxString(original)
        result = String(ws)
        @test result == original
        delete!(ws)
    end

    @testset "Empty String" begin
        # Test empty string
        original = ""
        ws = WxString(original)
        result = String(ws)
        @test result == original
        delete!(ws)
    end

    @testset "String with Special Characters" begin
        # Test string with newlines, tabs, etc.
        original = "Line 1\nLine 2\tTabbed\rCarriage Return"
        ws = WxString(original)
        result = String(ws)
        @test result == original
        delete!(ws)
    end

    @testset "Long String" begin
        # Test long string
        original = repeat("Julia ", 1000)
        ws = WxString(original)
        result = String(ws)
        @test result == original
        delete!(ws)
    end

    @testset "Convert Function" begin
        # Test convert function
        original = "Convert Test"
        ws = convert(WxString, original)
        result = convert(String, ws)
        @test result == original
        delete!(ws)
    end
end
