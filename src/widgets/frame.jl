# High-level WxFrame wrapper

"""
    WxFrame

A top-level window that can contain other controls and has optional
menu bar, status bar, and toolbar.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxFrame C++ object
- `children::Vector{Any}` - Keeps child widgets alive (prevents GC)
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct WxFrame <: WxTopLevelWindow
    ptr::Ptr{Cvoid}
    children::Vector{Any}
    closures::Vector{Any}
end

"""
    WxFrame(parent, title::String; kwargs...) -> WxFrame

Create a new frame (top-level window).

# Arguments
- `parent::Union{WxWindow,Nothing}` - Parent window (usually nothing for top-level frames)
- `title::String` - Frame title displayed in title bar

# Keyword Arguments
- `id::Int = wxID_ANY[]` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = wxDEFAULT_FRAME_STYLE[]` - Window style flags

# Example
```julia
frame = WxFrame(nothing, "My Application", size=(800, 600))
show(frame)
```
"""
function WxFrame(parent::Union{WxWindow,Nothing}, title::String;
                 id::Integer = wxID_ANY[],
                 pos::Tuple{Int,Int} = (-1, -1),
                 size::Tuple{Int,Int} = (-1, -1),
                 style::Integer = wxDEFAULT_FRAME_STYLE[])
    parent_ptr = isnothing(parent) ? C_NULL : parent.ptr
    title_ws = WxString(title)

    ptr = wxframe_create(
        parent_ptr,
        id,
        title_ws.ptr,
        pos[1], pos[2],
        size[1], size[2],
        style
    )

    delete!(title_ws)

    if ptr == C_NULL
        error("Failed to create WxFrame")
    end

    WxFrame(ptr, Any[], Any[])
end

"""
    create_status_bar(frame::WxFrame, fields::Int = 1, style::Int = 0)

Create a status bar at the bottom of the frame.

# Arguments
- `fields::Int = 1` - Number of status bar fields
- `style::Int = 0` - Status bar style flags

# Returns
The status bar pointer (stored internally by wxWidgets).
"""
function create_status_bar(frame::WxFrame, fields::Integer = 1, style::Integer = 0)
    wxframe_createstatusbar(frame.ptr, fields, style)
    nothing
end

"""
    set_status_text(frame::WxFrame, text::String, field::Int = 0)

Set text in the status bar.

# Arguments
- `text::String` - Text to display
- `field::Int = 0` - Status bar field index (0-based)
"""
function set_status_text(frame::WxFrame, text::String, field::Integer = 0)
    wxframe_setstatustext(frame.ptr, text, field)
    nothing
end

"""
    push_status_text(frame::WxFrame, text::String, field::Int = 0)

Push text to the status bar (can be restored with pop_status_text).
"""
function push_status_text(frame::WxFrame, text::String, field::Integer = 0)
    wxframe_pushstatustext(frame.ptr, text, field)
    nothing
end

"""
    pop_status_text(frame::WxFrame, field::Int = 0)

Restore the previous status bar text.
"""
function pop_status_text(frame::WxFrame, field::Integer = 0)
    wxframe_popstatustext(frame.ptr, field)
    nothing
end

"""
    set_menu_bar(frame::WxFrame, menubar)

Set the menu bar for the frame.
"""
function set_menu_bar(frame::WxFrame, menubar)
    menubar_ptr = hasproperty(menubar, :ptr) ? menubar.ptr : menubar
    wxframe_setmenubar(frame.ptr, menubar_ptr)
    nothing
end

"""
    get_menu_bar(frame::WxFrame) -> Ptr{Cvoid}

Get the frame's menu bar pointer.
"""
function get_menu_bar(frame::WxFrame)
    wxframe_getmenubar(frame.ptr)
end

"""
    set_tool_bar(frame::WxFrame, toolbar)

Set the frame's toolbar.
"""
function set_tool_bar(frame::WxFrame, toolbar)
    toolbar_ptr = hasproperty(toolbar, :ptr) ? toolbar.ptr : toolbar
    wxframe_settoolbar(frame.ptr, toolbar_ptr)
    nothing
end

"""
    get_tool_bar(frame::WxFrame) -> Ptr{Cvoid}

Get the frame's toolbar pointer.
"""
function get_tool_bar(frame::WxFrame)
    wxframe_gettoolbar(frame.ptr)
end
