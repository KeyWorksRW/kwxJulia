# Minimal Frame Example for Phase 4
# Demonstrates creating and displaying a wxFrame using the generated wx/ API.

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

println("Phase 4 Example: Minimal Frame")
println("=" ^ 50)

WxWidgets.run_app(app_name="Phase4Test") do
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "Phase 4 - Window & Frame Demo",
                    -1, -1, 600, 400, KwxFFI.DEFAULT_FRAME_STYLE())

    create_status_bar(frame, 1, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Phase 4 implementation is working!", 0)

    set_top_window(frame)
    centre!(frame, KwxFFI.CENTRE())
    show(frame)

    println("Frame created and displayed!")
    println("  Title: ", get_label(frame))
    println("  Size: ", get_width(get_size(frame)), " x ", get_height(get_size(frame)))
    println("  Position: ", get_x(get_position(frame)), ", ", get_y(get_position(frame)))
    println("\nClose the window to exit.")
end

println("\nApplication exited cleanly.")
