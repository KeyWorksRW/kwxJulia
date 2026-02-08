# Raw FFI declarations for wxWindow functions

"""
    wxwindow_show(window::Ptr{Cvoid}, show::Bool = true) -> Bool

Show or hide the window.
"""
function wxwindow_show(window::Ptr{Cvoid}, show::Bool = true)
    @ccall $(ffi(:wxWindow_Show))(window::Ptr{Cvoid}, show::Cint)::Cint
end

"""
    wxwindow_hide(window::Ptr{Cvoid})

Hide the window (equivalent to Show(false)).
"""
function wxwindow_hide(window::Ptr{Cvoid})
    @ccall $(ffi(:wxWindow_Hide))(window::Ptr{Cvoid})::Cint
end

"""
    wxwindow_setsize(window::Ptr{Cvoid}, x::Int, y::Int, width::Int, height::Int)

Set the window position and size.
"""
function wxwindow_setsize(window::Ptr{Cvoid}, x::Integer, y::Integer, width::Integer, height::Integer)
    @ccall $(ffi(:wxWindow_SetSize))(
        window::Ptr{Cvoid},
        x::Cint, y::Cint,
        width::Cint, height::Cint
    )::Cvoid
end

"""
    wxwindow_getsize(window::Ptr{Cvoid}) -> Tuple{Int, Int}

Get the window size (width, height).
"""
function wxwindow_getsize(window::Ptr{Cvoid})
    width = Ref{Cint}(0)
    height = Ref{Cint}(0)
    @ccall $(ffi(:wxWindow_GetSize))(
        window::Ptr{Cvoid},
        width::Ptr{Cint},
        height::Ptr{Cint}
    )::Cvoid
    (Int(width[]), Int(height[]))
end

"""
    wxwindow_setposition(window::Ptr{Cvoid}, x::Int, y::Int)

Set the window position.
"""
function wxwindow_setposition(window::Ptr{Cvoid}, x::Integer, y::Integer)
    @ccall $(ffi(:wxWindow_SetPosition))(
        window::Ptr{Cvoid},
        x::Cint, y::Cint
    )::Cvoid
end

"""
    wxwindow_getposition(window::Ptr{Cvoid}) -> Tuple{Int, Int}

Get the window position (x, y).
"""
function wxwindow_getposition(window::Ptr{Cvoid})
    x = Ref{Cint}(0)
    y = Ref{Cint}(0)
    @ccall $(ffi(:wxWindow_GetPosition))(
        window::Ptr{Cvoid},
        x::Ptr{Cint},
        y::Ptr{Cint}
    )::Cvoid
    (Int(x[]), Int(y[]))
end

"""
    wxwindow_setlabel(window::Ptr{Cvoid}, label::String)

Set the window label/title.
"""
function wxwindow_setlabel(window::Ptr{Cvoid}, label::String)
    label_ws = WxString(label)
    @ccall $(ffi(:wxWindow_SetLabel))(
        window::Ptr{Cvoid},
        label_ws.ptr::Ptr{Cvoid}
    )::Cvoid
    delete!(label_ws)
end

"""
    wxwindow_getlabel(window::Ptr{Cvoid}) -> String

Get the window label/title.
"""
function wxwindow_getlabel(window::Ptr{Cvoid})
    ws_ptr = @ccall $(ffi(:wxWindow_GetLabel))(window::Ptr{Cvoid})::Ptr{Cvoid}
    if ws_ptr == C_NULL
        return ""
    end
    result = String(WxString(ws_ptr))
    @ccall $(ffi(:wxString_Delete))(ws_ptr::Ptr{Cvoid})::Cvoid
    result
end

"""
    wxwindow_setsizer(window::Ptr{Cvoid}, sizer::Ptr{Cvoid}, delete_old::Bool = true)

Set the window's sizer for layout management.
"""
function wxwindow_setsizer(window::Ptr{Cvoid}, sizer::Ptr{Cvoid}, delete_old::Bool = true)
    @ccall $(ffi(:wxWindow_SetSizer))(
        window::Ptr{Cvoid},
        sizer::Ptr{Cvoid},
        delete_old::Cint
    )::Cvoid
end

"""
    wxwindow_layout(window::Ptr{Cvoid})

Layout the window (recalculates sizer layout).
"""
function wxwindow_layout(window::Ptr{Cvoid})
    @ccall $(ffi(:wxWindow_Layout))(window::Ptr{Cvoid})::Cint
end

"""
    wxwindow_refresh(window::Ptr{Cvoid}, erase_background::Bool = true)

Force the window to redraw.
"""
function wxwindow_refresh(window::Ptr{Cvoid}, erase_background::Bool = true)
    @ccall $(ffi(:wxWindow_Refresh))(
        window::Ptr{Cvoid},
        erase_background::Cint
    )::Cvoid
end

"""
    wxwindow_update(window::Ptr{Cvoid})

Process pending paint events immediately.
"""
function wxwindow_update(window::Ptr{Cvoid})
    @ccall $(ffi(:wxWindow_Update))(window::Ptr{Cvoid})::Cvoid
end

"""
    wxwindow_close(window::Ptr{Cvoid}, force::Bool = false) -> Bool

Close the window. Returns true if the window was closed.
"""
function wxwindow_close(window::Ptr{Cvoid}, force::Bool = false)
    @ccall $(ffi(:wxWindow_Close))(
        window::Ptr{Cvoid},
        force::Cint
    )::Cint
end

"""
    wxwindow_destroy(window::Ptr{Cvoid}) -> Bool

Destroy the window immediately. Use with caution.
"""
function wxwindow_destroy(window::Ptr{Cvoid})
    @ccall $(ffi(:wxWindow_Destroy))(window::Ptr{Cvoid})::Cint
end

"""
    wxwindow_enable(window::Ptr{Cvoid}, enable::Bool = true) -> Bool

Enable or disable the window.
"""
function wxwindow_enable(window::Ptr{Cvoid}, enable::Bool = true)
    @ccall $(ffi(:wxWindow_Enable))(
        window::Ptr{Cvoid},
        enable::Cint
    )::Cint
end

"""
    wxwindow_isenabled(window::Ptr{Cvoid}) -> Bool

Check if the window is enabled.
"""
function wxwindow_isenabled(window::Ptr{Cvoid})
    (@ccall $(ffi(:wxWindow_IsEnabled))(window::Ptr{Cvoid})::Cint) != 0
end

"""
    wxwindow_isshown(window::Ptr{Cvoid}) -> Bool

Check if the window is shown.
"""
function wxwindow_isshown(window::Ptr{Cvoid})
    (@ccall $(ffi(:wxWindow_IsShown))(window::Ptr{Cvoid})::Cint) != 0
end

"""
    wxwindow_setfocus(window::Ptr{Cvoid})

Set keyboard focus to this window.
"""
function wxwindow_setfocus(window::Ptr{Cvoid})
    @ccall $(ffi(:wxWindow_SetFocus))(window::Ptr{Cvoid})::Cvoid
end

"""
    wxwindow_centre(window::Ptr{Cvoid}, direction::Int = 3)

Center the window. Direction: 1=horizontal, 2=vertical, 3=both.
"""
function wxwindow_centre(window::Ptr{Cvoid}, direction::Integer = 3)
    @ccall $(ffi(:wxWindow_Centre))(
        window::Ptr{Cvoid},
        direction::Cint
    )::Cvoid
end
