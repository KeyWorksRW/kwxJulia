#!/usr/bin/env julia

# Comprehensive Phase 1+2 verification test

using Pkg
Pkg.activate(".")

println("=== Phase 1: Foundation ===\n")

println("Loading WxWidgets module...")
using WxWidgets

println("✓ Module loaded successfully")
println("  Library path: ", WxWidgets.default_lib_path())
println("  libwxffi handle: ", WxWidgets.libwxffi[])

# Test constants (Phase 2)
println("\n=== Phase 2: Constants & Events ===\n")
println("Constants:")
println("  wxID_ANY = ", wxID_ANY[])
println("  wxID_OK = ", WxWidgets.wxID_OK[])
println("  wxID_CANCEL = ", WxWidgets.wxID_CANCEL[])
println("  wxDEFAULT_FRAME_STYLE = ", wxDEFAULT_FRAME_STYLE[])
println("  wxTE_MULTILINE = ", WxWidgets.wxTE_MULTILINE[])

@assert wxID_ANY[] == -1 "wxID_ANY should be -1"
@assert wxDEFAULT_FRAME_STYLE[] != 0 "wxDEFAULT_FRAME_STYLE should be non-zero"
println("✓ Constants loaded correctly")

println("\nEvent types:")
println("  wxEVT_BUTTON = ", wxEVT_BUTTON[])
println("  wxEVT_CLOSE_WINDOW = ", wxEVT_CLOSE_WINDOW[])
println("  wxEVT_MENU = ", wxEVT_MENU[])
println("  wxEVT_LEFT_DOWN = ", wxEVT_LEFT_DOWN[])
println("  wxEVT_LEFT_UP = ", wxEVT_LEFT_UP[])
println("  wxEVT_PAINT = ", wxEVT_PAINT[])
println("  wxEVT_SIZE = ", wxEVT_SIZE[])

@assert wxEVT_BUTTON[] != 0 "wxEVT_BUTTON should be non-zero"
@assert wxEVT_CLOSE_WINDOW[] != 0 "wxEVT_CLOSE_WINDOW should be non-zero"
@assert wxEVT_SIZE[] != 0 "wxEVT_SIZE should be non-zero"
println("✓ Event types loaded correctly")

# Test string conversion
println("\n=== String Conversion ===\n")
ws = WxString("Hello, wxWidgets!")
str = String(ws)
println("  Round-trip: \"$str\"")
@assert str == "Hello, wxWidgets!" "String round-trip failed"
println("✓ String conversion works")

# Test with Unicode
ws2 = WxString("日本語テスト 🎉")
str2 = String(ws2)
println("  Unicode round-trip: \"$str2\"")
@assert str2 == "日本語テスト 🎉" "Unicode string round-trip failed"
println("✓ Unicode string conversion works")

# Test empty string
ws3 = WxString("")
str3 = String(ws3)
@assert str3 == "" "Empty string round-trip failed"
println("✓ Empty string conversion works")

# Test FFI declarations
println("\n=== FFI App Lifecycle ===\n")
result = WxWidgets.kwxapp_initialize()
println("  kwxApp_Initialize() returned: $result")
@assert result != 0 "wxWidgets initialization failed"
println("✓ wxWidgets initialized successfully")

println("\n✓✓✓ Phase 1 & 2 verification complete! ✓✓✓")
