# Raw FFI declarations for wxFrame functions

"""
    wxframe_create(parent::Ptr{Cvoid}, id::Int, title::Ptr{Cvoid},
                   x::Int, y::Int, width::Int, height::Int, style::Int) -> Ptr{Cvoid}

Create a new wxFrame instance.
"""
function wxframe_create(parent::Ptr{Cvoid}, id::Integer, title::Ptr{Cvoid},
                        x::Integer, y::Integer, width::Integer, height::Integer, style::Integer)
    @ccall $(ffi(:wxFrame_Create))(
        parent::Ptr{Cvoid},
        id::Cint,
        title::Ptr{Cvoid},
        x::Cint, y::Cint,
        width::Cint, height::Cint,
        style::Cint
    )::Ptr{Cvoid}
end

"""
    wxframe_setmenubar(frame::Ptr{Cvoid}, menubar::Ptr{Cvoid})

Set the menu bar for the frame.
"""
function wxframe_setmenubar(frame::Ptr{Cvoid}, menubar::Ptr{Cvoid})
    @ccall $(ffi(:wxFrame_SetMenuBar))(
        frame::Ptr{Cvoid},
        menubar::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxframe_getmenubar(frame::Ptr{Cvoid}) -> Ptr{Cvoid}

Get the frame's menu bar.
"""
function wxframe_getmenubar(frame::Ptr{Cvoid})
    @ccall $(ffi(:wxFrame_GetMenuBar))(frame::Ptr{Cvoid})::Ptr{Cvoid}
end

"""
    wxframe_createstatusbar(frame::Ptr{Cvoid}, number::Int = 1, style::Int = 0) -> Ptr{Cvoid}

Create a status bar at the bottom of the frame.
"""
function wxframe_createstatusbar(frame::Ptr{Cvoid}, number::Integer = 1, style::Integer = 0)
    @ccall $(ffi(:wxFrame_CreateStatusBar))(
        frame::Ptr{Cvoid},
        number::Cint,
        style::Cint
    )::Ptr{Cvoid}
end

"""
    wxframe_getstatusbar(frame::Ptr{Cvoid}) -> Ptr{Cvoid}

Get the frame's status bar.
"""
function wxframe_getstatusbar(frame::Ptr{Cvoid})
    @ccall $(ffi(:wxFrame_GetStatusBar))(frame::Ptr{Cvoid})::Ptr{Cvoid}
end

"""
    wxframe_setstatustext(frame::Ptr{Cvoid}, text::String, field::Int = 0)

Set text in the status bar.
"""
function wxframe_setstatustext(frame::Ptr{Cvoid}, text::String, field::Integer = 0)
    text_ws = WxString(text)
    @ccall $(ffi(:wxFrame_SetStatusText))(
        frame::Ptr{Cvoid},
        text_ws.ptr::Ptr{Cvoid},
        field::Cint
    )::Cvoid
    delete!(text_ws)
end

"""
    wxframe_pushstatustext(frame::Ptr{Cvoid}, text::String, field::Int = 0)

Push text to the status bar (can be popped later).
"""
function wxframe_pushstatustext(frame::Ptr{Cvoid}, text::String, field::Integer = 0)
    text_ws = WxString(text)
    @ccall $(ffi(:wxFrame_PushStatusText))(
        frame::Ptr{Cvoid},
        text_ws.ptr::Ptr{Cvoid},
        field::Cint
    )::Cvoid
    delete!(text_ws)
end

"""
    wxframe_popstatustext(frame::Ptr{Cvoid}, field::Int = 0)

Pop status bar text (restore previous text).
"""
function wxframe_popstatustext(frame::Ptr{Cvoid}, field::Integer = 0)
    @ccall $(ffi(:wxFrame_PopStatusText))(
        frame::Ptr{Cvoid},
        field::Cint
    )::Cvoid
end

"""
    wxframe_settoolbar(frame::Ptr{Cvoid}, toolbar::Ptr{Cvoid})

Set the frame's toolbar.
"""
function wxframe_settoolbar(frame::Ptr{Cvoid}, toolbar::Ptr{Cvoid})
    @ccall $(ffi(:wxFrame_SetToolBar))(
        frame::Ptr{Cvoid},
        toolbar::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxframe_gettoolbar(frame::Ptr{Cvoid}) -> Ptr{Cvoid}

Get the frame's toolbar.
"""
function wxframe_gettoolbar(frame::Ptr{Cvoid})
    @ccall $(ffi(:wxFrame_GetToolBar))(frame::Ptr{Cvoid})::Ptr{Cvoid}
end
