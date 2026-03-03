# High-level wxButton wrapper

"""
    wxButton

A command button which the user can press to trigger an action.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxButton C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct wxButton <: wxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    wxButton(parent::wxWindow, label::String; kwargs...) -> wxButton

Create a new button.

# Arguments
- `parent::wxWindow` - Parent window (required)
- `label::String` - Button text

# Keyword Arguments
- `id::Int = KwxFFI.ID_ANY()` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = 0` - Button style flags

# Example
```julia
btn = wxButton(frame, "Click Me")
on_click!(btn) do event
    println("Button clicked!")
end
```
"""
function wxButton(parent::wxWindow, label::String;
                  id::Integer = KwxFFI.ID_ANY(),
                  pos::Tuple{Int,Int} = (-1, -1),
                  size::Tuple{Int,Int} = (-1, -1),
                  style::Integer = 0)
    label_ws = wxString(label)

    ptr = KwxFFI.wxButton_Create(
        parent.ptr,
        Cint(id),
        label_ws.ptr,
        Cint(pos[1]), Cint(pos[2]),
        Cint(size[1]), Cint(size[2]),
        Cint(style)
    )

    delete!(label_ws)

    if ptr == C_NULL
        error("Failed to create wxButton")
    end

    btn = wxButton(ptr, Any[])
    push!(parent.children, btn)
    btn
end

"""
    set_default!(button::wxButton)

Set this button as the default button in its top-level window.
The default button is activated when the user presses Enter.
"""
function set_default!(button::wxButton)
    KwxFFI.wxButton_SetDefault(button.ptr)
    nothing
end

"""
    on_click!(handler::Function, button::wxButton)
    on_click!(button::wxButton, handler::Function)

Convenience function to connect a click event handler.

# Example
```julia
on_click!(button) do event
    println("Clicked!")
end
```
"""
function on_click!(button::wxButton, handler::Function)
    wx_connect!(button, KwxFFI.wxEVT_BUTTON(), handler)
end

# do-block syntax: on_click!(handler, button)
function on_click!(handler::Function, button::wxButton)
    on_click!(button, handler)
end
