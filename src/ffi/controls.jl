# Raw FFI declarations for common controls:
# wxButton, wxStaticText, wxTextCtrl, wxCheckBox, wxComboBox, wxListBox

# =============================================================================
# wxButton
# =============================================================================

"""
    wxbutton_create(parent, id, label, x, y, w, h, style) -> Ptr{Cvoid}

Create a new wxButton. label is a wxString*.
"""
function wxbutton_create(parent::Ptr{Cvoid}, id::Integer, label::Ptr{Cvoid},
                         x::Integer, y::Integer, w::Integer, h::Integer, style::Integer)
    @ccall $(ffi(:wxButton_Create))(
        parent::Ptr{Cvoid},
        id::Cint,
        label::Ptr{Cvoid},
        x::Cint, y::Cint,
        w::Cint, h::Cint,
        style::Cint
    )::Ptr{Cvoid}
end

"""
    wxbutton_setdefault(button)

Set this button as the default button in its top-level window.
"""
function wxbutton_setdefault(button::Ptr{Cvoid})
    @ccall $(ffi(:wxButton_SetDefault))(button::Ptr{Cvoid})::Cvoid
end

"""
    wxbutton_setbackgroundcolour(button, colour) -> Bool

Set the button's background colour. Returns true on success.
"""
function wxbutton_setbackgroundcolour(button::Ptr{Cvoid}, colour::Ptr{Cvoid})
    @ccall $(ffi(:wxButton_SetBackgroundColour))(
        button::Ptr{Cvoid},
        colour::Ptr{Cvoid}
    )::Cint
end

# =============================================================================
# wxStaticText
# =============================================================================

"""
    wxstatictext_create(parent, id, label, x, y, w, h, style) -> Ptr{Cvoid}

Create a new wxStaticText (label widget). label is a wxString*.
"""
function wxstatictext_create(parent::Ptr{Cvoid}, id::Integer, label::Ptr{Cvoid},
                             x::Integer, y::Integer, w::Integer, h::Integer, style::Integer)
    @ccall $(ffi(:wxStaticText_Create))(
        parent::Ptr{Cvoid},
        id::Cint,
        label::Ptr{Cvoid},
        x::Cint, y::Cint,
        w::Cint, h::Cint,
        style::Cint
    )::Ptr{Cvoid}
end

# =============================================================================
# wxTextCtrl
# =============================================================================

"""
    wxtextctrl_create(parent, id, value, x, y, w, h, style) -> Ptr{Cvoid}

Create a new wxTextCtrl. value is a wxString* (initial text). style is long.
"""
function wxtextctrl_create(parent::Ptr{Cvoid}, id::Integer, value::Ptr{Cvoid},
                           x::Integer, y::Integer, w::Integer, h::Integer, style::Integer)
    @ccall $(ffi(:wxTextCtrl_Create))(
        parent::Ptr{Cvoid},
        id::Cint,
        value::Ptr{Cvoid},
        x::Cint, y::Cint,
        w::Cint, h::Cint,
        style::Clong
    )::Ptr{Cvoid}
end

"""
    wxtextctrl_getvalue(textctrl) -> Ptr{Cvoid}

Get the text content. Returns wxString*.
"""
function wxtextctrl_getvalue(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_GetValue))(textctrl::Ptr{Cvoid})::Ptr{Cvoid}
end

"""
    wxtextctrl_setvalue(textctrl, value)

Set the text content. value is a wxString*.
"""
function wxtextctrl_setvalue(textctrl::Ptr{Cvoid}, value::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_SetValue))(
        textctrl::Ptr{Cvoid},
        value::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxtextctrl_changevalue(textctrl, value)

Change the text content without generating a text change event. value is a wxString*.
"""
function wxtextctrl_changevalue(textctrl::Ptr{Cvoid}, value::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_ChangeValue))(
        textctrl::Ptr{Cvoid},
        value::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxtextctrl_getlinetext(textctrl, line) -> Ptr{Cvoid}

Get the text of a specific line. Returns wxString*.
"""
function wxtextctrl_getlinetext(textctrl::Ptr{Cvoid}, line::Integer)
    @ccall $(ffi(:wxTextCtrl_GetLineText))(
        textctrl::Ptr{Cvoid},
        line::Clong
    )::Ptr{Cvoid}
end

"""
    wxtextctrl_getnumberoflines(textctrl) -> Int

Get the number of lines in the text control.
"""
function wxtextctrl_getnumberoflines(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_GetNumberOfLines))(textctrl::Ptr{Cvoid})::Cint
end

