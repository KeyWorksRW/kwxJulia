# High-level wxCheckBox wrapper

"""
    wxCheckBox

A checkbox control that can be toggled on and off.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxCheckBox C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct wxCheckBox <: wxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    wxCheckBox(parent::wxWindow, label::String; kwargs...) -> wxCheckBox

Create a new checkbox.

# Arguments
- `parent::wxWindow` - Parent window (required)
- `label::String` - Checkbox label text

# Keyword Arguments
- `id::Int = KwxFFI.ID_ANY()` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = 0` - Style flags

# Example
```julia
cb = wxCheckBox(frame, "Enable logging")
on_checkbox!(cb) do event
    println("Checked: ", is_checked(cb))
end
```
"""
function wxCheckBox(parent::wxWindow, label::String;
                    id::Integer = KwxFFI.ID_ANY(),
                    pos::Tuple{Int,Int} = (-1, -1),
                    size::Tuple{Int,Int} = (-1, -1),
                    style::Integer = 0)
    label_ws = wxString(label)

    ptr = KwxFFI.wxCheckBox_Create(
        parent.ptr,
        Cint(id),
        label_ws.ptr,
        Cint(pos[1]), Cint(pos[2]),
        Cint(size[1]), Cint(size[2]),
        Cint(style)
    )

    delete!(label_ws)

    if ptr == C_NULL
        error("Failed to create wxCheckBox")
    end

    cb = wxCheckBox(ptr, Any[])
    push!(parent.children, cb)
    cb
end

"""
    is_checked(cb::wxCheckBox) -> Bool

Returns true if the checkbox is checked.
"""
function is_checked(cb::wxCheckBox)
    KwxFFI.wxCheckBox_GetValue(cb.ptr) != 0
end

"""
    set_checked!(cb::wxCheckBox, checked::Bool)

Set the checkbox state.
"""
function set_checked!(cb::wxCheckBox, checked::Bool)
    KwxFFI.wxCheckBox_SetValue(cb.ptr, Cint(checked))
    nothing
end

"""
    on_checkbox!(handler::Function, cb::wxCheckBox)
    on_checkbox!(cb::wxCheckBox, handler::Function)

Connect a handler for checkbox toggle events.

# Example
```julia
on_checkbox!(checkbox) do event
    println("Checkbox toggled!")
end
```
"""
function on_checkbox!(cb::wxCheckBox, handler::Function)
    wx_connect!(cb, KwxFFI.wxEVT_CHECKBOX(), handler)
end

function on_checkbox!(handler::Function, cb::wxCheckBox)
    on_checkbox!(cb, handler)
end
