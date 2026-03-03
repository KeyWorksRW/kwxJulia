# High-level wxComboBox wrapper

"""
    wxComboBox

A drop-down selection control with an optional text entry field.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxComboBox C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct wxComboBox <: wxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    wxComboBox(parent::wxWindow; kwargs...) -> wxComboBox

Create a new combo box.

# Keyword Arguments
- `value::String = ""` - Initial text in the text field
- `choices::Vector{String} = String[]` - Initial list of choices
- `id::Int = KwxFFI.ID_ANY()` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = 0` - Style flags (e.g., KwxFFI.CB_READONLY(), KwxFFI.CB_DROPDOWN(), KwxFFI.CB_SORT())

# Example
```julia
combo = wxComboBox(frame, choices=["Red", "Green", "Blue"])
on_combobox!(combo) do event
    println("Selected: ", get_string_selection(combo))
end
```
"""
function wxComboBox(parent::wxWindow;
                    value::String = "",
                    choices::Vector{String} = String[],
                    id::Integer = KwxFFI.ID_ANY(),
                    pos::Tuple{Int,Int} = (-1, -1),
                    size::Tuple{Int,Int} = (-1, -1),
                    style::Integer = 0)
    value_ws = wxString(value)

    # Convert Julia strings to array of C strings for TArrayString
    c_choices = [Base.unsafe_convert(Cstring, s) for s in choices]
    choices_ptr = isempty(c_choices) ? Ptr{Ptr{UInt8}}(C_NULL) : pointer(c_choices)

    ptr = GC.@preserve choices c_choices begin
        KwxFFI.wxComboBox_Create(
            parent.ptr,
            Cint(id),
            value_ws.ptr,
            Cint(pos[1]), Cint(pos[2]),
            Cint(size[1]), Cint(size[2]),
            Cint(length(choices)),
            choices_ptr,
            Cint(style)
        )
    end

    delete!(value_ws)

    if ptr == C_NULL
        error("Failed to create wxComboBox")
    end

    cb = wxComboBox(ptr, Any[])
    push!(parent.children, cb)
    cb
end

# --- Item management ---

"""
    append!(combo::wxComboBox, item::String)

Append an item to the end of the list.
"""
function append!(combo::wxComboBox, item::String)
    ws = wxString(item)
    KwxFFI.wxComboBox_Append(combo.ptr, ws.ptr)
    delete!(ws)
    nothing
end

"""
    clear!(combo::wxComboBox)

Remove all items from the combo box.
"""
function clear!(combo::wxComboBox)
    KwxFFI.wxComboBox_Clear(combo.ptr)
    nothing
end

"""
    delete_item!(combo::wxComboBox, index::Int)

Delete the item at the given index (0-based).
"""
function delete_item!(combo::wxComboBox, index::Integer)
    KwxFFI.wxComboBox_Delete(combo.ptr, Cint(index))
    nothing
end

"""
    get_count(combo::wxComboBox) -> Int

Get the number of items in the combo box.
"""
function get_count(combo::wxComboBox)
    Int(KwxFFI.wxComboBox_GetCount(combo.ptr))
end

# --- Selection ---

"""
    get_selection(combo::wxComboBox) -> Int

Get the index of the selected item (-1 if none). 0-based.
"""
function get_selection(combo::wxComboBox)
    Int(KwxFFI.wxComboBox_GetSelection(combo.ptr))
end

"""
    set_selection!(combo::wxComboBox, index::Int)

Select an item by index (0-based).
"""
function set_selection!(combo::wxComboBox, index::Integer)
    KwxFFI.wxComboBox_SetSelection(combo.ptr, Cint(index))
    nothing
end

"""
    get_string(combo::wxComboBox, index::Int) -> String

Get the string at the given index (0-based).
"""
function get_string(combo::wxComboBox, index::Integer)
    ws_ptr = KwxFFI.wxComboBox_GetString(combo.ptr, Cint(index))
    result = _wx_get_string(ws_ptr)
    result
end

"""
    get_string_selection(combo::wxComboBox) -> String

Get the currently selected string.
"""
function get_string_selection(combo::wxComboBox)
    ws_ptr = KwxFFI.wxComboBox_GetStringSelection(combo.ptr)
    result = _wx_get_string(ws_ptr)
    result
end

# --- Value (text field) ---

"""
    get_value(combo::wxComboBox) -> String

Get the current text in the text field.
"""
function get_value(combo::wxComboBox)
    ws_ptr = KwxFFI.wxComboBox_GetValue(combo.ptr)
    result = _wx_get_string(ws_ptr)
    result
end

"""
    set_value!(combo::wxComboBox, text::String)

Set the text in the text field.
"""
function set_value!(combo::wxComboBox, text::String)
    ws = wxString(text)
    KwxFFI.wxComboBox_SetValue(combo.ptr, ws.ptr)
    delete!(ws)
    nothing
end

# --- Search ---

"""
    find_string(combo::wxComboBox, s::String) -> Int

Find an item by string. Returns 0-based index or -1 if not found.
"""
function find_string(combo::wxComboBox, s::String)
    ws = wxString(s)
    result = Int(KwxFFI.wxComboBox_FindString(combo.ptr, ws.ptr))
    delete!(ws)
    result
end

# --- Events ---

"""
    on_combobox!(handler::Function, combo::wxComboBox)
    on_combobox!(combo::wxComboBox, handler::Function)

Connect a handler for combobox selection change events.

# Example
```julia
on_combobox!(combo) do event
    println("Selection changed!")
end
```
"""
function on_combobox!(combo::wxComboBox, handler::Function)
    wx_connect!(combo, KwxFFI.wxEVT_COMBOBOX(), handler)
end

function on_combobox!(handler::Function, combo::wxComboBox)
    on_combobox!(combo, handler)
end

"""
    on_text_changed!(handler::Function, combo::wxComboBox)
    on_text_changed!(combo::wxComboBox, handler::Function)

Connect a handler for text change events in the combo box text field.
"""
function on_text_changed!(combo::wxComboBox, handler::Function)
    wx_connect!(combo, KwxFFI.wxEVT_TEXT(), handler)
end

function on_text_changed!(handler::Function, combo::wxComboBox)
    on_text_changed!(combo, handler)
end
