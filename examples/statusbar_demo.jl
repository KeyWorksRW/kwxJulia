# Frame with Status Bar Example
# Demonstrates frame with status bar and window manipulation

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

println("Phase 4 Example: Frame with Status Bar")
println("=" ^ 50)

WxWidgets.run_app(app_name="StatusBarDemo") do
    # Create main frame
    frame = WxFrame(nothing, "Status Bar Demo",
                    size=(700, 500),
                    pos=(100, 100))

    # Create status bar with 2 fields
    create_status_bar(frame, 2)
    set_status_text(frame, "Ready", 0)
    set_status_text(frame, "Phase 4 Active", 1)

    # Get frame details
    size = get_size(frame)
    pos = get_position(frame)

    println("\nFrame created:")
    println("  Title: ", get_label(frame))
    println("  Size: $(size[1]) x $(size[2])")
    println("  Position: $(pos[1]), $(pos[2])")

    # Demonstrate status bar push/pop
    println("\nDemonstrating status text push/pop...")
    push_status_text(frame, "Temporary message", 0)
    set_status_text(frame, "Pushed temporary text", 1)

    # Update frame label
    set_label(frame, "Status Bar Demo - Updated Title")

    # Center the frame
    centre(frame)

    # Set as top window and show
    set_top_window(frame)
    show_window(frame)

    # Verify window state
    println("\nWindow state:")
    println("  Shown: ", is_shown(frame))
    println("  Enabled: ", is_enabled(frame))

    println("\n✓ Frame is displayed. Close the window to exit.")
end

println("\nApplication finished.")
