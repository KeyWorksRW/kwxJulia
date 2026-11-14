# quick_main.jl — hand-written entry point for the kwxJulia quick test app.
#
# quick.wxui generates quick_mainframe.jl and quick_dlg.jl into this folder; the
# generated files only build the (hidden) forms. This file owns the application
# bootstrap: create the frame, show it, register it as the top window, run the
# modal dialog and then enter the event loop.
#
# Run from the repository root:
#   julia tests\quick\quick_main.jl
# or build/check only:
#   build_quick.cmd

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

using WxWidgets

# The generated wrappers are reached from Julia callbacks and from the event loop, which
# runs outside Julia, so the forms stay rooted for the whole run.
const ROOTS = Any[]

# Set by the frame's close handler when a close request arrives while the app-modal
# dialog is open.
const CLOSE_REQUESTED = Ref(false)

include(joinpath(@__DIR__, "quick_mainframe.jl"))

# The dialog form is only generated while quick.wxui still contains the dialog.
dialog_factory = nothing
dialog_path = joinpath(@__DIR__, "quick_dlg.jl")
if isfile(dialog_path)
    include(dialog_path)
    global dialog_factory = create_quick_dialog
end

run_app(app_name = "Quick") do
    frame = create_quick_main_frame(nothing)
    push!(ROOTS, frame)
    set_top_window(frame)
    show(frame)

    if dialog_factory !== nothing
        dialog = dialog_factory(frame)
        push!(ROOTS, dialog)
        # wxWidgets vetoes a frame close while an app-modal dialog is open
        # (wxTopLevelWindowBase::OnCloseWindow). A close request on the frame still has to
        # end the app, so record it, stop the handler chain and end the modal dialog. The
        # main loop has not started yet, so the exit is deferred to the first idle event.
        wx_connect!(frame, KwxFFI.EVT_CLOSE_WINDOW(), function (event)
            CLOSE_REQUESTED[] = true
            skip!(event, false)
            is_modal(dialog) && end_modal!(dialog, KwxFFI.ID_CANCEL())
            return nothing
        end)
        show_modal(dialog)
    end

    wx_connect!(frame, KwxFFI.EVT_IDLE(), function (event)
        CLOSE_REQUESTED[] && exit_app()
        skip!(event, true)
        return nothing
    end)
end
