# Manual FFI wrappers for kwxApp_* functions.
# These are NOT in the generated KwxFFI code — they are part of the
# custom kwxApp C++ helper built into kwxFFI.dll.

using ..KwxFFI: libkwxFFI

# ── kwxApp lifecycle ──────────────────────────────────────────────
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
    ccall((:kwxApp_SetExitOnFrameDelete, libkwxFFI), Cvoid, (Cint,), Cint(flag))
end

function kwxapp_initallimagehandlers()
    ccall((:kwxApp_InitAllImageHandlers, libkwxFFI), Cvoid, ())
end

# ── kwxApp event binding ─────────────────────────────────────────
function kwxapp_connect(obj::Ptr{Cvoid}, first::Integer, last::Integer,
                        event_type::Integer, callback::Ptr{Cvoid},
                        user_data::Ptr{Cvoid} = C_NULL)
    ccall((:kwxApp_Connect, libkwxFFI), Cint,
          (Ptr{Cvoid}, Cint, Cint, Cint, Ptr{Cvoid}, Ptr{Cvoid}),
          obj, Cint(first), Cint(last), Cint(event_type), callback, user_data)
end

function kwxapp_disconnect(obj::Ptr{Cvoid}, first::Integer, last::Integer,
                           event_type::Integer)
    ccall((:kwxApp_Disconnect, libkwxFFI), Cint,
          (Ptr{Cvoid}, Cint, Cint, Cint),
          obj, Cint(first), Cint(last), Cint(event_type))
end
