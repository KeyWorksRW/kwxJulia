# High-level wxFrame wrapper

"""
    wxFrame

A top-level window that can contain other controls and has optional
menu bar, status bar, and toolbar.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxFrame C++ object
- `children::Vector{Any}` - Keeps child widgets alive (prevents GC)
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct wxFrame <: wxTopLevelWindow
    ptr::Ptr{Cvoid}
    children::Vector{Any}
    closures::Vector{Any}
end

"""
    wxFrame(parent, title::String; kwargs...) -> wxFrame

Create a new frame (top-level window).

# Arguments
- `parent::Union{wxWindow,Nothing}` - Parent window (usually nothing for top-level frames)
- `title::String` - Frame title displayed in title bar

# Keyword Arguments
- `id::Int = KwxFFI.ID_ANY()` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = KwxFFI.DEFAULT_FRAME_STYLE()` - Window style flags

# Example
```julia
frame = wxFrame(nothing, "My Application", size=(800, 600))
show_window(frame)
```
"""
function wxFrame(parent::Union{wxWindow,Nothing}, title::String;
                 id::Integer = KwxFFI.ID_ANY(),
                 pos::Tuple{Int,Int} = (-1, -1),
                 size::Tuple{Int,Int} = (-1, -1),
                 style::Integer = KwxFFI.DEFAULT_FRAME_STYLE())
    parent_ptr = isnothing(parent) ? C_NULL : parent.ptr
    title_ws = wxString(title)

    ptr = KwxFFI.wxFrame_Create(
        parent_ptr,
        Cint(id),
        title_ws.ptr,
        Cint(pos[1]), Cint(pos[2]),
        Cint(size[1]), Cint(size[2]),
        Cint(style)
    )

    delete!(title_ws)

    if ptr == C_NULL
        error("Failed to create wxFrame")
    end

    wxFrame(ptr, Any[], Any[])
end

"""
    create_status_bar(frame::wxFrame, fields::Int = 1, style::Int = 0)

Create a status bar at the bottom of the frame.

# Arguments
- `fields::Int = 1` - Number of status bar fields
- `style::Int = 0` - Status bar style flags

# Returns
The status bar pointer (stored internally by wxWidgets).
"""
function create_status_bar(frame::wxFrame, fields::Integer = 1, style::Integer = 0)
    KwxFFI.wxFrame_CreateStatusBar(frame.ptr, Cint(fields), Cint(style))
    nothing
end

"""
    set_status_text(frame::wxFrame, text::String, field::Int = 0)

Set text in the status bar.

# Arguments
- `text::String` - Text to display
- `field::Int = 0` - Status bar field index (0-based)
"""
function set_status_text(frame::wxFrame, text::String, field::Integer = 0)
    ws = wxString(text)
    KwxFFI.wxFrame_SetStatusText(frame.ptr, ws.ptr, Cint(field))
    delete!(ws)
    nothing
end

"""
    set_menu_bar(frame::wxFrame, menubar)

Set the menu bar for the frame.
"""
function set_menu_bar(frame::wxFrame, menubar)
    menubar_ptr = hasproperty(menubar, :ptr) ? menubar.ptr : menubar
    KwxFFI.wxFrame_SetMenuBar(frame.ptr, menubar_ptr)
    nothing
end

"""
    get_menu_bar(frame::wxFrame) -> Ptr{Cvoid}

Get the frame's menu bar pointer.
"""
function get_menu_bar(frame::wxFrame)
    KwxFFI.wxFrame_GetMenuBar(frame.ptr)
end

"""
    set_tool_bar(frame::wxFrame, toolbar)

Set the frame's toolbar.
"""
function set_tool_bar(frame::wxFrame, toolbar)
    toolbar_ptr = hasproperty(toolbar, :ptr) ? toolbar.ptr : toolbar
    KwxFFI.wxFrame_SetToolBar(frame.ptr, toolbar_ptr)
    nothing
end

"""
    get_tool_bar(frame::wxFrame) -> Ptr{Cvoid}

Get the frame's toolbar pointer.
"""
function get_tool_bar(frame::wxFrame)
    KwxFFI.wxFrame_GetToolBar(frame.ptr)
end
