# Phase 4 verification test
# Tests WxFrame and WxWindow functionality

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

println("Testing Phase 4: Window and Frame")
println("=" ^ 50)

# Test 1: Module loads with new exports
println("\nTest 1: Check exports")
@assert isdefined(WxWidgets, :WxFrame) "WxFrame not exported"
@assert isdefined(WxWidgets, :show_window) "show_window not exported"
@assert isdefined(WxWidgets, :hide) "hide not exported"
@assert isdefined(WxWidgets, :create_status_bar) "create_status_bar not exported"
println("  ✓ All exports present")

# Test 2: Create a frame
println("\nTest 2: Create WxFrame")
frame = WxFrame(nothing, "Test Frame", size=(400, 300))
@assert frame.ptr != C_NULL "Frame pointer is NULL"
@assert length(frame.children) == 0 "Children not initialized correctly"
@assert length(frame.closures) == 0 "Closures not initialized correctly"
println("  ✓ WxFrame created successfully")
println("  Frame pointer: ", frame.ptr)

# Test 3: Frame position and size
println("\nTest 3: Frame position and size")
size = get_size(frame)
println("  Size: $size")
@assert size[1] > 0 && size[2] > 0 "Invalid size"
println("  ✓ get_size() works")

pos = get_position(frame)
println("  Position: $pos")
println("  ✓ get_position() works")

# Test 4: Set label
println("\nTest 4: Set frame label")
set_label(frame, "Updated Title")
label = get_label(frame)
println("  Label: \"$label\"")
@assert occursin("Updated", label) "Label not updated"
println("  ✓ set_label() and get_label() work")

# Test 5: Status bar
println("\nTest 5: Status bar")
create_status_bar(frame, 1)
set_status_text(frame, "Ready")
println("  ✓ create_status_bar() and set_status_text() work")

# Test 6: Show frame briefly
println("\nTest 6: Show frame")
show_window(frame, true)
println("  ✓ show_window() called (frame should be visible)")
@assert is_shown(frame) "Frame not shown"
println("  ✓ is_shown() returns true")

# Test 7: Center frame
println("\nTest 7: Center frame")
centre(frame)
println("  ✓ centre() works")

# Test 8: Close frame
println("\nTest 8: Close frame")
close(frame, true)
println("  ✓ Frame closed")

println("\n" * "=" ^ 50)
println("Phase 4 basic tests passed! ✓")
println("\nNote: Frame was shown briefly. If you saw a window, display works correctly.")
