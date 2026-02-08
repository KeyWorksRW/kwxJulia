# Raw FFI declarations for kwxApp_* functions
# These call into kwxFFI.dll (kwxApp.cpp is compiled into kwxFFI target)

"""
    kwxapp_initialize() -> Int32

Initialize wxWidgets. Must be called once before any wx functions.
Returns non-zero on success, 0 on failure.
"""
function kwxapp_initialize()
    @ccall $(ffi(:kwxApp_Initialize))(0::Cint, C_NULL::Ptr{Ptr{Cchar}})::Cint
end

"""
    kwxapp_mainloop() -> Int32

Run the event loop. Blocks until exit is signaled.
Returns exit code.
"""
function kwxapp_mainloop()
    @ccall $(ffi(:kwxApp_MainLoop))()::Cint
end

"""
    kwxapp_exit()

Signal the event loop to exit.
"""
function kwxapp_exit()
    @ccall $(ffi(:kwxApp_ExitMainLoop))()::Cvoid
end

"""
    kwxapp_shutdown()

Optional cleanup. Called automatically at program exit in most cases.
"""
function kwxapp_shutdown()
    @ccall $(ffi(:kwxApp_Shutdown))()::Cvoid
end

"""
    kwxapp_setappname(name::String)

Set the application name.
"""
function kwxapp_setappname(name::String)
    @ccall $(ffi(:kwxApp_SetAppName))(name::Cstring)::Cvoid
end

"""
    kwxapp_settopwindow(window::Ptr{Cvoid})

Set the top-level window. The event loop exits when this window closes
(if exit-on-frame-delete is true).
"""
function kwxapp_settopwindow(window::Ptr{Cvoid})
    @ccall $(ffi(:kwxApp_SetTopWindow))(window::Ptr{Cvoid})::Cvoid
end

"""
    kwxapp_setexitonframedelete(flag::Bool)

Control whether the app exits when the top window is deleted.
Default is true.
"""
function kwxapp_setexitonframedelete(flag::Bool)
    @ccall $(ffi(:kwxApp_SetExitOnFrameDelete))(flag::Cint)::Cvoid
end

"""
    kwxapp_initallimagehandlers()

Enable support for PNG, JPEG, and other image formats.
"""
function kwxapp_initallimagehandlers()
    @ccall $(ffi(:kwxApp_InitAllImageHandlers))()::Cvoid
end
