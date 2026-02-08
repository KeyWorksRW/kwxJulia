# High-level WxTextCtrl wrapper

"""
    WxTextCtrl

A text input control that can be single-line or multi-line.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxTextCtrl C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct WxTextCtrl <: WxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    WxTextCtrl(parent::WxWindow; kwargs...) -> WxTextCtrl

Create a new text control.

# Keyword Arguments
- `value::String = ""` - Initial text content
- `id::Int = wxID_ANY[]` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Int = 0` - Style flags (e.g., wxTE_MULTILINE[], wxTE_READONLY[])

# Example
```julia
# Single-line text input
text = WxTextCtrl(frame, value="Enter text here")

# Multi-line text editor
editor = WxTextCtrl(frame, style=wxTE_MULTILINE[])
```
"""
function WxTextCtrl(parent::WxWindow;
                    value::String = "",
                    id::Integer = wxID_ANY[],
                    pos::Tuple{Int,Int} = (-1, -1),
                    size::Tuple{Int,Int} = (-1, -1),
                    style::Integer = 0)
    value_ws = WxString(value)

    ptr = wxtextctrl_create(
        parent.ptr,
        id,
        value_ws.ptr,
        pos[1], pos[2],
        size[1], size[2],
        style
    )

    delete!(value_ws)

    if ptr == C_NULL
        error("Failed to create WxTextCtrl")
    end

    tc = WxTextCtrl(ptr, Any[])
    push!(parent.children, tc)
    tc
end

# --- Value access ---

"""
    get_value(tc::WxTextCtrl) -> String

Get the text content of the control.
"""
function get_value(tc::WxTextCtrl)
    ws_ptr = wxtextctrl_getvalue(tc.ptr)
    ws = WxString(ws_ptr, true)  # owned — will be freed
    String(ws)
end

"""
    set_value!(tc::WxTextCtrl, text::String)

Set the text content. Generates a text change event.
"""
function set_value!(tc::WxTextCtrl, text::String)
    ws = WxString(text)
    wxtextctrl_setvalue(tc.ptr, ws.ptr)
    delete!(ws)
    nothing
end

"""
    change_value!(tc::WxTextCtrl, text::String)

Set the text content without generating a text change event.
"""
function change_value!(tc::WxTextCtrl, text::String)
    ws = WxString(text)
    wxtextctrl_changevalue(tc.ptr, ws.ptr)
    delete!(ws)
    nothing
end

# --- Line access ---

"""
    get_line_text(tc::WxTextCtrl, line::Int) -> String

Get the text of a specific line (0-based).
"""
function get_line_text(tc::WxTextCtrl, line::Integer)
    ws_ptr = wxtextctrl_getlinetext(tc.ptr, line)
    ws = WxString(ws_ptr, true)
    String(ws)
end

"""
    get_number_of_lines(tc::WxTextCtrl) -> Int

Get the number of lines in the text control.
"""
function get_number_of_lines(tc::WxTextCtrl)
    Int(wxtextctrl_getnumberoflines(tc.ptr))
end

"""
    get_line_length(tc::WxTextCtrl, line::Int) -> Int

Get the length of a specific line (0-based).
"""
function get_line_length(tc::WxTextCtrl, line::Integer)
    Int(wxtextctrl_getlinelength(tc.ptr, line))
end

# --- Cursor / insertion point ---

"""
    get_insertion_point(tc::WxTextCtrl) -> Int

Get the current insertion point (cursor position).
"""
function get_insertion_point(tc::WxTextCtrl)
    Int(wxtextctrl_getinsertionpoint(tc.ptr))
end

"""
    set_insertion_point!(tc::WxTextCtrl, pos::Int)

Set the insertion point (cursor position).
"""
function set_insertion_point!(tc::WxTextCtrl, pos::Integer)
    wxtextctrl_setinsertionpoint(tc.ptr, pos)
    nothing
end

"""
    set_insertion_point_end!(tc::WxTextCtrl)

Move the cursor to the end of the text.
"""
function set_insertion_point_end!(tc::WxTextCtrl)
    wxtextctrl_setinsertionpointend(tc.ptr)
    nothing
end

"""
    get_last_position(tc::WxTextCtrl) -> Int

Get the position of the last character.
"""
function get_last_position(tc::WxTextCtrl)
    Int(wxtextctrl_getlastposition(tc.ptr))
end

# --- Selection ---

"""
    get_selection(tc::WxTextCtrl) -> Tuple{Int, Int}

Get the selection range as (from, to).
"""
function get_selection(tc::WxTextCtrl)
    wxtextctrl_getselection(tc.ptr)
end

"""
    set_selection!(tc::WxTextCtrl, from::Int, to::Int)

Select a range of text.
"""
function set_selection!(tc::WxTextCtrl, from::Integer, to::Integer)
    wxtextctrl_setselection(tc.ptr, from, to)
    nothing
end

# --- Text manipulation ---

"""
    write_text!(tc::WxTextCtrl, text::String)

Insert text at the current insertion point.
"""
function write_text!(tc::WxTextCtrl, text::String)
    ws = WxString(text)
    wxtextctrl_writetext(tc.ptr, ws.ptr)
    delete!(ws)
    nothing
end

"""
    replace_text!(tc::WxTextCtrl, from::Int, to::Int, value::String)

Replace text in range [from, to).
"""
function replace_text!(tc::WxTextCtrl, from::Integer, to::Integer, value::String)
    ws = WxString(value)
    wxtextctrl_replace(tc.ptr, from, to, ws.ptr)
    delete!(ws)
    nothing
end

