# High-level wxTextCtrl wrapper

"""
    wxTextCtrl

A text input control that can be single-line or multi-line.

# Fields
- `ptr::Ptr{Cvoid}` - Pointer to the underlying wxTextCtrl C++ object
- `closures::Vector{Any}` - Keeps event handler closures alive (prevents GC)
"""
mutable struct wxTextCtrl <: wxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
end

"""
    wxTextCtrl(parent::wxWindow; kwargs...) -> wxTextCtrl

Create a new text control.

# Keyword Arguments
- `value::String = ""` - Initial text content
- `id::Int = KwxFFI.ID_ANY()` - Window identifier
- `pos::Tuple{Int,Int} = (-1, -1)` - Initial position (x, y); -1 means default
- `size::Tuple{Int,Int} = (-1, -1)` - Initial size (width, height); -1 means default
- `style::Integer = 0` - Style flags (e.g., KwxFFI.TE_MULTILINE(), KwxFFI.TE_READONLY())

# Example
```julia
# Single-line text input
text = wxTextCtrl(frame, value="Enter text here")

# Multi-line text editor
editor = wxTextCtrl(frame, style=KwxFFI.TE_MULTILINE())
```
"""
function wxTextCtrl(parent::wxWindow;
                    value::String = "",
                    id::Integer = KwxFFI.ID_ANY(),
                    pos::Tuple{Int,Int} = (-1, -1),
                    size::Tuple{Int,Int} = (-1, -1),
                    style::Integer = 0)
    value_ws = wxString(value)

    ptr = KwxFFI.wxTextCtrl_Create(
        parent.ptr,
        Cint(id),
        value_ws.ptr,
        Cint(pos[1]), Cint(pos[2]),
        Cint(size[1]), Cint(size[2]),
        Clong(style)
    )

    delete!(value_ws)

    if ptr == C_NULL
        error("Failed to create wxTextCtrl")
    end

    tc = wxTextCtrl(ptr, Any[])
    push!(parent.children, tc)
    tc
end

# --- Value access ---

"""
    get_value(tc::wxTextCtrl) -> String

Get the text content of the control.
"""
function get_value(tc::wxTextCtrl)
    _wx_get_string(KwxFFI.wxTextCtrl_GetValue(tc.ptr))
end

"""
    set_value!(tc::wxTextCtrl, text::String)

Set the text content. Generates a text change event.
"""
function set_value!(tc::wxTextCtrl, text::String)
    ws = wxString(text)
    KwxFFI.wxTextCtrl_SetValue(tc.ptr, ws.ptr)
    delete!(ws)
    nothing
end

"""
    change_value!(tc::wxTextCtrl, text::String)

Set the text content without generating a text change event.
"""
function change_value!(tc::wxTextCtrl, text::String)
    ws = wxString(text)
    KwxFFI.wxTextCtrl_ChangeValue(tc.ptr, ws.ptr)
    delete!(ws)
    nothing
end

# --- Line access ---

"""
    get_line_text(tc::wxTextCtrl, line::Int) -> String

Get the text of a specific line (0-based).
"""
function get_line_text(tc::wxTextCtrl, line::Integer)
    _wx_get_string(KwxFFI.wxTextCtrl_GetLineText(tc.ptr, Clong(line)))
end

"""
    get_number_of_lines(tc::wxTextCtrl) -> Int

Get the number of lines in the text control.
"""
function get_number_of_lines(tc::wxTextCtrl)
    Int(KwxFFI.wxTextCtrl_GetNumberOfLines(tc.ptr))
end

"""
    get_line_length(tc::wxTextCtrl, line::Int) -> Int

Get the length of a specific line (0-based).
"""
function get_line_length(tc::wxTextCtrl, line::Integer)
    Int(KwxFFI.wxTextCtrl_GetLineLength(tc.ptr, Clong(line)))
end

# --- Cursor / insertion point ---

