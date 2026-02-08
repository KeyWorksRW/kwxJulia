# High-level WxComboBox wrapper

"""
    WxComboBox

A drop-down selection control with an optional text entry field.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxComboBox C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct WxComboBox <: WxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    WxComboBox(parent::WxWindow; kwargs...) -> WxComboBox

Create a new combo box.

# Keyword Arguments
- `value::String = ""` - Initial text in the text field
- `choices::Vector{String} = String[]` - Initial list of choices
- `id::Int = wxID_ANY[]` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = 0` - Style flags (e.g., wxCB_READONLY[], wxCB_DROPDOWN[], wxCB_SORT[])

# Example
```julia
combo = WxComboBox(frame, choices=["Red", "Green", "Blue"])
on_combobox!(combo) do event
    println("Selected: ", get_string_selection(combo))
end
```
"""
function WxComboBox(parent::WxWindow;
                    value::String = "",
                    choices::Vector{String} = String[],
                    id::Integer = wxID_ANY[],
                    pos::Tuple{Int,Int} = (-1, -1),
                    size::Tuple{Int,Int} = (-1, -1),
                    style::Integer = 0)
    value_ws = WxString(value)

    # Convert Julia strings to array of C strings for TArrayString
    c_choices = [Base.unsafe_convert(Cstring, s) for s in choices]
    choices_ptr = isempty(c_choices) ? Ptr{Ptr{UInt8}}(C_NULL) : pointer(c_choices)

    ptr = GC.@preserve choices c_choices begin
        wxcombobox_create(
            parent.ptr,
            id,
            value_ws.ptr,
            pos[1], pos[2],
            size[1], size[2],
            length(choices),
            choices_ptr,
            style
        )
    end

    delete!(value_ws)

    if ptr == C_NULL
        error("Failed to create WxComboBox")
    end

    cb = WxComboBox(ptr, Any[])
    push!(parent.children, cb)
    cb
end

# --- Item management ---

"""
    append!(combo::WxComboBox, item::String)

Append an item to the end of the list.
"""
function append!(combo::WxComboBox, item::String)
    ws = WxString(item)
    wxcombobox_append(combo.ptr, ws.ptr)
    delete!(ws)
    nothing
end

"""
    clear!(combo::WxComboBox)

Remove all items from the combo box.
"""
function clear!(combo::WxComboBox)
    wxcombobox_clear(combo.ptr)
    nothing
end

"""
    delete_item!(combo::WxComboBox, index::Int)

Delete the item at the given index (0-based).
"""
function delete_item!(combo::WxComboBox, index::Integer)
    wxcombobox_delete(combo.ptr, index)
    nothing
end

"""
    get_count(combo::WxComboBox) -> Int

Get the number of items in the combo box.
"""
function get_count(combo::WxComboBox)
    Int(wxcombobox_getcount(combo.ptr))
end

# --- Selection ---

"""
    get_selection(combo::WxComboBox) -> Int

Get the index of the selected item (-1 if none). 0-based.
"""
function get_selection(combo::WxComboBox)
    Int(wxcombobox_getselection(combo.ptr))
end

"""
    set_selection!(combo::WxComboBox, index::Int)

Select an item by index (0-based).
"""
function set_selection!(combo::WxComboBox, index::Integer)
    wxcombobox_setselection(combo.ptr, index)
    nothing
end

"""
    get_string(combo::WxComboBox, index::Int) -> String

Get the string at the given index (0-based).
"""
function get_string(combo::WxComboBox, index::Integer)
    ws_ptr = wxcombobox_getstring(combo.ptr, index)
    ws = WxString(ws_ptr, true)
    String(ws)
end

"""
    get_string_selection(combo::WxComboBox) -> String

Get the currently selected string.
"""
function get_string_selection(combo::WxComboBox)
    ws_ptr = wxcombobox_getstringselection(combo.ptr)
    ws = WxString(ws_ptr, true)
    String(ws)
end

# --- Value (text field) ---

"""
    get_value(combo::WxComboBox) -> String

Get the current text in the text field.
"""
function get_value(combo::WxComboBox)
    ws_ptr = wxcombobox_getvalue(combo.ptr)
    ws = WxString(ws_ptr, true)
    String(ws)
end

"""
    set_value!(combo::WxComboBox, text::String)

Set the text in the text field.
"""
function set_value!(combo::WxComboBox, text::String)
    ws = WxString(text)
    wxcombobox_setvalue(combo.ptr, ws.ptr)
    delete!(ws)
    nothing
end

# --- Search ---

"""
    find_string(combo::WxComboBox, s::String) -> Int

Find an item by string. Returns 0-based index or -1 if not found.
"""
function find_string(combo::WxComboBox, s::String)
    ws = WxString(s)
    result = Int(wxcombobox_findstring(combo.ptr, ws.ptr))
    delete!(ws)
    result
end

# --- Events ---

"""
    on_combobox!(handler::Function, combo::WxComboBox)
    on_combobox!(combo::WxComboBox, handler::Function)

Connect a handler for combobox selection change events.

# Example
```julia
on_combobox!(combo) do event
    println("Selection changed!")
end
```
"""
function on_combobox!(combo::WxComboBox, handler::Function)
    wx_connect!(combo, wxEVT_COMBOBOX[], handler)
end

function on_combobox!(handler::Function, combo::WxComboBox)
    on_combobox!(combo, handler)
end

"""
    on_text_changed!(handler::Function, combo::WxComboBox)
    on_text_changed!(combo::WxComboBox, handler::Function)

Connect a handler for text change events in the combo box text field.
"""
function on_text_changed!(combo::WxComboBox, handler::Function)
    wx_connect!(combo, wxEVT_TEXT[], handler)
end

function on_text_changed!(handler::Function, combo::WxComboBox)
    on_text_changed!(combo, handler)
end
