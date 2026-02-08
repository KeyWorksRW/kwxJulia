# High-level WxButton wrapper

"""
    WxButton

A command button which the user can press to trigger an action.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxButton C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct WxButton <: WxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    WxButton(parent::WxWindow, label::String; kwargs...) -> WxButton

Create a new button.

# Arguments
- `parent::WxWindow` - Parent window (required)
- `label::String` - Button text

# Keyword Arguments
- `id::Int = wxID_ANY[]` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = 0` - Button style flags

# Example
```julia
btn = WxButton(frame, "Click Me")
on_click!(btn) do event
    println("Button clicked!")
end
```
"""
function WxButton(parent::WxWindow, label::String;
                  id::Integer = wxID_ANY[],
                  pos::Tuple{Int,Int} = (-1, -1),
                  size::Tuple{Int,Int} = (-1, -1),
                  style::Integer = 0)
    label_ws = WxString(label)

    ptr = wxbutton_create(
        parent.ptr,
        id,
        label_ws.ptr,
        pos[1], pos[2],
        size[1], size[2],
        style
    )

    delete!(label_ws)

    if ptr == C_NULL
        error("Failed to create WxButton")
    end

    btn = WxButton(ptr, Any[])
    push!(parent.children, btn)
    btn
end

"""
    set_default!(button::WxButton)

Set this button as the default button in its top-level window.
The default button is activated when the user presses Enter.
"""
function set_default!(button::WxButton)
    wxbutton_setdefault(button.ptr)
    nothing
end

"""
    on_click!(handler::Function, button::WxButton)
    on_click!(button::WxButton, handler::Function)

Convenience function to connect a click event handler.

# Example
```julia
on_click!(button) do event
    println("Clicked!")
end
```
"""
function on_click!(button::WxButton, handler::Function)
    wx_connect!(button, wxEVT_BUTTON[], handler)
end

# do-block syntax: on_click!(handler, button)
function on_click!(handler::Function, button::WxButton)
    on_click!(button, handler)
end