"""
    wxtextctrl_getlinelength(textctrl, line) -> Int

Get the length of a specific line.
"""
function wxtextctrl_getlinelength(textctrl::Ptr{Cvoid}, line::Integer)
    @ccall $(ffi(:wxTextCtrl_GetLineLength))(
        textctrl::Ptr{Cvoid},
        line::Clong
    )::Cint
end

"""
    wxtextctrl_getinsertionpoint(textctrl) -> Int

Get the current insertion point (cursor position).
"""
function wxtextctrl_getinsertionpoint(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_GetInsertionPoint))(textctrl::Ptr{Cvoid})::Clong
end

"""
    wxtextctrl_setinsertionpoint(textctrl, pos)

Set the insertion point (cursor position).
"""
function wxtextctrl_setinsertionpoint(textctrl::Ptr{Cvoid}, pos::Integer)
    @ccall $(ffi(:wxTextCtrl_SetInsertionPoint))(
        textctrl::Ptr{Cvoid},
        pos::Clong
    )::Cvoid
end

"""
    wxtextctrl_setinsertionpointend(textctrl)

Set the insertion point to the end of the text.
"""
function wxtextctrl_setinsertionpointend(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_SetInsertionPointEnd))(textctrl::Ptr{Cvoid})::Cvoid
end

"""
    wxtextctrl_getlastposition(textctrl) -> Int

Get the position of the last character.
"""
function wxtextctrl_getlastposition(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_GetLastPosition))(textctrl::Ptr{Cvoid})::Clong
end

"""
    wxtextctrl_getselection(textctrl) -> Tuple{Int, Int}

Get the current selection range (from, to).
"""
function wxtextctrl_getselection(textctrl::Ptr{Cvoid})
    from = Ref{Clong}(0)
    to = Ref{Clong}(0)
    @ccall $(ffi(:wxTextCtrl_GetSelection))(
        textctrl::Ptr{Cvoid},
        from::Ptr{Clong},
        to::Ptr{Clong}
    )::Cvoid
    (Int(from[]), Int(to[]))
end

"""
    wxtextctrl_setselection(textctrl, from, to)

Select a range of text.
"""
function wxtextctrl_setselection(textctrl::Ptr{Cvoid}, from::Integer, to::Integer)
    @ccall $(ffi(:wxTextCtrl_SetSelection))(
        textctrl::Ptr{Cvoid},
        from::Clong,
        to::Clong
    )::Cvoid
end

"""
    wxtextctrl_writetext(textctrl, text)

Insert text at the current insertion point. text is a wxString*.
"""
function wxtextctrl_writetext(textctrl::Ptr{Cvoid}, text::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_WriteText))(
        textctrl::Ptr{Cvoid},
        text::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxtextctrl_replace(textctrl, from, to, value)

Replace text in range [from, to). value is a wxString*.
"""
function wxtextctrl_replace(textctrl::Ptr{Cvoid}, from::Integer, to::Integer, value::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_Replace))(
        textctrl::Ptr{Cvoid},
        from::Clong,
        to::Clong,
        value::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxtextctrl_remove(textctrl, from, to)

Remove text in range [from, to).
"""
function wxtextctrl_remove(textctrl::Ptr{Cvoid}, from::Integer, to::Integer)
    @ccall $(ffi(:wxTextCtrl_Remove))(
        textctrl::Ptr{Cvoid},
        from::Clong,
        to::Clong
    )::Cvoid
end

"""
    wxtextctrl_clear(textctrl)

Clear all text.
"""
function wxtextctrl_clear(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_Clear))(textctrl::Ptr{Cvoid})::Cvoid
end

