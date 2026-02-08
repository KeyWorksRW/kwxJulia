# Phase 3 verification test
# Tests that kwxApp functions work correctly

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

println("Testing Phase 3: Application Lifecycle")
println("=" ^ 50)

# Test 1: Initialization
println("\nTest 1: kwxApp_Initialize")
result = WxWidgets.kwxapp_initialize()
println("  Initialize result: $result")
@assert result != 0 "kwxApp_Initialize failed"
println("  ✓ Initialize succeeded")

# Test 2: Set app name
println("\nTest 2: kwxApp_SetAppName")
WxWidgets.kwxapp_setappname("TestApp")
println("  ✓ App name set")

# Test 3: Init image handlers
println("\nTest 3: kwxApp_InitAllImageHandlers")
WxWidgets.kwxapp_initallimagehandlers()
println("  ✓ Image handlers initialized")

# Test 4: Set exit on frame delete
println("\nTest 4: kwxApp_SetExitOnFrameDelete")
WxWidgets.kwxapp_setexitonframedelete(true)
println("  ✓ Exit on frame delete set")

# Test 5: Exit signal (to prevent hanging if mainloop is called)
println("\nTest 5: kwxApp_ExitMainLoop")
WxWidgets.kwxapp_exit()
println("  ✓ Exit signal sent")

# Note: We don't test MainLoop here because without windows it may not behave
# predictably. The MainLoop will be properly tested in Phase 4 when we can
# create windows and set a top window.

# Test 6: Cleanup
println("\nTest 6: kwxApp_Shutdown")
WxWidgets.kwxapp_shutdown()
println("  ✓ Shutdown completed")

println("\n" * "=" ^ 50)
println("Phase 3 basic tests passed! ✓")
println("\nNote: Full MainLoop testing requires Phase 4 (Window/Frame)")
