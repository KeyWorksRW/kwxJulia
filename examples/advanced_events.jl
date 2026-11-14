# Advanced Event Handling Example
# Demonstrates multiple event types and error handling.

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

println("Advanced Event Handling Example")
println("=" ^ 50)
println("\nDemonstrates:")
println("  - Multiple event handlers on same window")
println("  - Exception handling in event handlers")
println("  - Event state tracking")
println("\nInteract with the window, then close to exit.")
println()

event_counts = Dict{String, Int}(
    "close" => 0,
    "size" => 0,
    "paint" => 0
)

WxWidgets.run_app(app_name="AdvancedEventDemo") do
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "Advanced Event Demo",
                    100, 100, 700, 500, KwxFFI.DEFAULT_FRAME_STYLE())

    create_status_bar(frame, 2, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Event Demo Active", 0)
    set_status_text!(frame, "Events: 0", 1)

    wx_connect!(frame, KwxFFI.EVT_CLOSE_WINDOW()) do event
        event_counts["close"] += 1
        total = sum(values(event_counts))

        println("\n📊 Event Statistics:")
        println("  Close events:  ", event_counts["close"])
        println("  Size events:   ", event_counts["size"])
        println("  Paint events:  ", event_counts["paint"])
        println("  Total events:  ", total)
        println("\n👋 Goodbye!")
        # Let the frame's default close handling destroy the window.
        skip!(event, true)
    end

    wx_connect!(frame, KwxFFI.EVT_SIZE()) do event
        event_counts["size"] += 1
        size = get_size(frame)
        pos = get_position(frame)

        println("📏 Size Event #$(event_counts["size"]):")
        println("  New size: $(get_width(size)) x $(get_height(size))")
        println("  Position: $(get_x(pos)), $(get_y(pos))")

        total = sum(values(event_counts))
        set_status_text!(frame, "Resized to $(get_width(size))x$(get_height(size))", 0)
        set_status_text!(frame, "Events: $total", 1)
    end

    wx_connect!(frame, KwxFFI.EVT_PAINT()) do event
        event_counts["paint"] += 1
        if event_counts["paint"] % 10 == 0
            println("🎨 Paint Event ($(event_counts["paint"]) total)")
        end
    end

    wx_connect!(frame, KwxFFI.EVT_LEFT_DOWN()) do event
        println("\n⚠️  Testing exception handling...")
        error("Intentional error to demonstrate error handling")
    end

    println("Event handlers registered:")
    println("  ✓ Close event")
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

    centre!(frame, KwxFFI.CENTRE())
    set_top_window(frame)
    show(frame)
end

println("\nApplication finished successfully!")
println("All event handlers were garbage-collected safely.")
