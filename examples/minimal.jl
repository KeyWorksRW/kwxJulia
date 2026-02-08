# Minimal Julia wxWidgets Example
# Demonstrates basic app lifecycle with an empty window

# Add parent directory to load path to find WxWidgets module
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

using WxWidgets

# Run the application
run_app(app_name="Minimal Julia App") do
    # Create a frame (top-level window)
    frame = WxFrame(nothing, "Minimal Julia wxWidgets", size=(400, 300))

    # Set this frame as the top window
    set_top_window(frame)

    # Create a status bar
    create_status_bar(frame)
    set_status_text(frame, "Welcome to kwxJulia!")

    # Show the frame
    show_window(frame)
end
