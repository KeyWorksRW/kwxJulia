# wxWidgets Constants (Style flags, IDs, etc.)
# Loaded at init time via kwxFFI exp*() functions

# Frame styles
const wxDEFAULT_FRAME_STYLE = Ref{Cint}(0)

# IDs
const wxID_ANY = Ref{Cint}(0)
const wxID_OK = Ref{Cint}(0)
const wxID_CANCEL = Ref{Cint}(0)

# TextCtrl styles
const wxTE_MULTILINE = Ref{Cint}(0)
const wxTE_READONLY = Ref{Cint}(0)
const wxTE_PROCESS_TAB = Ref{Cint}(0)
const wxTE_PROCESS_ENTER = Ref{Cint}(0)
const wxTE_RICH = Ref{Cint}(0)
const wxTE_RICH2 = Ref{Cint}(0)
const wxTE_PASSWORD = Ref{Cint}(0)
const wxTE_NO_VSCROLL = Ref{Cint}(0)
const wxTE_AUTO_URL = Ref{Cint}(0)
const wxTE_NOHIDESEL = Ref{Cint}(0)
const wxTE_LEFT = Ref{Cint}(0)
const wxTE_RIGHT = Ref{Cint}(0)
const wxTE_CENTRE = Ref{Cint}(0)
const wxTE_WORDWRAP = Ref{Cint}(0)

# ComboBox styles
const wxCB_SIMPLE = Ref{Cint}(0)
const wxCB_SORT = Ref{Cint}(0)
const wxCB_READONLY = Ref{Cint}(0)
const wxCB_DROPDOWN = Ref{Cint}(0)

# ListBox styles
const wxLB_SORT = Ref{Cint}(0)
const wxLB_SINGLE = Ref{Cint}(0)
const wxLB_MULTIPLE = Ref{Cint}(0)
const wxLB_EXTENDED = Ref{Cint}(0)
const wxLB_NEEDED_SB = Ref{Cint}(0)
const wxLB_ALWAYS_SB = Ref{Cint}(0)

# Button styles
const wxBU_EXACTFIT = Ref{Cint}(0)
const wxBU_LEFT = Ref{Cint}(0)
const wxBU_TOP = Ref{Cint}(0)
const wxBU_RIGHT = Ref{Cint}(0)
const wxBU_BOTTOM = Ref{Cint}(0)

# StaticText styles
const wxST_NO_AUTORESIZE = Ref{Cint}(0)

# Layout/alignment flags (used by sizers and controls)
const wxHORIZONTAL = Ref{Cint}(0)
const wxVERTICAL = Ref{Cint}(0)
const wxALL = Ref{Cint}(0)
const wxEXPAND = Ref{Cint}(0)
const wxGROW = Ref{Cint}(0)
const wxALIGN_CENTER = Ref{Cint}(0)
const wxALIGN_LEFT = Ref{Cint}(0)
const wxALIGN_RIGHT = Ref{Cint}(0)
const wxALIGN_TOP = Ref{Cint}(0)
const wxALIGN_BOTTOM = Ref{Cint}(0)
const wxLEFT = Ref{Cint}(0)
const wxRIGHT = Ref{Cint}(0)
const wxTOP = Ref{Cint}(0)
const wxBOTTOM = Ref{Cint}(0)
const wxBOTH = Ref{Cint}(0)
const wxALIGN_CENTER_HORIZONTAL = Ref{Cint}(0)
const wxALIGN_CENTER_VERTICAL = Ref{Cint}(0)
const wxSHAPED = Ref{Cint}(0)
const wxSTRETCH_NOT = Ref{Cint}(0)

