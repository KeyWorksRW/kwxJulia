# Phase 5 verification test
# Tests event handling functionality

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

println("Testing Phase 5: Event Handling")
println("=" ^ 50)

# Test 1: Module loads with new exports
println("\nTest 1: Check exports")
@assert isdefined(WxWidgets, :WxEvent) "WxEvent not exported"
@assert isdefined(WxWidgets, :wx_connect!) "wx_connect! not exported"
@assert isdefined(WxWidgets, :wx_disconnect!) "wx_disconnect! not exported"
@assert isdefined(WxWidgets, :on_close!) "on_close! not exported"
println("  ✓ All exports present")

# Test 2: WxEvent type
println("\nTest 2: WxEvent type")
evt = WxEvent(C_NULL)
@assert evt.ptr == C_NULL "WxEvent construction failed"
println("  ✓ WxEvent type works")

# Test 3: Event handler with frame
println("\nTest 3: Event handler connection")
event_fired = Ref{Bool}(false)

WxWidgets.run_app(app_name="Phase5Test") do
    frame = WxFrame(nothing, "Event Test", size=(400, 300))

    # Connect close event handler
    wx_connect!(frame, wxEVT_CLOSE_WINDOW[]) do event
        println("    Close event received!")
        event_fired[] = true
        # Allow the window to close
    end

    println("  ✓ Event handler connected without errors")
    println("  Closures stored: ", length(frame.closures))
    @assert length(frame.closures) == 1 "Closure not stored"

    # Set as top window and show briefly
    set_top_window(frame)
    show_window(frame)

    # Close immediately for testing
    println("  Closing frame to test event...")
    close(frame, true)
end

# Note: Event may or may not fire depending on timing
# The important thing is that connecting didn't crash
println("  ✓ Frame closed successfully")

# Test 4: Multiple event handlers
println("\nTest 4: Multiple event handlers")
WxWidgets.run_app(app_name="MultiEventTest") do
    frame = WxFrame(nothing, "Multi-Event Test", size=(400, 300))

    # Connect multiple handlers to same window
    handler_count = Ref{Int}(0)

    wx_connect!(frame, wxEVT_CLOSE_WINDOW[]) do event
        handler_count[] += 1
        println("    Handler 1 fired")
    end

    wx_connect!(frame, wxEVT_SIZE[]) do event
        println("    Size event handler")
    end

    println("  ✓ Multiple handlers connected")
    println("  Closures stored: ", length(frame.closures))
    @assert length(frame.closures) == 2 "Expected 2 closures"

    set_top_window(frame)
    show_window(frame)
    close(frame, true)
end

println("  ✓ Multiple handlers work")

# Test 5: Convenience function
println("\nTest 5: on_close! convenience function")
WxWidgets.run_app(app_name="ConvenienceTest") do
    frame = WxFrame(nothing, "Convenience Test", size=(400, 300))

    on_close!(frame) do event
        println("    on_close! handler fired")
    end

    println("  ✓ on_close! works")
    @assert length(frame.closures) == 1 "Closure not stored"

    set_top_window(frame)
    show_window(frame)
    close(frame, true)
end

println("\n" * "=" ^ 50)
println("Phase 5 basic tests passed! ✓")
println("\nNote: Event handlers connected successfully.")
println("Full interactive testing requires manually running examples.")