"""
    wxtextctrl_ismodified(textctrl) -> Bool

Returns true if the text has been modified.
"""
function wxtextctrl_ismodified(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_IsModified))(textctrl::Ptr{Cvoid})::Cint
end

"""
    wxtextctrl_iseditable(textctrl) -> Bool

Returns true if the text is editable.
"""
function wxtextctrl_iseditable(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_IsEditable))(textctrl::Ptr{Cvoid})::Cint
end

"""
    wxtextctrl_seteditable(textctrl, editable)

Set whether the text is editable.
"""
function wxtextctrl_seteditable(textctrl::Ptr{Cvoid}, editable::Bool)
    @ccall $(ffi(:wxTextCtrl_SetEditable))(
        textctrl::Ptr{Cvoid},
        editable::Cint
    )::Cvoid
end

"""
    wxtextctrl_discardedits(textctrl)

Reset the modified flag.
"""
function wxtextctrl_discardedits(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_DiscardEdits))(textctrl::Ptr{Cvoid})::Cvoid
end

"""
    wxtextctrl_copy(textctrl)

Copy selected text to clipboard.
"""
function wxtextctrl_copy(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_Copy))(textctrl::Ptr{Cvoid})::Cvoid
end

"""
    wxtextctrl_cut(textctrl)

Cut selected text to clipboard.
"""
function wxtextctrl_cut(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_Cut))(textctrl::Ptr{Cvoid})::Cvoid
end

"""
    wxtextctrl_paste(textctrl)

Paste text from clipboard.
"""
function wxtextctrl_paste(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_Paste))(textctrl::Ptr{Cvoid})::Cvoid
end

"""
    wxtextctrl_undo(textctrl)

Undo the last edit operation.
"""
function wxtextctrl_undo(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_Undo))(textctrl::Ptr{Cvoid})::Cvoid
end

"""
    wxtextctrl_redo(textctrl)

Redo the last undone edit operation.
"""
function wxtextctrl_redo(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_Redo))(textctrl::Ptr{Cvoid})::Cvoid
end

"""
    wxtextctrl_cancopy(textctrl) -> Bool

Returns true if there is selected text that can be copied.
"""
function wxtextctrl_cancopy(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_CanCopy))(textctrl::Ptr{Cvoid})::Cint
end

"""
    wxtextctrl_cancut(textctrl) -> Bool

Returns true if there is selected text that can be cut.
"""
function wxtextctrl_cancut(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_CanCut))(textctrl::Ptr{Cvoid})::Cint
end

"""
    wxtextctrl_canpaste(textctrl) -> Bool

Returns true if there is data on the clipboard that can be pasted.
"""
function wxtextctrl_canpaste(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_CanPaste))(textctrl::Ptr{Cvoid})::Cint
end

"""
    wxtextctrl_canundo(textctrl) -> Bool

Returns true if there are actions to undo.
"""
function wxtextctrl_canundo(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_CanUndo))(textctrl::Ptr{Cvoid})::Cint
end

"""
    wxtextctrl_canredo(textctrl) -> Bool

Returns true if there are actions to redo.
"""
function wxtextctrl_canredo(textctrl::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_CanRedo))(textctrl::Ptr{Cvoid})::Cint
end

"""
    wxtextctrl_showposition(textctrl, pos)

Scroll the control to make the given position visible.
"""
function wxtextctrl_showposition(textctrl::Ptr{Cvoid}, pos::Integer)
    @ccall $(ffi(:wxTextCtrl_ShowPosition))(
        textctrl::Ptr{Cvoid},
        pos::Clong
    )::Cvoid
end

"""
    wxtextctrl_loadfile(textctrl, file) -> Bool

Load a file into the text control. file is a wxString*.
"""
function wxtextctrl_loadfile(textctrl::Ptr{Cvoid}, file::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_LoadFile))(
        textctrl::Ptr{Cvoid},
        file::Ptr{Cvoid}
    )::Cint
