# Minimal Frame Example for Phase 4
# Demonstrates creating and displaying a wxFrame

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

println("Phase 4 Example: Minimal Frame")
println("=" ^ 50)

# Run the application
WxWidgets.run_app(app_name="Phase4Test") do
    # Create a frame
    frame = wxFrame(nothing, "Phase 4 - Window & Frame Demo",
                    size=(600, 400))

    # Create a status bar
    create_status_bar(frame, 1)
    set_status_text(frame, "Phase 4 implementation is working!")

    # Set the frame as the top window
    set_top_window(frame)

    # Center the frame on screen
    centre(frame)

    # Show the frame
    show_window(frame)

    println("Frame created and displayed!")
    println("  Title: ", get_label(frame))
    println("  Size: ", get_size(frame))
    println("  Position: ", get_position(frame))
    println("\nClose the window to exit.")
end

println("\nApplication exited cleanly.")
