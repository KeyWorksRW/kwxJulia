# probe_main.jl — hand-written probe entry for the kwxJulia probe lane.
#
# probe.wxui (../../quick/tests/quick_probe/probe.wxui) generates
# gen/probe_mainframe.jl and gen/probe_dlg.jl. Probe output never goes to
# tests/quick.

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

using WxWidgets

const ROOTS = Any[]

include(joinpath(@__DIR__, "gen", "probe_mainframe.jl"))
include(joinpath(@__DIR__, "gen", "probe_dlg.jl"))

run_app(app_name = "Probe") do
    frame = create_probe_main_frame(nothing)
    push!(ROOTS, frame)
    set_top_window(frame)
    show(frame)

    dialog = create_probe_dialog(frame)
    push!(ROOTS, dialog)
    # A frame close while the app-modal dialog is open is vetoed by wxWidgets, so end the
    # modal loop from the frame's own handler and let the generated handler do the rest.
    wx_connect!(frame, KwxFFI.EVT_CLOSE_WINDOW(), function (event)
        skip!(event, true)
        is_modal(dialog) && end_modal!(dialog, KwxFFI.ID_CANCEL())
        return nothing
    end)
    show_modal(dialog)
end
