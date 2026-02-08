# High-level WxStaticText wrapper

"""
    WxStaticText

A static text label (non-editable text display).

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxStaticText C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct WxStaticText <: WxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    WxStaticText(parent::WxWindow, label::String; kwargs...) -> WxStaticText

Create a new static text label.

# Arguments
- `parent::WxWindow` - Parent window (required)
- `label::String` - Text to display

# Keyword Arguments
- `id::Int = wxID_ANY[]` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = 0` - Style flags (e.g., wxST_NO_AUTORESIZE[])

# Example
```julia
label = WxStaticText(frame, "Hello, World!")
```
"""
function WxStaticText(parent::WxWindow, label::String;
                      id::Integer = wxID_ANY[],
                      pos::Tuple{Int,Int} = (-1, -1),
                      size::Tuple{Int,Int} = (-1, -1),
                      style::Integer = 0)
    label_ws = WxString(label)

    ptr = wxstatictext_create(
        parent.ptr,
        id,
        label_ws.ptr,
        pos[1], pos[2],
        size[1], size[2],
        style
    )

    delete!(label_ws)

    if ptr == C_NULL
        error("Failed to create WxStaticText")
    end

    st = WxStaticText(ptr, Any[])
    push!(parent.children, st)
    st
end