"""
    get_insertion_point(tc::wxTextCtrl) -> Int

Get the current insertion point (cursor position).
"""
function get_insertion_point(tc::wxTextCtrl)
    Int(KwxFFI.wxTextCtrl_GetInsertionPoint(tc.ptr))
end

"""
    set_insertion_point!(tc::wxTextCtrl, pos::Int)

Set the insertion point (cursor position).
"""
function set_insertion_point!(tc::wxTextCtrl, pos::Integer)
    KwxFFI.wxTextCtrl_SetInsertionPoint(tc.ptr, Clong(pos))
    nothing
end

"""
    set_insertion_point_end!(tc::wxTextCtrl)

Move the cursor to the end of the text.
"""
function set_insertion_point_end!(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_SetInsertionPointEnd(tc.ptr)
    nothing
end

"""
    get_last_position(tc::wxTextCtrl) -> Int

Get the position of the last character.
"""
function get_last_position(tc::wxTextCtrl)
    Int(KwxFFI.wxTextCtrl_GetLastPosition(tc.ptr))
end

# --- Selection ---

"""
    get_selection(tc::wxTextCtrl) -> Tuple{Int, Int}

Get the selection range as (from, to).
"""
function get_selection(tc::wxTextCtrl)
    from = Ref{Clong}(0)
    to = Ref{Clong}(0)
    KwxFFI.wxTextCtrl_GetSelection(tc.ptr, from, to)
    (Int(from[]), Int(to[]))
end

"""
    set_selection!(tc::wxTextCtrl, from::Int, to::Int)

Select a range of text.
"""
function set_selection!(tc::wxTextCtrl, from::Integer, to::Integer)
    KwxFFI.wxTextCtrl_SetSelection(tc.ptr, Clong(from), Clong(to))
    nothing
end

# --- Text manipulation ---

"""
    write_text!(tc::wxTextCtrl, text::String)

Insert text at the current insertion point.
"""
function write_text!(tc::wxTextCtrl, text::String)
    ws = wxString(text)
    KwxFFI.wxTextCtrl_WriteText(tc.ptr, ws.ptr)
    delete!(ws)
    nothing
end

"""
    replace_text!(tc::wxTextCtrl, from::Int, to::Int, value::String)

Replace text in range [from, to).
"""
function replace_text!(tc::wxTextCtrl, from::Integer, to::Integer, value::String)
    ws = wxString(value)
    KwxFFI.wxTextCtrl_Replace(tc.ptr, Clong(from), Clong(to), ws.ptr)
    delete!(ws)
    nothing
end

"""
    remove_text!(tc::wxTextCtrl, from::Int, to::Int)

Remove text in range [from, to).
"""
function remove_text!(tc::wxTextCtrl, from::Integer, to::Integer)
    KwxFFI.wxTextCtrl_Remove(tc.ptr, Clong(from), Clong(to))
    nothing
end

"""
    clear!(tc::wxTextCtrl)

Clear all text in the control.
"""
function clear!(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_Clear(tc.ptr)
    nothing
end

# --- State queries ---

"""
    is_modified(tc::wxTextCtrl) -> Bool

Returns true if the text has been modified since the last save or creation.
"""
function is_modified(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_IsModified(tc.ptr) != 0
end

"""
    is_editable(tc::wxTextCtrl) -> Bool

Returns true if the control is editable.
"""
function is_editable(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_IsEditable(tc.ptr) != 0
end

"""
    set_editable!(tc::wxTextCtrl, editable::Bool)

Set whether the control is editable.
"""
function set_editable!(tc::wxTextCtrl, editable::Bool)
    KwxFFI.wxTextCtrl_SetEditable(tc.ptr, Cint(editable))
    nothing
end

"""
    discard_edits!(tc::wxTextCtrl)

Reset the modified flag (mark as unmodified).
"""
function discard_edits!(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_DiscardEdits(tc.ptr)
    nothing
end

# --- Clipboard ---

"""
    copy!(tc::wxTextCtrl)

Copy selected text to clipboard.
"""
function copy!(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_Copy(tc.ptr)
    nothing
end

"""
    cut!(tc::wxTextCtrl)

Cut selected text to clipboard.
"""
function cut!(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_Cut(tc.ptr)
    nothing
end

"""
    paste!(tc::wxTextCtrl)

Paste text from clipboard at the insertion point.
"""
function paste!(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_Paste(tc.ptr)
    nothing
end

"""
    undo!(tc::wxTextCtrl)

Undo the last edit operation.
"""
function undo!(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_Undo(tc.ptr)
    nothing
end

"""
    redo!(tc::wxTextCtrl)

Redo the last undone edit operation.
"""
function redo!(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_Redo(tc.ptr)
    nothing
end

"""
    can_copy(tc::wxTextCtrl) -> Bool

Returns true if there is selected text that can be copied.
"""
function can_copy(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_CanCopy(tc.ptr) != 0
end

"""
    can_cut(tc::wxTextCtrl) -> Bool

Returns true if there is selected text that can be cut.
"""
function can_cut(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_CanCut(tc.ptr) != 0
end

"""
    can_paste(tc::wxTextCtrl) -> Bool

Returns true if there is data on the clipboard that can be pasted.
"""
function can_paste(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_CanPaste(tc.ptr) != 0
end

"""
    can_undo(tc::wxTextCtrl) -> Bool

Returns true if there are actions to undo.
"""
function can_undo(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_CanUndo(tc.ptr) != 0
end

"""
    can_redo(tc::wxTextCtrl) -> Bool

Returns true if there are actions to redo.
"""
function can_redo(tc::wxTextCtrl)
    KwxFFI.wxTextCtrl_CanRedo(tc.ptr) != 0
end

# --- File operations ---

"""
    load_file!(tc::wxTextCtrl, filename::String) -> Bool

Load a file into the text control. Returns true on success.
"""
function load_file!(tc::wxTextCtrl, filename::String)
    ws = wxString(filename)
    result = KwxFFI.wxTextCtrl_LoadFile(tc.ptr, ws.ptr, Cint(0)) != 0
    delete!(ws)
    result
end

"""
    save_file!(tc::wxTextCtrl, filename::String) -> Bool

Save the text control contents to a file. Returns true on success.
"""
function save_file!(tc::wxTextCtrl, filename::String)
    ws = wxString(filename)
    result = KwxFFI.wxTextCtrl_SaveFile(tc.ptr, ws.ptr, Cint(0)) != 0
    delete!(ws)
    result
end

# --- Event convenience ---

"""
    on_text_changed!(handler::Function, tc::wxTextCtrl)
    on_text_changed!(tc::wxTextCtrl, handler::Function)

Connect a handler for text change events.

# Example
```julia
on_text_changed!(textctrl) do event
    println("Text changed!")
end
```
"""
function on_text_changed!(tc::wxTextCtrl, handler::Function)
    wx_connect!(tc, KwxFFI.wxEVT_TEXT(), handler)
end

function on_text_changed!(handler::Function, tc::wxTextCtrl)
    on_text_changed!(tc, handler)
end

"""
    on_text_enter!(handler::Function, tc::wxTextCtrl)
    on_text_enter!(tc::wxTextCtrl, handler::Function)

Connect a handler for the Enter key event (requires wxTE_PROCESS_ENTER style).

# Example
```julia
tc = wxTextCtrl(frame, style=KwxFFI.TE_PROCESS_ENTER())
on_text_enter!(tc) do event
    println("Enter pressed!")
end
```
"""
function on_text_enter!(tc::wxTextCtrl, handler::Function)
    wx_connect!(tc, KwxFFI.wxEVT_TEXT_ENTER(), handler)
end

function on_text_enter!(handler::Function, tc::wxTextCtrl)
    on_text_enter!(tc, handler)
end
