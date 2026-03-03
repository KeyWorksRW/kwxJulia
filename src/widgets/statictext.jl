# High-level wxStaticText wrapper

"""
    wxStaticText

A static text label (non-editable text display).

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxStaticText C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct wxStaticText <: wxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    wxStaticText(parent::wxWindow, label::String; kwargs...) -> wxStaticText

Create a new static text label.

# Arguments
- `parent::wxWindow` - Parent window (required)
- `label::String` - Text to display

# Keyword Arguments
- `id::Int = KwxFFI.ID_ANY()` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = 0` - Style flags (e.g., KwxFFI.ST_NO_AUTORESIZE())

# Example
```julia
label = wxStaticText(frame, "Hello, World!")
```
"""
function wxStaticText(parent::wxWindow, label::String;
                      id::Integer = KwxFFI.ID_ANY(),
                      pos::Tuple{Int,Int} = (-1, -1),
                      size::Tuple{Int,Int} = (-1, -1),
                      style::Integer = 0)
    label_ws = wxString(label)

    ptr = KwxFFI.wxStaticText_Create(
        parent.ptr,
        Cint(id),
        label_ws.ptr,
        Cint(pos[1]), Cint(pos[2]),
        Cint(size[1]), Cint(size[2]),
        Cint(style)
    )

    delete!(label_ws)

    if ptr == C_NULL
        error("Failed to create wxStaticText")
    end

    st = wxStaticText(ptr, Any[])
    push!(parent.children, st)
    st
end
