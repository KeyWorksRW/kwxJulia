# Main module for kwxJulia - Julia bindings for wxWidgets

module WxWidgets

# Core infrastructure
include("core/library.jl")
include("core/types.jl")
include("core/strings.jl")
include("core/constants.jl")
include("core/events.jl")

# FFI declarations (raw @ccall wrappers)
include("ffi/app.jl")
include("ffi/window.jl")
include("ffi/frame.jl")
include("ffi/events.jl")
include("ffi/controls.jl")
include("ffi/sizers.jl")

# High-level API (idiomatic Julia wrappers)
include("widgets/app.jl")
include("widgets/window.jl")
include("widgets/frame.jl")
include("widgets/events.jl")
include("widgets/button.jl")
include("widgets/statictext.jl")
include("widgets/textctrl.jl")
include("widgets/checkbox.jl")
include("widgets/combobox.jl")
include("widgets/listbox.jl")
include("widgets/sizers.jl")

# Exports
export WxString, WxFrame, WxEvent
export WxButton, WxStaticText, WxTextCtrl, WxCheckBox, WxComboBox, WxListBox
export WxBoxSizer, WxGridSizer, WxFlexGridSizer, WxGridBagSizer, WxWrapSizer
export run_app, exit_app, set_top_window, set_exit_on_frame_delete

# Window functions
export show_window, hide, close, destroy!
export set_size, get_size, set_position, get_position
export set_label, get_label
export set_sizer, layout, refresh, update
export enable, is_enabled, is_shown, set_focus
export centre, center

# Frame functions
export create_status_bar, set_status_text, push_status_text, pop_status_text
export set_menu_bar, get_menu_bar, set_tool_bar, get_tool_bar

# Event handling
export wx_connect!, wx_disconnect!, on_close!

# Button functions
export set_default!, on_click!

# TextCtrl functions
export get_value, set_value!, change_value!
export get_line_text, get_number_of_lines, get_line_length
export get_insertion_point, set_insertion_point!, set_insertion_point_end!, get_last_position
export get_selection, set_selection!
export write_text!, replace_text!, remove_text!, clear!
export is_modified, is_editable, set_editable!, discard_edits!
export copy!, cut!, paste!, undo!, redo!
export can_copy, can_cut, can_paste, can_undo, can_redo
export load_file!, save_file!
export on_text_changed!, on_text_enter!

# CheckBox functions
export is_checked, set_checked!, on_checkbox!

# ComboBox functions
export append!, get_count, get_string, get_string_selection
export find_string, on_combobox!

# ListBox functions
export delete_item!, is_selected, set_string!
export set_first_item!, on_listbox!, on_listbox_dclick!

# Sizer functions
export add!, add_spacer!, add_stretch_spacer!, insert!, prepend!
export fit!, fit_inside!, set_size_hints!, set_min_size!
export sizer_layout!, sizer_clear!, detach!, sizer_hide!, sizer_show!
export set_item_min_size!
export get_orientation, get_cols, get_rows, get_hgap, get_vgap
export set_cols!, set_rows!, set_hgap!, set_vgap!
export add_growable_col!, add_growable_row!, remove_growable_col!, remove_growable_row!
export set_empty_cell_size!, get_empty_cell_size
export set_orientation!

# Constants (exported as Refs)
export wxDEFAULT_FRAME_STYLE
export wxID_ANY, wxID_OK, wxID_CANCEL
# TextCtrl styles
export wxTE_MULTILINE, wxTE_READONLY, wxTE_PROCESS_TAB, wxTE_PROCESS_ENTER
export wxTE_RICH, wxTE_RICH2, wxTE_PASSWORD, wxTE_NO_VSCROLL
export wxTE_AUTO_URL, wxTE_NOHIDESEL, wxTE_LEFT, wxTE_RIGHT, wxTE_CENTRE, wxTE_WORDWRAP
# ComboBox styles
export wxCB_SIMPLE, wxCB_SORT, wxCB_READONLY, wxCB_DROPDOWN
# ListBox styles
export wxLB_SORT, wxLB_SINGLE, wxLB_MULTIPLE, wxLB_EXTENDED, wxLB_NEEDED_SB, wxLB_ALWAYS_SB
# Button styles
export wxBU_EXACTFIT, wxBU_LEFT, wxBU_TOP, wxBU_RIGHT, wxBU_BOTTOM
# StaticText styles
export wxST_NO_AUTORESIZE
# Layout/alignment flags
export wxHORIZONTAL, wxVERTICAL, wxALL, wxEXPAND, wxGROW
export wxALIGN_CENTER, wxALIGN_LEFT, wxALIGN_RIGHT, wxALIGN_TOP, wxALIGN_BOTTOM
export wxALIGN_CENTER_HORIZONTAL, wxALIGN_CENTER_VERTICAL
export wxLEFT, wxRIGHT, wxTOP, wxBOTTOM, wxBOTH
export wxSHAPED, wxSTRETCH_NOT

# Event types (exported as Refs)
export wxEVT_BUTTON, wxEVT_CLOSE_WINDOW, wxEVT_MENU
export wxEVT_LEFT_DOWN, wxEVT_LEFT_UP, wxEVT_PAINT, wxEVT_SIZE
export wxEVT_CHECKBOX, wxEVT_COMBOBOX
export wxEVT_LISTBOX, wxEVT_LISTBOX_DCLICK
export wxEVT_TEXT, wxEVT_TEXT_ENTER

"""
Module initialization - loads libraries and constants.
Called automatically when the module is first loaded.
"""
function __init__()
    try
        load_libraries!()
        load_constants!()
        load_events!()
    catch e
        @error "Failed to initialize WxWidgets module" exception=(e, catch_backtrace())
        rethrow(e)
    end
end

end # module WxWidgets
