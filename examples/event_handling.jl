# Event Handling Example
# Demonstrates wx_connect! with various event types.

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

println("Phase 5 Example: Event Handling")
println("=" ^ 50)
println("\nThis example demonstrates event handling:")
println("  - Close event handler")
println("  - Window size event handler")
println("\nClose the window to exit.")
println()

WxWidgets.run_app(app_name="EventDemo") do
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "Event Handling Demo",
                    -1, -1, 600, 400, KwxFFI.DEFAULT_FRAME_STYLE())

    create_status_bar(frame, 1, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Ready - try resizing or closing the window", 0)

    wx_connect!(frame, KwxFFI.EVT_CLOSE_WINDOW()) do event
        println("✓ Close event fired!")
        println("  Event pointer: ", event.ptr)
        set_status_text!(frame, "Window is closing...", 0)
        # Let the frame's default close handling destroy the window.
        skip!(event, true)
    end

    wx_connect!(frame, KwxFFI.EVT_SIZE()) do event
        println("✓ Size event fired!")
        size = get_size(frame)
        set_status_text!(frame,
                         "Window resized to $(get_width(size)) x $(get_height(size))", 0)
    end

    println("Event handlers connected:")
    println("  - wxEVT_CLOSE_WINDOW")
    println("  - wxEVT_SIZE")
    println("  Total closures stored: ", length(frame.closures))
    println()

    centre!(frame, KwxFFI.CENTRE())
    set_top_window(frame)
    show(frame)

    println("Frame is now visible. Waiting for events...")
end

println("\nApplication exited cleanly.")
println("Events were handled successfully!")