"""
    remove_text!(tc::WxTextCtrl, from::Int, to::Int)

Remove text in range [from, to).
"""
function remove_text!(tc::WxTextCtrl, from::Integer, to::Integer)
    wxtextctrl_remove(tc.ptr, from, to)
    nothing
end

"""
    clear!(tc::WxTextCtrl)

Clear all text in the control.
"""
function clear!(tc::WxTextCtrl)
    wxtextctrl_clear(tc.ptr)
    nothing
end

# --- State queries ---

"""
    is_modified(tc::WxTextCtrl) -> Bool

Returns true if the text has been modified since the last save or creation.
"""
function is_modified(tc::WxTextCtrl)
    wxtextctrl_ismodified(tc.ptr) != 0
end

"""
    is_editable(tc::WxTextCtrl) -> Bool

Returns true if the control is editable.
"""
function is_editable(tc::WxTextCtrl)
    wxtextctrl_iseditable(tc.ptr) != 0
end

"""
    set_editable!(tc::WxTextCtrl, editable::Bool)

Set whether the control is editable.
"""
function set_editable!(tc::WxTextCtrl, editable::Bool)
    wxtextctrl_seteditable(tc.ptr, editable)
    nothing
end

"""
    discard_edits!(tc::WxTextCtrl)

Reset the modified flag (mark as unmodified).
"""
function discard_edits!(tc::WxTextCtrl)
    wxtextctrl_discardedits(tc.ptr)
    nothing
end

# --- Clipboard ---

"""
    copy!(tc::WxTextCtrl)

Copy selected text to clipboard.
"""
function copy!(tc::WxTextCtrl)
    wxtextctrl_copy(tc.ptr)
    nothing
end

"""
    cut!(tc::WxTextCtrl)

Cut selected text to clipboard.
"""
function cut!(tc::WxTextCtrl)
    wxtextctrl_cut(tc.ptr)
    nothing
end

"""
    paste!(tc::WxTextCtrl)

Paste text from clipboard at the insertion point.
"""
function paste!(tc::WxTextCtrl)
    wxtextctrl_paste(tc.ptr)
    nothing
end

"""
    undo!(tc::WxTextCtrl)

Undo the last edit operation.
"""
function undo!(tc::WxTextCtrl)
    wxtextctrl_undo(tc.ptr)
    nothing
end

"""
    redo!(tc::WxTextCtrl)

Redo the last undone edit operation.
"""
function redo!(tc::WxTextCtrl)
    wxtextctrl_redo(tc.ptr)
    nothing
end

"""
    can_copy(tc::WxTextCtrl) -> Bool

Returns true if there is selected text that can be copied.
"""
function can_copy(tc::WxTextCtrl)
    wxtextctrl_cancopy(tc.ptr) != 0
end

"""
    can_cut(tc::WxTextCtrl) -> Bool

Returns true if there is selected text that can be cut.
"""
function can_cut(tc::WxTextCtrl)
    wxtextctrl_cancut(tc.ptr) != 0
end

"""
    can_paste(tc::WxTextCtrl) -> Bool

Returns true if there is data on the clipboard that can be pasted.
"""
function can_paste(tc::WxTextCtrl)
    wxtextctrl_canpaste(tc.ptr) != 0
end

"""
    can_undo(tc::WxTextCtrl) -> Bool

Returns true if there are actions to undo.
"""
function can_undo(tc::WxTextCtrl)
    wxtextctrl_canundo(tc.ptr) != 0
end

"""
    can_redo(tc::WxTextCtrl) -> Bool

Returns true if there are actions to redo.
"""
function can_redo(tc::WxTextCtrl)
    wxtextctrl_canredo(tc.ptr) != 0
end

# --- File operations ---

"""
    load_file!(tc::WxTextCtrl, filename::String) -> Bool

Load a file into the text control. Returns true on success.
"""
function load_file!(tc::WxTextCtrl, filename::String)
    ws = WxString(filename)
    result = wxtextctrl_loadfile(tc.ptr, ws.ptr) != 0
    delete!(ws)
    result
end

"""
    save_file!(tc::WxTextCtrl, filename::String) -> Bool

Save the text control contents to a file. Returns true on success.
"""
function save_file!(tc::WxTextCtrl, filename::String)
    ws = WxString(filename)
    result = wxtextctrl_savefile(tc.ptr, ws.ptr) != 0
    delete!(ws)
    result
end

# --- Event convenience ---

"""
    on_text_changed!(handler::Function, tc::WxTextCtrl)
    on_text_changed!(tc::WxTextCtrl, handler::Function)

Connect a handler for text change events.

# Example
```julia
on_text_changed!(textctrl) do event
    println("Text changed!")
end
```
"""
function on_text_changed!(tc::WxTextCtrl, handler::Function)
    wx_connect!(tc, wxEVT_TEXT[], handler)
end

function on_text_changed!(handler::Function, tc::WxTextCtrl)
    on_text_changed!(tc, handler)
end

"""
    on_text_enter!(handler::Function, tc::WxTextCtrl)
    on_text_enter!(tc::WxTextCtrl, handler::Function)

Connect a handler for the Enter key event (requires wxTE_PROCESS_ENTER style).

# Example
```julia
tc = WxTextCtrl(frame, style=wxTE_PROCESS_ENTER[])
on_text_enter!(tc) do event
    println("Enter pressed!")
end
```
"""
function on_text_enter!(tc::WxTextCtrl, handler::Function)
    wx_connect!(tc, wxEVT_TEXT_ENTER[], handler)
end

function on_text_enter!(handler::Function, tc::WxTextCtrl)
    on_text_enter!(tc, handler)
end