end

"""
    wxtextctrl_savefile(textctrl, file) -> Bool

Save the text control contents to a file. file is a wxString*.
"""
function wxtextctrl_savefile(textctrl::Ptr{Cvoid}, file::Ptr{Cvoid})
    @ccall $(ffi(:wxTextCtrl_SaveFile))(
        textctrl::Ptr{Cvoid},
        file::Ptr{Cvoid}
    )::Cint
end

# =============================================================================
# wxCheckBox
# =============================================================================

"""
    wxcheckbox_create(parent, id, label, x, y, w, h, style) -> Ptr{Cvoid}

Create a new wxCheckBox. label is a wxString*.
"""
function wxcheckbox_create(parent::Ptr{Cvoid}, id::Integer, label::Ptr{Cvoid},
                           x::Integer, y::Integer, w::Integer, h::Integer, style::Integer)
    @ccall $(ffi(:wxCheckBox_Create))(
        parent::Ptr{Cvoid},
        id::Cint,
        label::Ptr{Cvoid},
        x::Cint, y::Cint,
        w::Cint, h::Cint,
        style::Cint
    )::Ptr{Cvoid}
end

"""
    wxcheckbox_getvalue(checkbox) -> Bool

Get the check state. Returns true if checked.
"""
function wxcheckbox_getvalue(checkbox::Ptr{Cvoid})
    @ccall $(ffi(:wxCheckBox_GetValue))(checkbox::Ptr{Cvoid})::Cint
end

"""
    wxcheckbox_setvalue(checkbox, value)

Set the check state.
"""
function wxcheckbox_setvalue(checkbox::Ptr{Cvoid}, value::Bool)
    @ccall $(ffi(:wxCheckBox_SetValue))(
        checkbox::Ptr{Cvoid},
        value::Cint
    )::Cvoid
end

"""
    wxcheckbox_delete(checkbox)

Delete the checkbox.
"""
function wxcheckbox_delete(checkbox::Ptr{Cvoid})
    @ccall $(ffi(:wxCheckBox_Delete))(checkbox::Ptr{Cvoid})::Cvoid
end

# =============================================================================
# wxComboBox
# =============================================================================

"""
    wxcombobox_create(parent, id, value, x, y, w, h, n, choices, style) -> Ptr{Cvoid}

Create a new wxComboBox. value is a wxString*, choices is an array of char* strings.
"""
function wxcombobox_create(parent::Ptr{Cvoid}, id::Integer, value::Ptr{Cvoid},
                           x::Integer, y::Integer, w::Integer, h::Integer,
                           n::Integer, choices::Ptr{Ptr{UInt8}}, style::Integer)
    @ccall $(ffi(:wxComboBox_Create))(
        parent::Ptr{Cvoid},
        id::Cint,
        value::Ptr{Cvoid},
        x::Cint, y::Cint,
        w::Cint, h::Cint,
        n::Cint,
        choices::Ptr{Ptr{UInt8}},
        style::Cint
    )::Ptr{Cvoid}
end