function load_constants!()
    # Frame styles
    wxDEFAULT_FRAME_STYLE[] = @ccall $(ffi(:expwxDEFAULT_FRAME_STYLE))()::Cint

    # IDs
    wxID_ANY[] = @ccall $(ffi(:expwxID_ANY))()::Cint
    wxID_OK[] = @ccall $(ffi(:expwxID_OK))()::Cint
    wxID_CANCEL[] = @ccall $(ffi(:expwxID_CANCEL))()::Cint

    # TextCtrl styles
    wxTE_MULTILINE[] = @ccall $(ffi(:expwxTE_MULTILINE))()::Cint
    wxTE_READONLY[] = @ccall $(ffi(:expwxTE_READONLY))()::Cint
    wxTE_PROCESS_TAB[] = @ccall $(ffi(:expwxTE_PROCESS_TAB))()::Cint
    wxTE_PROCESS_ENTER[] = @ccall $(ffi(:expwxTE_PROCESS_ENTER))()::Cint
    wxTE_RICH[] = @ccall $(ffi(:expwxTE_RICH))()::Cint
    wxTE_RICH2[] = @ccall $(ffi(:expwxTE_RICH2))()::Cint
    wxTE_PASSWORD[] = @ccall $(ffi(:expwxTE_PASSWORD))()::Cint
    wxTE_NO_VSCROLL[] = @ccall $(ffi(:expwxTE_NO_VSCROLL))()::Cint
    wxTE_AUTO_URL[] = @ccall $(ffi(:expwxTE_AUTO_URL))()::Cint
    wxTE_NOHIDESEL[] = @ccall $(ffi(:expwxTE_NOHIDESEL))()::Cint
    wxTE_LEFT[] = @ccall $(ffi(:expwxTE_LEFT))()::Cint
    wxTE_RIGHT[] = @ccall $(ffi(:expwxTE_RIGHT))()::Cint
    wxTE_CENTRE[] = @ccall $(ffi(:expwxTE_CENTRE))()::Cint
    wxTE_WORDWRAP[] = @ccall $(ffi(:expwxTE_WORDWRAP))()::Cint

    # ComboBox styles
    wxCB_SIMPLE[] = @ccall $(ffi(:expwxCB_SIMPLE))()::Cint
    wxCB_SORT[] = @ccall $(ffi(:expwxCB_SORT))()::Cint
    wxCB_READONLY[] = @ccall $(ffi(:expwxCB_READONLY))()::Cint
    wxCB_DROPDOWN[] = @ccall $(ffi(:expwxCB_DROPDOWN))()::Cint

    # ListBox styles
    wxLB_SORT[] = @ccall $(ffi(:expwxLB_SORT))()::Cint
    wxLB_SINGLE[] = @ccall $(ffi(:expwxLB_SINGLE))()::Cint
    wxLB_MULTIPLE[] = @ccall $(ffi(:expwxLB_MULTIPLE))()::Cint
    wxLB_EXTENDED[] = @ccall $(ffi(:expwxLB_EXTENDED))()::Cint
    wxLB_NEEDED_SB[] = @ccall $(ffi(:expwxLB_NEEDED_SB))()::Cint
    wxLB_ALWAYS_SB[] = @ccall $(ffi(:expwxLB_ALWAYS_SB))()::Cint

    # Button styles
    wxBU_EXACTFIT[] = @ccall $(ffi(:expwxBU_EXACTFIT))()::Cint
    wxBU_LEFT[] = @ccall $(ffi(:expwxBU_LEFT))()::Cint
    wxBU_TOP[] = @ccall $(ffi(:expwxBU_TOP))()::Cint
    wxBU_RIGHT[] = @ccall $(ffi(:expwxBU_RIGHT))()::Cint
    wxBU_BOTTOM[] = @ccall $(ffi(:expwxBU_BOTTOM))()::Cint

    # StaticText styles
    wxST_NO_AUTORESIZE[] = @ccall $(ffi(:expwxST_NO_AUTORESIZE))()::Cint

    # Layout/alignment flags
    wxHORIZONTAL[] = @ccall $(ffi(:expwxHORIZONTAL))()::Cint
    wxVERTICAL[] = @ccall $(ffi(:expwxVERTICAL))()::Cint
    wxALL[] = @ccall $(ffi(:expwxALL))()::Cint
    wxEXPAND[] = @ccall $(ffi(:expwxEXPAND))()::Cint
    wxGROW[] = @ccall $(ffi(:expwxGROW))()::Cint
    wxALIGN_CENTER[] = @ccall $(ffi(:expwxALIGN_CENTER))()::Cint
    wxALIGN_LEFT[] = @ccall $(ffi(:expwxALIGN_LEFT))()::Cint
    wxALIGN_RIGHT[] = @ccall $(ffi(:expwxALIGN_RIGHT))()::Cint
    wxALIGN_TOP[] = @ccall $(ffi(:expwxALIGN_TOP))()::Cint
    wxALIGN_BOTTOM[] = @ccall $(ffi(:expwxALIGN_BOTTOM))()::Cint
    wxLEFT[] = @ccall $(ffi(:expwxLEFT))()::Cint
    wxRIGHT[] = @ccall $(ffi(:expwxRIGHT))()::Cint
    wxTOP[] = @ccall $(ffi(:expwxTOP))()::Cint
    wxBOTTOM[] = @ccall $(ffi(:expwxBOTTOM))()::Cint
    wxBOTH[] = @ccall $(ffi(:expwxBOTH))()::Cint
    wxALIGN_CENTER_HORIZONTAL[] = @ccall $(ffi(:expwxALIGN_CENTER_HORIZONTAL))()::Cint
    wxALIGN_CENTER_VERTICAL[] = @ccall $(ffi(:expwxALIGN_CENTER_VERTICAL))()::Cint
    wxSHAPED[] = @ccall $(ffi(:expwxSHAPED))()::Cint
    wxSTRETCH_NOT[] = @ccall $(ffi(:expwxSTRETCH_NOT))()::Cint
end
