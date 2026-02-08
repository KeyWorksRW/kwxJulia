# Event Handling Example
# Demonstrates wx_connect! with various event types

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
    # Create main frame
    frame = WxFrame(nothing, "Event Handling Demo",
                    size=(600, 400))

    # Create status bar for event feedback
    create_status_bar(frame, 1)
    set_status_text(frame, "Ready - try resizing or closing the window")

    # Connect close event handler
    wx_connect!(frame, wxEVT_CLOSE_WINDOW[]) do event
        println("✓ Close event fired!")
        println("  Event pointer: ", event.ptr)
        set_status_text(frame, "Window is closing...")
        # Note: We don't call Destroy or Veto here - let the default handling proceed
    end

    # Connect size event handler
    wx_connect!(frame, wxEVT_SIZE[]) do event
        println("✓ Size event fired!")
        size = get_size(frame)
        set_status_text(frame, "Window resized to $(size[1]) x $(size[2])")
    end

    println("Event handlers connected:")
    println("  - wxEVT_CLOSE_WINDOW")
    println("  - wxEVT_SIZE")
    println("  Total closures stored: ", length(frame.closures))
    println()

    # Show the frame
    centre(frame)
    set_top_window(frame)
    show_window(frame)

    println("Frame is now visible. Waiting for events...")
end

println("\nApplication exited cleanly.")
println("Events were handled successfully!")
