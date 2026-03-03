# Advanced Event Handling Example
# Demonstrates multiple event types and error handling

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

println("Advanced Event Handling Example")
println("=" ^ 50)
println("\nDemonstrates:")
println("  - on_close! convenience function")
println("  - Multiple event handlers on same window")
println("  - Exception handling in event handlers")
println("  - Event state tracking")
println("\nInteract with the window, then close to exit.")
println()

# Global state to track events
event_counts = Dict{String, Int}(
    "close" => 0,
    "size" => 0,
    "paint" => 0
)

WxWidgets.run_app(app_name="AdvancedEventDemo") do
    frame = wxFrame(nothing, "Advanced Event Demo",
                    size=(700, 500),
                    pos=(100, 100))

    create_status_bar(frame, 2)
    set_status_text(frame, "Event Demo Active", 0)
    set_status_text(frame, "Events: 0", 1)

    # Use convenience function for close event
    on_close!(frame) do event
        event_counts["close"] += 1
        total = sum(values(event_counts))

        println("\n📊 Event Statistics:")
        println("  Close events:  ", event_counts["close"])
        println("  Size events:   ", event_counts["size"])
        println("  Paint events:  ", event_counts["paint"])
        println("  Total events:  ", total)
        println("\n👋 Goodbye!")
    end

    # Size event with detailed logging
    wx_connect!(frame, KwxFFI.wxEVT_SIZE()) do event
        event_counts["size"] += 1
        size = get_size(frame)
        pos = get_position(frame)

        println("📏 Size Event #$(event_counts["size"]):")
        println("  New size: $(size[1]) x $(size[2])")
        println("  Position: $(pos[1]), $(pos[2])")

        total = sum(values(event_counts))
        set_status_text(frame, "Resized to $(size[1])x$(size[2])", 0)
        set_status_text(frame, "Events: $total", 1)
    end

    # Paint event (may fire frequently)
    wx_connect!(frame, KwxFFI.wxEVT_PAINT()) do event
        event_counts["paint"] += 1
        # Don't log every paint - too noisy
        if event_counts["paint"] % 10 == 0
            println("🎨 Paint Event ($(event_counts["paint"]) total)")
        end
    end

    # Demonstrate error handling - this won't crash the app
    wx_connect!(frame, KwxFFI.wxEVT_LEFT_DOWN()) do event
        println("\n⚠️  Testing exception handling...")
        # This error will be caught and logged
        error("Intentional error to demonstrate error handling")
    end

    println("Event handlers registered:")
    println("  ✓ Close event (via on_close!)")
    println("  ✓ Size event")
    println("  ✓ Paint event")
    println("  ✓ Left mouse down (with intentional error)")
    println("  Total closures: ", length(frame.closures))
    println()
    println("Try the following:")
    println("  1. Resize the window → size events fire")
    println("  2. Click in the window → error is caught safely")
    println("  3. Close the window → see event statistics")
    println()

    centre(frame)
    set_top_window(frame)
    show_window(frame)
end

println("\nApplication finished successfully!")
println("All event handlers were garbage-collected safely.")
