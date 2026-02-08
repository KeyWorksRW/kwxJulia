# High-level WxListBox wrapper

"""
    WxListBox

A list selection control displaying a scrollable list of items.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxListBox C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct WxListBox <: WxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    WxListBox(parent::WxWindow; kwargs...) -> WxListBox

Create a new list box.

# Keyword Arguments
- `choices::Vector{String} = String[]` - Initial list of items
- `id::Int = wxID_ANY[]` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = 0` - Style flags (e.g., wxLB_SINGLE[], wxLB_MULTIPLE[], wxLB_SORT[])

# Example
```julia
lb = WxListBox(frame, choices=["Apple", "Banana", "Cherry"])
on_listbox!(lb) do event
    idx = get_selection(lb)
    println("Selected index: ", idx)
end
```
"""
function WxListBox(parent::WxWindow;
                   choices::Vector{String} = String[],
                   id::Integer = wxID_ANY[],
                   pos::Tuple{Int,Int} = (-1, -1),
                   size::Tuple{Int,Int} = (-1, -1),
                   style::Integer = 0)
    # Convert Julia strings to array of C strings for TArrayString
    c_choices = [Base.unsafe_convert(Cstring, s) for s in choices]
    choices_ptr = isempty(c_choices) ? Ptr{Ptr{UInt8}}(C_NULL) : pointer(c_choices)

    ptr = GC.@preserve choices c_choices begin
        wxlistbox_create(
            parent.ptr,
            id,
            pos[1], pos[2],
            size[1], size[2],
            length(choices),
            choices_ptr,
            style
        )
    end

    if ptr == C_NULL
        error("Failed to create WxListBox")
    end

    lb = WxListBox(ptr, Any[])
    push!(parent.children, lb)
    lb
end

# --- Item management ---

"""
    append!(lb::WxListBox, item::String)

Append an item to the end of the list.
"""
function append!(lb::WxListBox, item::String)
    ws = WxString(item)
    wxlistbox_append(lb.ptr, ws.ptr)
    delete!(ws)
    nothing
end

"""
    clear!(lb::WxListBox)

Remove all items from the list box.
"""
function clear!(lb::WxListBox)
    wxlistbox_clear(lb.ptr)
    nothing
end

"""
    delete_item!(lb::WxListBox, index::Int)

Delete the item at the given index (0-based).
"""
function delete_item!(lb::WxListBox, index::Integer)
    wxlistbox_delete(lb.ptr, index)
    nothing
end

"""
    get_count(lb::WxListBox) -> Int

Get the number of items in the list box.
"""
function get_count(lb::WxListBox)
    Int(wxlistbox_getcount(lb.ptr))
end

# --- Selection ---

"""
    get_selection(lb::WxListBox) -> Int

Get the index of the selected item (-1 if none). 0-based.
For single-selection list boxes only.
"""
function get_selection(lb::WxListBox)
    Int(wxlistbox_getselection(lb.ptr))
end

"""
    set_selection!(lb::WxListBox, index::Int, select::Bool = true)

Select or deselect an item by index (0-based).
"""
function set_selection!(lb::WxListBox, index::Integer, select::Bool = true)
    wxlistbox_setselection(lb.ptr, index, select)
    nothing
end

"""
    is_selected(lb::WxListBox, index::Int) -> Bool

Returns true if the item at the given index is selected.
"""
function is_selected(lb::WxListBox, index::Integer)
    wxlistbox_isselected(lb.ptr, index) != 0
end

# --- String access ---

"""
    get_string(lb::WxListBox, index::Int) -> String

Get the string at the given index (0-based).
"""
function get_string(lb::WxListBox, index::Integer)
    ws_ptr = wxlistbox_getstring(lb.ptr, index)
    ws = WxString(ws_ptr, true)
    String(ws)
end

"""
    set_string!(lb::WxListBox, index::Int, s::String)

Set the string at the given index (0-based).
"""
function set_string!(lb::WxListBox, index::Integer, s::String)
    ws = WxString(s)
    wxlistbox_setstring(lb.ptr, index, ws.ptr)
    delete!(ws)
    nothing
end

# --- Search ---

"""
    find_string(lb::WxListBox, s::String) -> Int

Find an item by string. Returns 0-based index or -1 if not found.
"""
function find_string(lb::WxListBox, s::String)
    ws = WxString(s)
    result = Int(wxlistbox_findstring(lb.ptr, ws.ptr))
    delete!(ws)
    result
end

# --- Scrolling ---

"""
    set_first_item!(lb::WxListBox, index::Int)

Scroll the list box to make the given item the first visible item.
"""
function set_first_item!(lb::WxListBox, index::Integer)
    wxlistbox_setfirstitem(lb.ptr, index)
    nothing
end

# --- Events ---

"""
    on_listbox!(handler::Function, lb::WxListBox)
    on_listbox!(lb::WxListBox, handler::Function)

Connect a handler for list box selection change events.

# Example
```julia
on_listbox!(listbox) do event
    println("Selection changed!")
end
```
"""
function on_listbox!(lb::WxListBox, handler::Function)
    wx_connect!(lb, wxEVT_LISTBOX[], handler)
end

function on_listbox!(handler::Function, lb::WxListBox)
    on_listbox!(lb, handler)
end

"""
    on_listbox_dclick!(handler::Function, lb::WxListBox)
    on_listbox_dclick!(lb::WxListBox, handler::Function)

Connect a handler for list box double-click events.
"""
function on_listbox_dclick!(lb::WxListBox, handler::Function)
    wx_connect!(lb, wxEVT_LISTBOX_DCLICK[], handler)
end

function on_listbox_dclick!(handler::Function, lb::WxListBox)
    on_listbox_dclick!(lb, handler)
end
