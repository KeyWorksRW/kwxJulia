# Application layer for the GUI samples.
#
# kwxgen generates the complete widget surface into wx/: every class, its
# constructor, its accessors, the sizer operations, the constants, and the
# event primitives (`wxClosure` and `Base.bind`).  Samples call that surface
# directly.
#
# The two things kwxgen cannot generate are the GUI application lifecycle and
# the Julia callback trampoline.  Both are provided by src/cpp/kwxApp.cpp,
# which is compiled into kwxFFI.dll (see CMakeLists.txt), so this file is the
# only hand-written Julia that remains: the kwxApp_* declarations, the
# run_app/exit_app helpers, and the event bridge that turns a Julia Function
# into a generated wxClosure.

using ..KwxFFI: libkwxFFI

# ── kwxApp lifecycle (src/cpp/kwxApp.cpp) ─────────────────────────
function kwxapp_initialize()
    ccall((:kwxApp_Initialize, libkwxFFI), Cint,
          (Cint, Ptr{Ptr{Cchar}}), 0, C_NULL)
end

function kwxapp_mainloop()
    ccall((:kwxApp_MainLoop, libkwxFFI), Cint, ())
end

function kwxapp_exit()
    ccall((:kwxApp_ExitMainLoop, libkwxFFI), Cvoid, ())
end

function kwxapp_shutdown()
    ccall((:kwxApp_Shutdown, libkwxFFI), Cvoid, ())
end

# ── kwxApp configuration ─────────────────────────────────────────
function kwxapp_setappname(name::String)
    ccall((:kwxApp_SetAppName, libkwxFFI), Cvoid, (Cstring,), name)
end

function kwxapp_settopwindow(window::Ptr{Cvoid})
    ccall((:kwxApp_SetTopWindow, libkwxFFI), Cvoid, (Ptr{Cvoid},), window)
end

function kwxapp_setexitonframedelete(flag::Bool)
    ccall((:kwxApp_SetExitOnFrameDelete, libkwxFFI), Cint, (Cint,), Cint(flag))
end

function kwxapp_initallimagehandlers()
    ccall((:kwxApp_InitAllImageHandlers, libkwxFFI), Cvoid, ())
end

# ── Application entry point ──────────────────────────────────────
"""
    run_app(setup::Function; app_name::String="wxApp")

Initialize wxWidgets, call `setup()` (where the windows are created), then
enter the event loop.  `run_app` owns initialisation, the loop, and shutdown;
never call the loop functions yourself.
"""
function run_app(setup::Function; app_name::String="wxApp")
    result = kwxapp_initialize()
    result == 0 && error("Failed to initialize wxWidgets")

    kwxapp_setappname(app_name)
    kwxapp_initallimagehandlers()

    setup()

    return kwxapp_mainloop()
end

"""
    exit_app()

Signal the event loop to exit.
"""
exit_app() = kwxapp_exit()

"""
    set_top_window(window)

Set the top-level window.  The event loop exits when this window closes.
"""
set_top_window(window) = kwxapp_settopwindow(window.ptr)

"""
    set_exit_on_frame_delete(flag::Bool)

Control whether the app exits when the top window is deleted.  Default is true.
"""
set_exit_on_frame_delete(flag::Bool) = kwxapp_setexitonframedelete(flag)

# ── Event bridge ─────────────────────────────────────────────────
# kwxgen emits `wxClosure(fun, data)` and
# `Base.bind(obj, first, last, type, closure)`.  The C++ side wraps the closure
# in a wxCallback that owns it; Julia only has to keep the @cfunction pointer
# reachable, which is what the generated `closures` field on each window is
# for.

"""
    wx_connect!(window, event_type, handler; id=-1, last_id=id)
    wx_connect!(handler, window, event_type; id=-1, last_id=id)

Bind a Julia `handler(event::wxEvent)` to `event_type` on `window`.  Both
argument orders are accepted so `wx_connect!(window, type) do event ... end`
works.  Exceptions are caught and logged so they never cross into C++.
"""
function wx_connect!(window::wxWindow, event_type::Integer, handler::Function;
                     id::Integer = -1, last_id::Integer = id)
    function trampoline(::Ptr{Cvoid}, ::Ptr{Cvoid}, evt::Ptr{Cvoid})::Cvoid
        try
            # A null event is the wxClosure cleanup signal; there is no event
            # to deliver and no Julia state to release.
            evt == C_NULL || handler(wxEvent(evt))
        catch e
            @error "Exception in event handler" exception = (e, catch_backtrace())
        end
        return nothing
    end

    cfun = @cfunction($trampoline, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))
    closure = wxClosure(Base.unsafe_convert(Ptr{Cvoid}, cfun), C_NULL)
    Base.bind(window, id, last_id, event_type, closure)

    # wxWidgets keeps only the native closure alive; the Julia C function is
    # invisible to it, so root it on the window for the rest of the run.
    push!(window.closures, cfun)
    return nothing
end

wx_connect!(handler::Function, window::wxWindow, event_type::Integer;
            id::Integer = -1, last_id::Integer = id) =
    wx_connect!(window, event_type, handler; id = id, last_id = last_id)

"""
    wx_disconnect!(window, event_type; id=-1, last_id=id) -> Bool

Remove the handlers `wx_connect!` installed for this id range and event type.
Returns `true` when at least one handler was removed.
"""
function wx_disconnect!(window::wxWindow, event_type::Integer;
                        id::Integer = -1, last_id::Integer = id)
    return unbind(window, id, last_id, event_type) > 0
end
