# High-level Window wrapper functions
# These operate on any wxWindow subtype

# Custom REPL display for wxWindow types
function Base.show(io::IO, ::MIME"text/plain", window::wxWindow)
    print(io, "$(typeof(window))(ptr=$(window.ptr))")
end

"""
    show_window(window::wxWindow)

Show the window. Use hide() to hide.
"""
function show_window(window::wxWindow)
    KwxFFI.wxWindow_Show(window.ptr)
    nothing
end

"""
    hide(window::wxWindow)

Hide the window.
"""
function hide(window::wxWindow)
    KwxFFI.wxWindow_Hide(window.ptr)
    nothing
end

"""
    close(window::wxWindow, force::Bool = false) -> Bool

Close the window. Returns true if the window was closed.
"""
function Base.close(window::wxWindow, force::Bool = false)
    KwxFFI.wxWindow_Close(window.ptr, Cint(force)) != 0
end

"""
    destroy!(window::wxWindow)

Destroy the window immediately. Use with caution - window should not be used after this.
"""
function destroy!(window::wxWindow)
    KwxFFI.wxWindow_Destroy(window.ptr)
    nothing
end

"""
    set_size(window::wxWindow, x::Int, y::Int, width::Int, height::Int; size_flags::Int=0)

Set the window position and size.
"""
function set_size(window::wxWindow, x::Integer, y::Integer,
                  width::Integer, height::Integer; size_flags::Integer = 0)
    KwxFFI.wxWindow_SetSize(window.ptr, Cint(x), Cint(y), Cint(width), Cint(height), Cint(size_flags))
    nothing
end

"""
    get_size(window::wxWindow) -> Tuple{Int, Int}

Get the window size as (width, height).
"""
function get_size(window::wxWindow)
    sz = KwxFFI.wxWindow_GetSize(window.ptr)
    if sz == C_NULL
        return (0, 0)
    end
    w = Int(KwxFFI.wxSize_GetWidth(sz))
    h = Int(KwxFFI.wxSize_GetHeight(sz))
    KwxFFI.wxSize_Delete(sz)
    return (w, h)
end

"""
    set_position(window::wxWindow, x::Int, y::Int; flags::Int=0)

Set the window position.
"""
function set_position(window::wxWindow, x::Integer, y::Integer; flags::Integer = 0)
    KwxFFI.wxWindow_Move(window.ptr, Cint(x), Cint(y), Cint(flags))
    nothing
end

"""
    get_position(window::wxWindow) -> Tuple{Int, Int}

Get the window position as (x, y).
"""
function get_position(window::wxWindow)
    pt = KwxFFI.wxWindow_GetPosition(window.ptr)
    if pt == C_NULL
        return (0, 0)
    end
    x = Int(KwxFFI.wxPoint_GetX(pt))
    y = Int(KwxFFI.wxPoint_GetY(pt))
    KwxFFI.wxPoint_Destroy(pt)
    return (x, y)
end

"""
    set_label(window::wxWindow, label::String)

Set the window label/title.
"""
function set_label(window::wxWindow, label::String)
    ws = wxString(label)
    KwxFFI.wxWindow_SetLabel(window.ptr, ws.ptr)
    delete!(ws)
    nothing
end

"""
    get_label(window::wxWindow) -> String

Get the window label/title.
"""
function get_label(window::wxWindow)
    ws_ptr = KwxFFI.wxWindow_GetLabel(window.ptr)
    _wx_get_string(ws_ptr)
end

"""
    set_sizer(window::wxWindow, sizer, delete_old::Bool = true)

Set the window's sizer for layout management.
"""
function set_sizer(window::wxWindow, sizer, delete_old::Bool = true)
    sizer_ptr = hasproperty(sizer, :ptr) ? sizer.ptr : sizer
    KwxFFI.wxWindow_SetSizer(window.ptr, sizer_ptr, Cint(delete_old))
    nothing
end

"""
    layout(window::wxWindow)

Layout the window (recalculates sizer layout).
"""
function layout(window::wxWindow)
    KwxFFI.wxWindow_Layout(window.ptr)
    nothing
end

"""
    refresh(window::wxWindow, erase_background::Bool = true)

Force the window to redraw.
"""
function refresh(window::wxWindow, erase_background::Bool = true)
    KwxFFI.wxWindow_Refresh(window.ptr, Cint(erase_background))
    nothing
end

"""
    update(window::wxWindow)

Process pending paint events immediately.
"""
function update(window::wxWindow)
    KwxFFI.wxWindow_Update(window.ptr)
    nothing
end

"""
    enable(window::wxWindow)

Enable the window. Use disable() to disable.
"""
function enable(window::wxWindow)
    KwxFFI.wxWindow_Enable(window.ptr)
    nothing
end

"""
    disable(window::wxWindow)

Disable the window.
"""
function disable(window::wxWindow)
    KwxFFI.wxWindow_Disable(window.ptr)
    nothing
end

"""
    is_enabled(window::wxWindow) -> Bool

Check if the window is enabled.
"""
function is_enabled(window::wxWindow)
    KwxFFI.wxWindow_IsEnabled(window.ptr) != 0
end

"""
    is_shown(window::wxWindow) -> Bool

Check if the window is shown.
"""
function is_shown(window::wxWindow)
    KwxFFI.wxWindow_IsShown(window.ptr) != 0
end

"""
    set_focus(window::wxWindow)

Set keyboard focus to this window.
"""
function set_focus(window::wxWindow)
    KwxFFI.wxWindow_SetFocus(window.ptr)
    nothing
end

"""
    center(window::wxWindow; horizontal::Bool = true, vertical::Bool = true)

Center the window on screen or within its parent.
"""
function center(window::wxWindow; horizontal::Bool = true, vertical::Bool = true)
    direction = (horizontal ? 1 : 0) | (vertical ? 2 : 0)
    KwxFFI.wxWindow_Center(window.ptr, Cint(direction))
    nothing
end

# Alias for British spelling
const centre = center
