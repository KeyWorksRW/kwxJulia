# High-level Window wrapper functions
# These operate on any WxWindow subtype

# Custom REPL display for WxWindow types
function Base.show(io::IO, ::MIME"text/plain", window::WxWindow)
    print(io, "$(typeof(window))(ptr=$(window.ptr))")
end

"""
    show_window(window::WxWindow, show_flag::Bool = true)

Show or hide the window.
"""
function show_window(window::WxWindow, show_flag::Bool = true)
    wxwindow_show(window.ptr, show_flag)
    nothing
end

"""
    hide(window::WxWindow)

Hide the window.
"""
function hide(window::WxWindow)
    wxwindow_hide(window.ptr)
    nothing
end

"""
    close(window::WxWindow, force::Bool = false) -> Bool

Close the window. Returns true if the window was closed.
"""
function Base.close(window::WxWindow, force::Bool = false)
    wxwindow_close(window.ptr, force) != 0
end

"""
    destroy!(window::WxWindow)

Destroy the window immediately. Use with caution - window should not be used after this.
"""
function destroy!(window::WxWindow)
    wxwindow_destroy(window.ptr)
    nothing
end

"""
    set_size(window::WxWindow, x::Int, y::Int, width::Int, height::Int)

Set the window position and size.
"""
function set_size(window::WxWindow, x::Integer, y::Integer, width::Integer, height::Integer)
    wxwindow_setsize(window.ptr, x, y, width, height)
    nothing
end

"""
    get_size(window::WxWindow) -> Tuple{Int, Int}

Get the window size as (width, height).
"""
function get_size(window::WxWindow)
    wxwindow_getsize(window.ptr)
end

"""
    set_position(window::WxWindow, x::Int, y::Int)

Set the window position.
"""
function set_position(window::WxWindow, x::Integer, y::Integer)
    wxwindow_setposition(window.ptr, x, y)
    nothing
end

"""
    get_position(window::WxWindow) -> Tuple{Int, Int}

Get the window position as (x, y).
"""
function get_position(window::WxWindow)
    wxwindow_getposition(window.ptr)
end

"""
    set_label(window::WxWindow, label::String)

Set the window label/title.
"""
function set_label(window::WxWindow, label::String)
    wxwindow_setlabel(window.ptr, label)
    nothing
end

"""
    get_label(window::WxWindow) -> String

Get the window label/title.
"""
function get_label(window::WxWindow)
    wxwindow_getlabel(window.ptr)
end

"""
    set_sizer(window::WxWindow, sizer, delete_old::Bool = true)

Set the window's sizer for layout management.
"""
function set_sizer(window::WxWindow, sizer, delete_old::Bool = true)
    sizer_ptr = hasproperty(sizer, :ptr) ? sizer.ptr : sizer
    wxwindow_setsizer(window.ptr, sizer_ptr, delete_old)
    nothing
end

"""
    layout(window::WxWindow)

Layout the window (recalculates sizer layout).
"""
function layout(window::WxWindow)
    wxwindow_layout(window.ptr)
    nothing
end

"""
    refresh(window::WxWindow, erase_background::Bool = true)

Force the window to redraw.
"""
function refresh(window::WxWindow, erase_background::Bool = true)
    wxwindow_refresh(window.ptr, erase_background)
    nothing
end

"""
    update(window::WxWindow)

Process pending paint events immediately.
"""
function update(window::WxWindow)
    wxwindow_update(window.ptr)
    nothing
end

"""
    enable(window::WxWindow, enable::Bool = true)

Enable or disable the window.
"""
function enable(window::WxWindow, enable::Bool = true)
    wxwindow_enable(window.ptr, enable)
    nothing
end

"""
    is_enabled(window::WxWindow) -> Bool

Check if the window is enabled.
"""
function is_enabled(window::WxWindow)
    wxwindow_isenabled(window.ptr)
end

"""
    is_shown(window::WxWindow) -> Bool

Check if the window is shown.
"""
function is_shown(window::WxWindow)
    wxwindow_isshown(window.ptr)
end

"""
    set_focus(window::WxWindow)

Set keyboard focus to this window.
"""
function set_focus(window::WxWindow)
    wxwindow_setfocus(window.ptr)
    nothing
end

"""
    centre(window::WxWindow; horizontal::Bool = true, vertical::Bool = true)

Center the window on screen or within its parent.
"""
function centre(window::WxWindow; horizontal::Bool = true, vertical::Bool = true)
    direction = (horizontal ? 1 : 0) | (vertical ? 2 : 0)
    wxwindow_centre(window.ptr, direction)
    nothing
end

# Alias for American spelling
center = centre
