# Minimal Julia wxWidgets Example
# Demonstrates basic app lifecycle with an empty window.
#
# Every widget call below comes from the generated wx/ tree (kwxgen); the only
# hand-written API used is the application layer in src/core/kwxapp.jl.

push!(LOAD_PATH, joinpath(@__DIR__, ".."))

using WxWidgets

run_app(app_name="Minimal Julia App") do
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "Minimal Julia wxWidgets",
                    -1, -1, 400, 300, KwxFFI.DEFAULT_FRAME_STYLE())

    set_top_window(frame)

    create_status_bar(frame, 1, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Welcome to kwxJulia!", 0)

    show(frame)
end