"""
    wxcombobox_append(combobox, item)

Append an item to the combobox. item is a wxString*.
"""
function wxcombobox_append(combobox::Ptr{Cvoid}, item::Ptr{Cvoid})
    @ccall $(ffi(:wxComboBox_Append))(
        combobox::Ptr{Cvoid},
        item::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxcombobox_clear(combobox)

Remove all items from the combobox.
"""
function wxcombobox_clear(combobox::Ptr{Cvoid})
    @ccall $(ffi(:wxComboBox_Clear))(combobox::Ptr{Cvoid})::Cvoid
end

"""
    wxcombobox_delete(combobox, n)

Delete item at index n.
"""
function wxcombobox_delete(combobox::Ptr{Cvoid}, n::Integer)
    @ccall $(ffi(:wxComboBox_Delete))(
        combobox::Ptr{Cvoid},
        n::Cint
    )::Cvoid
end

"""
    wxcombobox_getcount(combobox) -> Int

Get the number of items.
"""
function wxcombobox_getcount(combobox::Ptr{Cvoid})
    @ccall $(ffi(:wxComboBox_GetCount))(combobox::Ptr{Cvoid})::Cint
end

"""
    wxcombobox_getselection(combobox) -> Int

Get the index of the selected item (-1 if none).
"""
function wxcombobox_getselection(combobox::Ptr{Cvoid})
    @ccall $(ffi(:wxComboBox_GetSelection))(combobox::Ptr{Cvoid})::Cint
end

"""
    wxcombobox_setselection(combobox, n)

Select item at index n.
"""
function wxcombobox_setselection(combobox::Ptr{Cvoid}, n::Integer)
    @ccall $(ffi(:wxComboBox_SetSelection))(
        combobox::Ptr{Cvoid},
        n::Cint
    )::Cvoid
end

"""
    wxcombobox_getstring(combobox, n) -> Ptr{Cvoid}

Get the string at index n. Returns wxString*.
"""
function wxcombobox_getstring(combobox::Ptr{Cvoid}, n::Integer)
    @ccall $(ffi(:wxComboBox_GetString))(
        combobox::Ptr{Cvoid},
        n::Cint
    )::Ptr{Cvoid}
end

"""
    wxcombobox_getstringselection(combobox) -> Ptr{Cvoid}

Get the currently selected string. Returns wxString*.
"""
function wxcombobox_getstringselection(combobox::Ptr{Cvoid})
    @ccall $(ffi(:wxComboBox_GetStringSelection))(combobox::Ptr{Cvoid})::Ptr{Cvoid}
end

"""
    wxcombobox_getvalue(combobox) -> Ptr{Cvoid}

Get the text field value. Returns wxString*.
"""
function wxcombobox_getvalue(combobox::Ptr{Cvoid})
    @ccall $(ffi(:wxComboBox_GetValue))(combobox::Ptr{Cvoid})::Ptr{Cvoid}
end

"""
    wxcombobox_setvalue(combobox, value)

Set the text field value. value is a wxString*.
"""
function wxcombobox_setvalue(combobox::Ptr{Cvoid}, value::Ptr{Cvoid})
    @ccall $(ffi(:wxComboBox_SetValue))(
        combobox::Ptr{Cvoid},
        value::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxcombobox_findstring(combobox, s) -> Int

Find a string in the combobox. Returns index or -1 if not found. s is a wxString*.
"""
function wxcombobox_findstring(combobox::Ptr{Cvoid}, s::Ptr{Cvoid})
    @ccall $(ffi(:wxComboBox_FindString))(
        combobox::Ptr{Cvoid},
        s::Ptr{Cvoid}
    )::Cint
end

"""
    wxcombobox_seteditable(combobox, editable)

Set whether the text field is editable.
"""
function wxcombobox_seteditable(combobox::Ptr{Cvoid}, editable::Bool)
    @ccall $(ffi(:wxComboBox_SetEditable))(
        combobox::Ptr{Cvoid},
        editable::Cint
    )::Cvoid
end

# =============================================================================
# wxListBox
# =============================================================================

"""
    wxlistbox_create(parent, id, x, y, w, h, n, choices, style) -> Ptr{Cvoid}

Create a new wxListBox. choices is an array of char* strings.
"""
function wxlistbox_create(parent::Ptr{Cvoid}, id::Integer,
                          x::Integer, y::Integer, w::Integer, h::Integer,
                          n::Integer, choices::Ptr{Ptr{UInt8}}, style::Integer)
    @ccall $(ffi(:wxListBox_Create))(
        parent::Ptr{Cvoid},
        id::Cint,
        x::Cint, y::Cint,
        w::Cint, h::Cint,
        n::Cint,
        choices::Ptr{Ptr{UInt8}},
        style::Cint
    )::Ptr{Cvoid}
end

"""
    wxlistbox_append(listbox, item)

Append an item to the listbox. item is a wxString*.
"""
function wxlistbox_append(listbox::Ptr{Cvoid}, item::Ptr{Cvoid})
    @ccall $(ffi(:wxListBox_Append))(
        listbox::Ptr{Cvoid},
        item::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxlistbox_clear(listbox)

Remove all items from the listbox.
"""
function wxlistbox_clear(listbox::Ptr{Cvoid})
    @ccall $(ffi(:wxListBox_Clear))(listbox::Ptr{Cvoid})::Cvoid
end

"""
    wxlistbox_delete(listbox, n)

Delete item at index n.
"""
function wxlistbox_delete(listbox::Ptr{Cvoid}, n::Integer)
    @ccall $(ffi(:wxListBox_Delete))(
        listbox::Ptr{Cvoid},
        n::Cint
    )::Cvoid
end

"""
    wxlistbox_getcount(listbox) -> Int

Get the number of items.
"""
function wxlistbox_getcount(listbox::Ptr{Cvoid})
    @ccall $(ffi(:wxListBox_GetCount))(listbox::Ptr{Cvoid})::Cint
end

"""
    wxlistbox_getselection(listbox) -> Int

Get the index of the selected item (-1 if none). For single-selection listboxes.
"""
function wxlistbox_getselection(listbox::Ptr{Cvoid})
    @ccall $(ffi(:wxListBox_GetSelection))(listbox::Ptr{Cvoid})::Cint
end

"""
    wxlistbox_setselection(listbox, n, select)

Select or deselect an item.
"""
function wxlistbox_setselection(listbox::Ptr{Cvoid}, n::Integer, select::Bool)
    @ccall $(ffi(:wxListBox_SetSelection))(
        listbox::Ptr{Cvoid},
        n::Cint,
        select::Cint
    )::Cvoid
end

"""
    wxlistbox_getstring(listbox, n) -> Ptr{Cvoid}

Get the string at index n. Returns wxString*.
"""
function wxlistbox_getstring(listbox::Ptr{Cvoid}, n::Integer)
    @ccall $(ffi(:wxListBox_GetString))(
        listbox::Ptr{Cvoid},
        n::Cint
    )::Ptr{Cvoid}
end

"""
    wxlistbox_setstring(listbox, n, s)

Set the string at index n. s is a wxString*.
"""
function wxlistbox_setstring(listbox::Ptr{Cvoid}, n::Integer, s::Ptr{Cvoid})
    @ccall $(ffi(:wxListBox_SetString))(
        listbox::Ptr{Cvoid},
        n::Cint,
        s::Ptr{Cvoid}
    )::Cvoid
end

"""
    wxlistbox_findstring(listbox, s) -> Int

Find a string. Returns index or -1 if not found. s is a wxString*.
"""
function wxlistbox_findstring(listbox::Ptr{Cvoid}, s::Ptr{Cvoid})
    @ccall $(ffi(:wxListBox_FindString))(
        listbox::Ptr{Cvoid},
        s::Ptr{Cvoid}
    )::Cint
end

"""
    wxlistbox_isselected(listbox, n) -> Bool

Returns true if item at index n is selected.
"""
function wxlistbox_isselected(listbox::Ptr{Cvoid}, n::Integer)
    @ccall $(ffi(:wxListBox_IsSelected))(
        listbox::Ptr{Cvoid},
        n::Cint
    )::Cint
end

"""
    wxlistbox_setfirstitem(listbox, n)

Scroll the listbox to make item n the first visible item.
"""
function wxlistbox_setfirstitem(listbox::Ptr{Cvoid}, n::Integer)
    @ccall $(ffi(:wxListBox_SetFirstItem))(
        listbox::Ptr{Cvoid},
        n::Cint
    )::Cvoid
end

"""
    wxlistbox_setstringselection(listbox, str, sel)

Select or deselect an item by string. str is a wxString*.
"""
function wxlistbox_setstringselection(listbox::Ptr{Cvoid}, str::Ptr{Cvoid}, sel::Bool)
    @ccall $(ffi(:wxListBox_SetStringSelection))(
        listbox::Ptr{Cvoid},
        str::Ptr{Cvoid},
        sel::Cint
    )::Cvoid
end
