# Frame with Status Bar Example
# Demonstrates frame with status bar and window manipulation.

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

println("Phase 4 Example: Frame with Status Bar")
println("=" ^ 50)

WxWidgets.run_app(app_name="StatusBarDemo") do
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "Status Bar Demo",
                    100, 100, 700, 500, KwxFFI.DEFAULT_FRAME_STYLE())

    create_status_bar(frame, 2, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Ready", 0)
    set_status_text!(frame, "Phase 4 Active", 1)

    size = get_size(frame)
    pos = get_position(frame)

    println("\nFrame created:")
    println("  Title: ", get_label(frame))
    println("  Size: $(get_width(size)) x $(get_height(size))")
    println("  Position: $(get_x(pos)), $(get_y(pos))")

    println("\nDemonstrating status text push/pop...")
    set_status_text!(frame, "Temporary message", 0)
    set_status_text!(frame, "Pushed temporary text", 1)

    set_label!(frame, "Status Bar Demo - Updated Title")

    centre!(frame, KwxFFI.CENTRE())

    set_top_window(frame)
    show(frame)

    println("\nWindow state:")
    println("  Shown: ", is_shown(frame))
    println("  Enabled: ", is_enabled(frame))

    println("\n✓ Frame is displayed. Close the window to exit.")
end

println("\nApplication finished.")
