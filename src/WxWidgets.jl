# Main module for kwxJulia - Julia bindings for wxWidgets via kwxFFI

module WxWidgets

using Libdl

# Generated FFI module — must come first so core files can `using ..KwxFFI`
include(joinpath(@__DIR__, "..", "wx", "KwxFFI_gen.jl"))
using .KwxFFI

# Core infrastructure (order matters: kwxapp needs KwxFFI, strings needs kwxapp)
include("core/types.jl")
include("core/kwxapp.jl")
include("core/strings.jl")

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

# --- Exports ---

# KwxFFI submodule (for constants, events, and raw FFI access)
export KwxFFI

# Types
export wxString, wxFrame, wxEvent
export wxButton, wxStaticText, wxTextCtrl, wxCheckBox, wxComboBox, wxListBox
export wxBoxSizer, wxGridSizer, wxFlexGridSizer, wxGridBagSizer, wxWrapSizer

# Application lifecycle
export run_app, exit_app, set_top_window, set_exit_on_frame_delete

# Window functions
export show_window, hide, close, destroy!
export set_size, get_size, set_position, get_position
export set_label, get_label
export set_sizer, layout, refresh, update
export enable, disable, is_enabled, is_shown, set_focus
export centre, center

# Frame functions
export create_status_bar, set_status_text
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

"""
Module initialization - adds kwxFFI DLL directory to the library search path.
Called automatically when the module is first loaded.
"""
function __init__()
    # Add kwxFFI DLL directory to Julia's library search path
    dlldir = joinpath(@__DIR__, "..", "bin", "Release")
    if isdir(dlldir) && !(dlldir in Libdl.DL_LOAD_PATH)
        pushfirst!(Libdl.DL_LOAD_PATH, dlldir)
    end
end

end # module WxWidgets
