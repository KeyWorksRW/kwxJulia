# wxWidgets Event Type Constants
# Loaded at init time via kwxFFI exp*() functions

# Command events (used by Phase 5+)
const wxEVT_BUTTON = Ref{Cint}(0)
const wxEVT_CLOSE_WINDOW = Ref{Cint}(0)
const wxEVT_MENU = Ref{Cint}(0)

# Mouse events
const wxEVT_LEFT_DOWN = Ref{Cint}(0)
const wxEVT_LEFT_UP = Ref{Cint}(0)

# Window events
const wxEVT_PAINT = Ref{Cint}(0)
const wxEVT_SIZE = Ref{Cint}(0)

# Control events (Phase 6)
const wxEVT_CHECKBOX = Ref{Cint}(0)
const wxEVT_COMBOBOX = Ref{Cint}(0)
const wxEVT_LISTBOX = Ref{Cint}(0)
const wxEVT_LISTBOX_DCLICK = Ref{Cint}(0)
const wxEVT_TEXT = Ref{Cint}(0)
const wxEVT_TEXT_ENTER = Ref{Cint}(0)

function load_events!()
    wxEVT_BUTTON[] = @ccall $(ffi(:expwxEVT_COMMAND_BUTTON_CLICKED))()::Cint
    wxEVT_CLOSE_WINDOW[] = @ccall $(ffi(:expwxEVT_CLOSE_WINDOW))()::Cint
    wxEVT_MENU[] = @ccall $(ffi(:expwxEVT_COMMAND_MENU_SELECTED))()::Cint
    wxEVT_LEFT_DOWN[] = @ccall $(ffi(:expwxEVT_LEFT_DOWN))()::Cint
    wxEVT_LEFT_UP[] = @ccall $(ffi(:expwxEVT_LEFT_UP))()::Cint
    wxEVT_PAINT[] = @ccall $(ffi(:expwxEVT_PAINT))()::Cint
    wxEVT_SIZE[] = @ccall $(ffi(:expwxEVT_SIZE))()::Cint

    # Control events (Phase 6)
    wxEVT_CHECKBOX[] = @ccall $(ffi(:expwxEVT_COMMAND_CHECKBOX_CLICKED))()::Cint
    wxEVT_COMBOBOX[] = @ccall $(ffi(:expwxEVT_COMMAND_COMBOBOX_SELECTED))()::Cint
    wxEVT_LISTBOX[] = @ccall $(ffi(:expwxEVT_COMMAND_LISTBOX_SELECTED))()::Cint
    wxEVT_LISTBOX_DCLICK[] = @ccall $(ffi(:expwxEVT_COMMAND_LISTBOX_DOUBLECLICKED))()::Cint
    wxEVT_TEXT[] = @ccall $(ffi(:expwxEVT_COMMAND_TEXT_UPDATED))()::Cint
    wxEVT_TEXT_ENTER[] = @ccall $(ffi(:expwxEVT_COMMAND_TEXT_ENTER))()::Cint
end
