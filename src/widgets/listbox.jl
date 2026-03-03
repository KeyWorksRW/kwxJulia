# High-level wxListBox wrapper

"""
    wxListBox

A list selection control displaying a scrollable list of items.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxListBox C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct wxListBox <: wxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    wxListBox(parent::wxWindow; kwargs...) -> wxListBox

Create a new list box.

# Keyword Arguments
- `choices::Vector{String} = String[]` - Initial list of items
- `id::Int = KwxFFI.ID_ANY()` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = 0` - Style flags (e.g., KwxFFI.LB_SINGLE(), KwxFFI.LB_MULTIPLE(), KwxFFI.LB_SORT())

# Example
```julia
lb = wxListBox(frame, choices=["Apple", "Banana", "Cherry"])
on_listbox!(lb) do event
    idx = get_selection(lb)
    println("Selected index: ", idx)
end
```
"""
function wxListBox(parent::wxWindow;
                   choices::Vector{String} = String[],
                   id::Integer = KwxFFI.ID_ANY(),
                   pos::Tuple{Int,Int} = (-1, -1),
                   size::Tuple{Int,Int} = (-1, -1),
                   style::Integer = 0)
    # Convert Julia strings to array of C strings for TArrayString
    c_choices = [Base.unsafe_convert(Cstring, s) for s in choices]
    choices_ptr = isempty(c_choices) ? Ptr{Ptr{UInt8}}(C_NULL) : pointer(c_choices)

    ptr = GC.@preserve choices c_choices begin
        KwxFFI.wxListBox_Create(
            parent.ptr,
            Cint(id),
            Cint(pos[1]), Cint(pos[2]),
            Cint(size[1]), Cint(size[2]),
            Cint(length(choices)),
            choices_ptr,
            Cint(style)
        )
    end

    if ptr == C_NULL
        error("Failed to create wxListBox")
    end

    lb = wxListBox(ptr, Any[])
    push!(parent.children, lb)
    lb
end

# --- Item management ---

"""
    append!(lb::wxListBox, item::String)

Append an item to the end of the list.
"""
function append!(lb::wxListBox, item::String)
    ws = wxString(item)
    KwxFFI.wxListBox_Append(lb.ptr, ws.ptr)
    delete!(ws)
    nothing
end

"""
    clear!(lb::wxListBox)

Remove all items from the list box.
"""
function clear!(lb::wxListBox)
    KwxFFI.wxListBox_Clear(lb.ptr)
    nothing
end

"""
    delete_item!(lb::wxListBox, index::Int)

Delete the item at the given index (0-based).
"""
function delete_item!(lb::wxListBox, index::Integer)
    KwxFFI.wxListBox_Delete(lb.ptr, Cint(index))
    nothing
end

"""
    get_count(lb::wxListBox) -> Int

Get the number of items in the list box.
"""
function get_count(lb::wxListBox)
    Int(KwxFFI.wxListBox_GetCount(lb.ptr))
end

# --- Selection ---

"""
    get_selection(lb::wxListBox) -> Int

Get the index of the selected item (-1 if none). 0-based.
For single-selection list boxes only.
"""
function get_selection(lb::wxListBox)
    Int(KwxFFI.wxListBox_GetSelection(lb.ptr))
end

"""
    set_selection!(lb::wxListBox, index::Int, select::Bool = true)

Select or deselect an item by index (0-based).
"""
function set_selection!(lb::wxListBox, index::Integer, select::Bool = true)
    KwxFFI.wxListBox_SetSelection(lb.ptr, Cint(index), Cint(select))
    nothing
end

"""
    is_selected(lb::wxListBox, index::Int) -> Bool

Returns true if the item at the given index is selected.
"""
function is_selected(lb::wxListBox, index::Integer)
    KwxFFI.wxListBox_IsSelected(lb.ptr, Cint(index)) != 0
end

# --- String access ---

"""
    get_string(lb::wxListBox, index::Int) -> String

Get the string at the given index (0-based).
"""
function get_string(lb::wxListBox, index::Integer)
    ws_ptr = KwxFFI.wxListBox_GetString(lb.ptr, Cint(index))
    _wx_get_string(ws_ptr)
end

"""
    set_string!(lb::wxListBox, index::Int, s::String)

Set the string at the given index (0-based).
"""
function set_string!(lb::wxListBox, index::Integer, s::String)
    ws = wxString(s)
    KwxFFI.wxListBox_SetString(lb.ptr, Cint(index), ws.ptr)
    delete!(ws)
    nothing
end

# --- Search ---

"""
    find_string(lb::wxListBox, s::String) -> Int

Find an item by string. Returns 0-based index or -1 if not found.
"""
function find_string(lb::wxListBox, s::String)
    ws = wxString(s)
    result = Int(KwxFFI.wxListBox_FindString(lb.ptr, ws.ptr))
    delete!(ws)
    result
end

# --- Scrolling ---

"""
    set_first_item!(lb::wxListBox, index::Int)

Scroll the list box to make the given item the first visible item.
"""
function set_first_item!(lb::wxListBox, index::Integer)
    KwxFFI.wxListBox_SetFirstItem(lb.ptr, Cint(index))
    nothing
end

# --- Events ---

"""
    on_listbox!(handler::Function, lb::wxListBox)
    on_listbox!(lb::wxListBox, handler::Function)

Connect a handler for list box selection change events.

# Example
```julia
on_listbox!(listbox) do event
    println("Selection changed!")
end
```
"""
function on_listbox!(lb::wxListBox, handler::Function)
    wx_connect!(lb, KwxFFI.wxEVT_LISTBOX(), handler)
end

function on_listbox!(handler::Function, lb::wxListBox)
    on_listbox!(lb, handler)
end

"""
    on_listbox_dclick!(handler::Function, lb::wxListBox)
    on_listbox_dclick!(lb::wxListBox, handler::Function)

Connect a handler for list box double-click events.
"""
function on_listbox_dclick!(lb::wxListBox, handler::Function)
    wx_connect!(lb, KwxFFI.wxEVT_LISTBOX_DCLICK(), handler)
end

function on_listbox_dclick!(handler::Function, lb::wxListBox)
    on_listbox_dclick!(lb, handler)
end
