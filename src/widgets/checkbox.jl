# High-level WxCheckBox wrapper

"""
    WxCheckBox

A checkbox control that can be toggled on and off.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxCheckBox C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct WxCheckBox <: WxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    WxCheckBox(parent::WxWindow, label::String; kwargs...) -> WxCheckBox

Create a new checkbox.

# Arguments
- `parent::WxWindow` - Parent window (required)
- `label::String` - Checkbox label text

# Keyword Arguments
- `id::Int = wxID_ANY[]` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = 0` - Style flags

# Example
```julia
cb = WxCheckBox(frame, "Enable logging")
on_checkbox!(cb) do event
    println("Checked: ", is_checked(cb))
end
```
"""
function WxCheckBox(parent::WxWindow, label::String;
                    id::Integer = wxID_ANY[],
                    pos::Tuple{Int,Int} = (-1, -1),
                    size::Tuple{Int,Int} = (-1, -1),
                    style::Integer = 0)
    label_ws = WxString(label)

    ptr = wxcheckbox_create(
        parent.ptr,
        id,
        label_ws.ptr,
        pos[1], pos[2],
        size[1], size[2],
        style
    )

    delete!(label_ws)

    if ptr == C_NULL
        error("Failed to create WxCheckBox")
    end

    cb = WxCheckBox(ptr, Any[])
    push!(parent.children, cb)
    cb
end

"""
    is_checked(cb::WxCheckBox) -> Bool

Returns true if the checkbox is checked.
"""
function is_checked(cb::WxCheckBox)
    wxcheckbox_getvalue(cb.ptr) != 0
end

"""
    set_checked!(cb::WxCheckBox, checked::Bool)

Set the checkbox state.
"""
function set_checked!(cb::WxCheckBox, checked::Bool)
    wxcheckbox_setvalue(cb.ptr, checked)
    nothing
end

"""
    on_checkbox!(handler::Function, cb::WxCheckBox)
    on_checkbox!(cb::WxCheckBox, handler::Function)

Connect a handler for checkbox toggle events.

# Example
```julia
on_checkbox!(checkbox) do event
    println("Checkbox toggled!")
end
```
"""
function on_checkbox!(cb::WxCheckBox, handler::Function)
    wx_connect!(cb, wxEVT_CHECKBOX[], handler)
end

function on_checkbox!(handler::Function, cb::WxCheckBox)
    on_checkbox!(cb, handler)
end
