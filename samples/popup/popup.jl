# popup.jl — kwxJulia port of wxSamples/src/popup/popup.cpp
#
# The wxWidgets popup sample.  A "Popup wxWidgets App" frame shows two buttons
# that open a wxPopupTransientWindow (plain and scrolled variants) under the
# button that fired.  The popup contains a wxScrolledWindow with a static text,
# a button that toggles its own label, a wxSpinCtrl, a text control and a
# static text whose background highlights while the mouse is over its row.
# Every wxLogMessage of the C++ sample is mirrored into the frame's log window
# through a wxLogTextCtrl active target.
#
# Run from the repository root:
#   julia samples\popup\popup.jl
#
# Mapping of the C++ structure onto this port:
#   MyApp::OnInit                        -> the run_app block at the bottom
#   MyFrame                              -> build_frame() + frame_on_* handlers
#   MyDialog                             -> show_test_dialog()
#   SimpleTransientPopup                 -> SimplePopup struct + build_popup()
#   wxBEGIN_EVENT_TABLE                  -> connect_frame_events() /
#                                           connect_popup_events()
#   wxDECLARE/EIMPLEMENT_ABSTRACT_CLASS  -> the SimplePopup state struct
#   member fields                        -> AppState / SimplePopup / local Refs
#
# Assets: the C++ sample sets the frame icon from the compiled-in sample.xpm
# array (../sample.xpm).  It is converted pixel for pixel to `sample.svg` next
# to this file and loaded at its original 32x32 size.
#
# Surface note: `WxWidgets` exports the frame/panel-free ergonomics but not the
# panel, scrolled-window, spin-control, dialog or popup wrapper types.  Those
# wrappers are generated into the module (wx/wx*_gen.jl), so they are imported
# by name below.  This is required, not cosmetic: `wx_connect!` dispatches on
# `wxWindow`, so each control must be a real wrapper handle for its event table
# to be expressible without a hand-written `@cfunction`.
#
# The popup itself is the bound `kwxPopupTransientWindow` wrapper
# (wx/kwxpopuptransientwindow_gen.jl), the subclass that carries the
# `Popup`/`Show`/`ProcessLeftDown`/`OnDismiss` hook entry points.  The C++
# sample's `delete m_simplePopup` cannot be reproduced with a synchronous free
# from inside the handler (see dispose_popup!), so a retired popup is dismissed
# and parked as a child of its parent instead of being deleted while the
# replacement is being created.
#
# Binding notes:
#   * The popup is created with
#     `wxBORDER_NONE | wxPU_CONTAINS_CONTROLS`, matching the C++ constructor.
#   * `wxLogTextCtrl::DisableTimestamp` has no wrapper; it is expressed with the
#     bound `wxLog::SetTimestamp` call, which is exactly what the C++ method does
#     (`DisableTimestamp() { SetTimestamp(wxEmptyString); }`).
#   * The `SimpleTransientPopup` overrides of `Popup`/`Show`/`ProcessLeftDown`/
#     `OnDismiss` log with `wxLogMessage` and then call the wxWidgets base
#     implementation.  They are installed as `set_on_*!` hook handlers that log
#     and delegate through the matching `call_base_*` entry point, which calls
#     the base implementation directly instead of re-entering the hook.

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

using WxWidgets

import WxWidgets: wxWindow, wxPanel, wxScrolledWindow, wxSpinCtrl, wxDialog
import WxWidgets: kwxPopupTransientWindow
import WxWidgets: set_on_popup!, set_on_show!, set_on_process_left_down!,
                  set_on_on_dismiss!
import WxWidgets: call_base_popup!, call_base_show,
                  call_base_process_left_down, call_base_on_dismiss!
# ------------------------------------------------------------------ hooks
#
# The `SimpleTransientPopup` overrides need a Julia handler installed on the
# generated `set_on_*!` entry points, which take a raw Ptr{Cvoid}.  These
# methods wrap a Julia Function in a @cfunction and root it on the popup.

function set_on_popup!(obj::kwxPopupTransientWindow, handler::Function)
    function callback(::Ptr{Cvoid}, focus::Ptr{Cvoid})::Cvoid
        try
            handler(obj, focus)
        catch e
            @error "Exception in popup Popup handler" exception = (e, catch_backtrace())
        end
        nothing
    end

    cfun = @cfunction($callback, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}))
    set_on_popup!(obj, Base.unsafe_convert(Ptr{Cvoid}, cfun))
    push!(obj.closures, cfun)
    return nothing
end

function set_on_show!(obj::kwxPopupTransientWindow, handler::Function)
    function callback(::Ptr{Cvoid}, show::Cint)::Cint
        result = false
        try
            result = handler(obj, show != 0)
        catch e
            @error "Exception in popup Show handler" exception = (e, catch_backtrace())
        end
        return result ? Cint(1) : Cint(0)
    end

    cfun = @cfunction($callback, Cint, (Ptr{Cvoid}, Cint))
    set_on_show!(obj, Base.unsafe_convert(Ptr{Cvoid}, cfun))
    push!(obj.closures, cfun)
    return nothing
end

function set_on_process_left_down!(obj::kwxPopupTransientWindow, handler::Function)
    function callback(::Ptr{Cvoid}, event::Ptr{Cvoid})::Cint
        result = false
        try
            result = handler(obj, event)
        catch e
            @error "Exception in popup ProcessLeftDown handler" exception = (e, catch_backtrace())
        end
        return result ? Cint(1) : Cint(0)
    end

    cfun = @cfunction($callback, Cint, (Ptr{Cvoid}, Ptr{Cvoid}))
    set_on_process_left_down!(obj, Base.unsafe_convert(Ptr{Cvoid}, cfun))
    push!(obj.closures, cfun)
    return nothing
end

function set_on_on_dismiss!(obj::kwxPopupTransientWindow, handler::Function)
    function callback(::Ptr{Cvoid})::Cvoid
        try
            handler(obj)
        catch e
            @error "Exception in popup OnDismiss handler" exception = (e, catch_backtrace())
        end
        nothing
    end

    cfun = @cfunction($callback, Cvoid, (Ptr{Cvoid},))
    set_on_on_dismiss!(obj, Base.unsafe_convert(Ptr{Cvoid}, cfun))
    push!(obj.closures, cfun)
    return nothing
end

# do-block argument order, the same convention wx_connect! uses.
set_on_popup!(handler::Function, obj::kwxPopupTransientWindow) = set_on_popup!(obj, handler)
set_on_show!(handler::Function, obj::kwxPopupTransientWindow) = set_on_show!(obj, handler)
set_on_process_left_down!(handler::Function, obj::kwxPopupTransientWindow) =
    set_on_process_left_down!(obj, handler)
set_on_on_dismiss!(handler::Function, obj::kwxPopupTransientWindow) =
    set_on_on_dismiss!(obj, handler)

# ---------------------------------------------------------------- identifiers
#
# enum { Minimal_Quit = wxID_EXIT, Minimal_About = wxID_ABOUT,
#        Minimal_TestDialog, Minimal_StartSimplePopup,
#        Minimal_StartScrolledPopup, Minimal_LogWindow, Minimal_PopupButton,
#        Minimal_PopupSpinctrl };
#
# The C++ enum continues from wxID_ABOUT's numeric value, so the derived IDs are
# expressed the same way; the stock IDs keep their bound constants.

const Popup_Quit              = KwxFFI.ID_EXIT()
const Popup_About             = KwxFFI.ID_ABOUT()
const Popup_TestDialog        = Popup_About + 1
const Popup_StartSimplePopup  = Popup_About + 2
const Popup_StartScrolledPopup = Popup_About + 3
const Popup_LogWindow         = Popup_About + 4
const Popup_PopupButton       = Popup_About + 5
const Popup_PopupSpinctrl     = Popup_About + 6

const Popup_Separator = "================================================"

# -------------------------------------------------------------------- logging
#
# MyFrame installs `wxLog::SetActiveTarget(new wxLogTextCtrl(m_logWin))`, so
# every wxLogMessage of the sample lands in the log pane.  The target must stay
# reachable for the whole run (the C++ frame owns it).

const POPUP_ROOTS = Any[]

"""
    popup_log(text)

`wxLogMessage(text)` into the active target, the frame's log text control.
"""
function popup_log(text::AbstractString)
    ws = wxString(text)
    try
        KwxFFI.LogMessage(ws.ptr)
    finally
        Base.delete!(ws)
    end
    return nothing
end

"""
    popup_ptr(ptr)

`%p` formatting for a native pointer: upper-case, zero-padded 16 hex digits,
matching the C runtime's `%p` layout on 64-bit MSW.
"""
function popup_ptr(ptr::Ptr{Cvoid})
    ptr == C_NULL && return "0000000000000000"
    return uppercase(lpad(string(UInt(ptr), base = 16), 16, '0'))
end

# ------------------------------------------------------------------ wxColours
#
# `wxSystemSettings::SelectLightDark(*wxLIGHT_GREY, wxColour(90, 90, 90))`.
# Both the dark operand and the result are new objects owned by the caller.

"""`wxSystemSettings::SelectLightDark(*wxLIGHT_GREY, wxColour(90,90,90))`."""
function popup_select_light_dark()
    dark = KwxFFI.wxColour_CreateRGB(Cuchar(90), Cuchar(90), Cuchar(90), Cuchar(255))
    dark == C_NULL && error("Failed to create the dark popup colour")
    selected = try
        KwxFFI.wxSystemSettings_SelectLightDark(KwxFFI.LIGHT_GREY(), dark)
    finally
        KwxFFI.wxColour_Delete(dark)
    end
    selected == C_NULL && error("Failed to select the popup background colour")
    return selected
end

"""`a != b` for two native wxColour pointers (RGBA comparison)."""
popup_colours_differ(a::Ptr{Cvoid}, b::Ptr{Cvoid}) =
    KwxFFI.wxColour_GetUnsignedInt(a) != KwxFFI.wxColour_GetUnsignedInt(b)

# ---------------------------------------------------------------- sizer flags
#
# `wxSizerFlags` fluent chains from the C++, expressed as a flag word plus the
# border in pixels (wxSizerFlags::GetDefaultBorder()).

popup_default_border() =
    Int(round(KwxFFI.wxSizerFlags_GetDefaultBorderFractional()))

"""Flag word for `wxSizerFlags()` plus the named fluent calls."""
function popup_flags(; center::Bool = false, expand::Bool = false,
                     border::Bool = false)
    flags = 0
    center && (flags |= KwxFFI.ALIGN_CENTRE())
    expand && (flags |= KwxFFI.EXPAND())
    border && (flags |= KwxFFI.ALL())
    return flags
end

# ---------------------------------------------------------------------- state

"""
    SimplePopup

`SimpleTransientPopup`: the popup window plus the controls it owns.
"""
mutable struct SimplePopup
    # kwxPopupTransientWindow: the bound popup wrapper that dispatches the
    # Popup/Show/ProcessLeftDown/OnDismiss hooks.  It is created and freed
    # through the wxWidgets API (see dispose_popup!).
    window::kwxPopupTransientWindow
    panel::wxScrolledWindow
    button::wxButton
    spin::wxSpinCtrl
    mouse_text::wxStaticText
    text_ctrl::wxTextCtrl
end

mutable struct AppState
    frame::Union{wxFrame, Nothing}
    simple_popup::Union{SimplePopup, Nothing}
    scrolled_popup::Union{SimplePopup, Nothing}
    log_window::Union{wxTextCtrl, Nothing}
end

AppState() = AppState(nothing, nothing, nothing, nothing)

# --------------------------------------------------------------- popup events

# EVT_MOUSE_EVENTS(SimpleTransientPopup::OnMouse)
const POPUP_MOUSE_EVENTS = (
    KwxFFI.EVT_LEFT_DOWN(), KwxFFI.EVT_LEFT_UP(), KwxFFI.EVT_LEFT_DCLICK(),
    KwxFFI.EVT_MIDDLE_DOWN(), KwxFFI.EVT_MIDDLE_UP(), KwxFFI.EVT_MIDDLE_DCLICK(),
    KwxFFI.EVT_RIGHT_DOWN(), KwxFFI.EVT_RIGHT_UP(), KwxFFI.EVT_RIGHT_DCLICK(),
    KwxFFI.EVT_MOTION(), KwxFFI.EVT_ENTER_WINDOW(), KwxFFI.EVT_LEAVE_WINDOW(),
    KwxFFI.EVT_MOUSEWHEEL(),
)

"""
    popup_on_mouse(sp, event)

`SimpleTransientPopup::OnMouse`: highlight the mouse-text row while the pointer
is inside it, then skip the event.
"""
function popup_on_mouse(sp::SimplePopup, event)
    rect = KwxFFI.wxWindow_GetRect(sp.mouse_text.ptr)
    rect == C_NULL && return nothing
    KwxFFI.wxRect_SetX(rect, Cint(-100000))
    KwxFFI.wxRect_SetWidth(rect, Cint(1000000))

    position = KwxFFI.wxMouseEvent_GetPosition(event.ptr)
    px = position == C_NULL ? 0 : Int(KwxFFI.wxPoint_GetX(position))
    py = position == C_NULL ? 0 : Int(KwxFFI.wxPoint_GetY(position))
    position == C_NULL || KwxFFI.wxPoint_Delete(position)

    colour = popup_select_light_dark()
    if KwxFFI.wxRect_Contains(rect, Cint(px), Cint(py)) != 0
        KwxFFI.wxColour_Delete(colour)
        # colour = wxSystemSettings::GetColour(wxSYS_COLOUR_HIGHLIGHT);
        colour = KwxFFI.wxColour_CreateEmpty()
        KwxFFI.wxSystemSettings_GetColour(Cint(KwxFFI.SYS_COLOUR_HIGHLIGHT()), colour)
        popup_log("$(popup_ptr(KwxFFI.wxEvent_GetEventObject(event.ptr))) " *
                  "SimpleTransientPopup::OnMouse pos($px, $py)")
    end
    KwxFFI.wxRect_Delete(rect)

    background = KwxFFI.wxColour_CreateEmpty()
    KwxFFI.wxWindow_GetBackgroundColour(sp.mouse_text.ptr, background)
    if popup_colours_differ(colour, background)
        KwxFFI.wxWindow_SetBackgroundColour(sp.mouse_text.ptr, colour)
        KwxFFI.wxWindow_Refresh(sp.mouse_text.ptr, Cint(1))
    end
    KwxFFI.wxColour_Delete(background)
    KwxFFI.wxColour_Delete(colour)

    KwxFFI.wxEvent_Skip(event.ptr, Cint(1))
    return nothing
end

"`SimpleTransientPopup::OnSize`."
function popup_on_size(sp::SimplePopup, event)
    popup_log("$(popup_ptr(sp.window.ptr)) SimpleTransientPopup::OnSize")
    KwxFFI.wxEvent_Skip(event.ptr, Cint(1))
    return nothing
end

"`SimpleTransientPopup::OnSetFocus`."
function popup_on_set_focus(sp::SimplePopup, event)
    popup_log("$(popup_ptr(sp.window.ptr)) SimpleTransientPopup::OnSetFocus")
    KwxFFI.wxEvent_Skip(event.ptr, Cint(1))
    return nothing
end

"`SimpleTransientPopup::OnKillFocus`."
function popup_on_kill_focus(sp::SimplePopup, event)
    popup_log("$(popup_ptr(sp.window.ptr)) SimpleTransientPopup::OnKillFocus")
    KwxFFI.wxEvent_Skip(event.ptr, Cint(1))
    return nothing
end

"`SimpleTransientPopup::OnButton`: toggle the label between Press Me/Pressed."
function popup_on_button(sp::SimplePopup, event)
    popup_log("$(popup_ptr(sp.window.ptr)) SimpleTransientPopup::OnButton ID " *
              string(KwxFFI.wxEvent_GetId(event.ptr)))

    if get_label(sp.button) == "Press Me"
        set_label!(sp.button, "Pressed")
    else
        set_label!(sp.button, "Press Me")
    end

    KwxFFI.wxEvent_Skip(event.ptr, Cint(1))
    return nothing
end

"`SimpleTransientPopup::OnSpinCtrl`."
function popup_on_spin_ctrl(sp::SimplePopup, event)
    popup_log("$(popup_ptr(sp.window.ptr)) SimpleTransientPopup::OnSpinCtrl ID " *
              string(KwxFFI.wxEvent_GetId(event.ptr)) * " Value " *
              string(KwxFFI.wxCommandEvent_GetInt(event.ptr)))
    KwxFFI.wxEvent_Skip(event.ptr, Cint(1))
    return nothing
end

"""The `SimpleTransientPopup` event table, translated into `wx_connect!` calls."""
function connect_popup_events!(sp::SimplePopup)
    # EVT_MOUSE_EVENTS(SimpleTransientPopup::OnMouse)
    for event_type in POPUP_MOUSE_EVENTS
        wx_connect!(sp.window, event_type, event -> popup_on_mouse(sp, event))
    end

    # m_panel->Bind(wxEVT_MOTION, &SimpleTransientPopup::OnMouse, this);
    wx_connect!(sp.panel, KwxFFI.EVT_MOTION(), event -> popup_on_mouse(sp, event))

    # EVT_SIZE / EVT_SET_FOCUS / EVT_KILL_FOCUS
    wx_connect!(sp.window, KwxFFI.EVT_SIZE(), event -> popup_on_size(sp, event))
    wx_connect!(sp.window, KwxFFI.EVT_SET_FOCUS(),
                event -> popup_on_set_focus(sp, event))
    wx_connect!(sp.window, KwxFFI.EVT_KILL_FOCUS(),
                event -> popup_on_kill_focus(sp, event))

    # EVT_BUTTON(Minimal_PopupButton, SimpleTransientPopup::OnButton)
    wx_connect!(sp.window, KwxFFI.EVT_BUTTON(),
                event -> popup_on_button(sp, event); id = Popup_PopupButton)

    # EVT_SPINCTRL(Minimal_PopupSpinctrl, SimpleTransientPopup::OnSpinCtrl)
    wx_connect!(sp.window, KwxFFI.EVT_SPINCTRL(),
                event -> popup_on_spin_ctrl(sp, event); id = Popup_PopupSpinctrl)

    return nothing
end

# --------------------------------------------------------------- popup build

"""
    build_popup(parent, scrolled) -> SimplePopup

`SimpleTransientPopup::SimpleTransientPopup(parent, scrolled)`.
"""
function build_popup(parent::wxWindow, scrolled::Bool)
    # wxPopupTransientWindow(parent, wxBORDER_NONE | wxPU_CONTAINS_CONTROLS).
    # The kwx subclass is used because it carries the hook entry points the
    # SimpleTransientPopup overrides need; without installed hooks it behaves
    # exactly like the plain wxWidgets class.
    window = kwxPopupTransientWindow(C_NULL, parent,
                                     KwxFFI.BORDER_NONE() |
                                     KwxFFI.PU_CONTAINS_CONTROLS())

    # wxColour colour = wxSystemSettings::SelectLightDark(...);
    colour = popup_select_light_dark()

    # m_panel = new wxScrolledWindow(this, wxID_ANY);
    # The C++ default style is wxHSCROLL | wxVSCROLL; the FFI takes the flags
    # explicitly, so name them here.
    panel = wxScrolledWindow(window, KwxFFI.ID_ANY(), -1, -1, -1, -1,
                             KwxFFI.HSCROLL() | KwxFFI.VSCROLL())
    KwxFFI.wxWindow_SetBackgroundColour(panel.ptr, colour)
    KwxFFI.wxColour_Delete(colour)

    text = wxStaticText(panel, KwxFFI.ID_ANY(),
        "wxPopupTransientWindow is a\n" *
        "wxPopupWindow which disappears\n" *
        "automatically when the user\n" *
        "clicks the mouse outside it or if it\n" *
        "(or its first child) loses focus in \n" *
        "any other way.", -1, -1, -1, -1, 0)

    button = wxButton(panel, Popup_PopupButton, "Press Me", -1, -1, -1, -1, 0)

    # new wxSpinCtrl(m_panel, Minimal_PopupSpinctrl, "Hello");
    spin = wxSpinCtrl(panel, Popup_PopupSpinctrl, "Hello", -1, -1, -1, -1,
                      KwxFFI.SP_ARROW_KEYS(), 0, 100, 0)

    mouse_text = wxStaticText(panel, KwxFFI.ID_ANY(), "<- Test Mouse ->",
                              -1, -1, -1, -1, 0)

    text_ctrl = wxTextCtrl(panel, KwxFFI.ID_ANY(), "Try to type here",
                           -1, -1, -1, -1, 0)

    border = popup_default_border()
    sizer = wxBoxSizer(KwxFFI.VERTICAL())
    add_window!(sizer, text, 0, popup_flags(border = true), border, C_NULL)
    add_window!(sizer, button, 0, popup_flags(border = true), border, C_NULL)
    add_window!(sizer, spin, 0, popup_flags(border = true), border, C_NULL)
    add_window!(sizer, text_ctrl, 0, popup_flags(expand = true, border = true),
                border, C_NULL)
    add_window!(sizer, mouse_text, 0, popup_flags(center = true, border = true),
                border, C_NULL)

    if scrolled
        # Add a big window to ensure that scrollbars are shown when the panel
        # size is reduced below.
        big = wxPanel(panel, KwxFFI.ID_ANY(), -1, -1, 600, 900, 0)
        add_window!(sizer, big, 0, 0, 0, C_NULL)
    end

    set_sizer!(panel, sizer, true)

    if scrolled
        # m_panel->SetSize(300, 300);  == SetSize(wxDefaultCoord, wxDefaultCoord,
        #                              300, 300, wxSIZE_USE_EXISTING)
        KwxFFI.wxWindow_SetSize(panel.ptr, Cint(-1), Cint(-1), Cint(300), Cint(300),
                               Cint(KwxFFI.SIZE_USE_EXISTING()))
        KwxFFI.wxScrolledWindow_SetScrollRate(panel.ptr, Cint(10), Cint(10))
    else
        # topSizer->Fit(m_panel);
        fit!(sizer, panel)
    end

    # SetClientSize(m_panel->GetSize());
    size = KwxFFI.wxWindow_GetSize(panel.ptr)
    width = size == C_NULL ? 0 : Int(KwxFFI.wxSize_GetWidth(size))
    height = size == C_NULL ? 0 : Int(KwxFFI.wxSize_GetHeight(size))
    size == C_NULL || KwxFFI.wxSize_Delete(size)
    KwxFFI.wxWindow_SetClientSize(window.ptr, Cint(width), Cint(height))

    sp = SimplePopup(window, panel, button, spin, mouse_text, text_ctrl)
    install_popup_hooks!(sp)
    connect_popup_events!(sp)
    return sp
end

"""
    install_popup_hooks!(sp)

The `SimpleTransientPopup` virtual overrides.  Each hook logs the same line the
C++ override logs, then delegates to the wxWidgets base implementation through
`call_base_*` (a qualified base call, so it cannot re-enter the hook).
"""
function install_popup_hooks!(sp::SimplePopup)
    # void Popup(wxWindow* focus) override {
    #     wxLogMessage("%p SimpleTransientPopup::Popup", this);
    #     wxPopupTransientWindow::Popup();  // note: base is called with nullptr
    # }
    set_on_popup!(sp.window) do popup, _focus
        popup_log("$(popup_ptr(popup.ptr)) SimpleTransientPopup::Popup")
        call_base_popup!(popup, nothing)
        return nothing
    end

    # bool Show(bool show) override {
    #     wxLogMessage("%p SimpleTransientPopup::Show %d", this, int(show));
    #     return wxPopupTransientWindow::Show(show);
    # }
    set_on_show!(sp.window) do popup, show
        popup_log("$(popup_ptr(popup.ptr)) SimpleTransientPopup::Show " *
                  (show ? "1" : "0"))
        return call_base_show(popup, show)
    end

    # bool ProcessLeftDown(wxMouseEvent& event) override {
    #     wxLogMessage("%p SimpleTransientPopup::ProcessLeftDown pos(%d, %d)",
    #                  this, event.GetX(), event.GetY());
    #     return wxPopupTransientWindow::ProcessLeftDown(event);
    # }
    set_on_process_left_down!(sp.window) do popup, event
        x = Int(KwxFFI.wxMouseEvent_GetX(event))
        y = Int(KwxFFI.wxMouseEvent_GetY(event))
        popup_log("$(popup_ptr(popup.ptr)) " *
                  "SimpleTransientPopup::ProcessLeftDown pos($x, $y)")
        return call_base_process_left_down(popup, wxMouseEvent(event))
    end

    # void OnDismiss() override {
    #     wxLogMessage("%p SimpleTransientPopup::OnDismiss", this);
    #     wxPopupTransientWindow::OnDismiss();
    # }
    set_on_on_dismiss!(sp.window) do popup
        popup_log("$(popup_ptr(popup.ptr)) SimpleTransientPopup::OnDismiss")
        call_base_on_dismiss!(popup)
        return nothing
    end

    return nothing
end

"""
    position_popup_under(popup, window_ptr)

`popup->Position(btn->ClientToScreen(wxPoint(0,0)), btn->GetSize())`.
Returns the `(x, y, width, height)` used for the following log line.
"""
function position_popup_under(popup::wxWindow, window_ptr::Ptr{Cvoid})
    origin = KwxFFI.wxWindow_ClientToScreen(window_ptr, Cint(0), Cint(0))
    size = KwxFFI.wxWindow_GetSize(window_ptr)
    origin == C_NULL && error("ClientToScreen failed")
    size == C_NULL && error("GetSize failed")

    x = Int(KwxFFI.wxPoint_GetX(origin))
    y = Int(KwxFFI.wxPoint_GetY(origin))
    width = Int(KwxFFI.wxSize_GetWidth(size))
    height = Int(KwxFFI.wxSize_GetHeight(size))
    KwxFFI.wxPoint_Delete(origin)
    KwxFFI.wxSize_Delete(size)

    KwxFFI.wxPopupWindow_Position(popup.ptr, Cint(x), Cint(y), Cint(width), Cint(height))
    return (x, y, width, height)
end

"""
    open_popup!(sp)

`m_simplePopup->Popup()`.  Virtual dispatch reaches the installed
`SimpleTransientPopup::Popup` hook, which logs and calls the base implementation.
"""
function open_popup!(sp::SimplePopup)
    KwxFFI.wxPopupTransientWindow_Popup(sp.window.ptr, C_NULL)
    return nothing
end

"""
    dispose_popup!(sp)

Retire the previous `SimpleTransientPopup` before a new one is created.

The C++ sample does `delete m_simplePopup` here.  A wxWidgets window cannot be
freed synchronously from inside the event handler of one of its own children:
`Destroy()` only detaches it and defers the native free to idle time, and a new
popup created in the same handler while that deferred free is still pending
corrupts the popup stack (observed as an illegal instruction in the native
window procedure on the following recreation).  The popup is therefore
dismissed - which is exactly the state the C++ code finds it in, because the
user's click arrives through the popup before the button - and parked.  It stays
a child of the frame/dialog, so wxWidgets frees it together with its parent.
"""
function dispose_popup!(sp::SimplePopup)
    if KwxFFI.wxWindow_IsShown(sp.window.ptr) != 0
        KwxFFI.wxPopupTransientWindow_Dismiss(sp.window.ptr)
    end
    # Keep the retired wrapper - and the @cfunction trampolines of its event
    # connections - reachable for the rest of the run.
    push!(POPUP_ROOTS, sp)
    return nothing
end

# -------------------------------------------------------------- frame handlers

"`MyFrame::OnActivate`."
function frame_on_activate(event)
    popup_log("In activate...")
    return nothing
end

"`MyFrame::OnStartSimplePopup`."
function frame_on_start_simple_popup(state::AppState, event)
    popup_log(Popup_Separator)

    # delete m_simplePopup; m_simplePopup = new SimpleTransientPopup(this, false);
    if state.simple_popup !== nothing
        # `delete m_simplePopup`, as the C++ does.
        dispose_popup!(state.simple_popup)
    end
    sp = build_popup(state.frame, false)
    state.simple_popup = sp

    button = KwxFFI.wxEvent_GetEventObject(event.ptr)
    x, y, width, height = position_popup_under(sp.window, button)
    popup_log("$(popup_ptr(sp.window.ptr)) Simple Popup Shown " *
              "pos($x, $y) size($width, $height)")

    # m_simplePopup->Popup();
    open_popup!(sp)
    return nothing
end

"`MyFrame::OnStartScrolledPopup`."
function frame_on_start_scrolled_popup(state::AppState, event)
    popup_log(Popup_Separator)

    if state.scrolled_popup !== nothing
        dispose_popup!(state.scrolled_popup)
    end
    sp = build_popup(state.frame, true)
    state.scrolled_popup = sp

    button = KwxFFI.wxEvent_GetEventObject(event.ptr)
    x, y, width, height = position_popup_under(sp.window, button)
    popup_log("$(popup_ptr(sp.window.ptr)) Scrolled Popup Shown " *
              "pos($x, $y) size($width, $height)")

    open_popup!(sp)
    return nothing
end

"`MyFrame::OnTestDialog`: run the modal test dialog."
function frame_on_test_dialog(state::AppState, event)
    show_test_dialog()
    return nothing
end

"`MyFrame::OnQuit`: `Close(true)`."
function frame_on_quit(state::AppState, event)
    close(state.frame, true)
    return nothing
end

"`MyFrame::OnAbout`: `wxMessageBox(msg, 'About Popup', wxOK | wxICON_INFORMATION)`."
function frame_on_about(state::AppState, event)
    version = KwxFFI.wxVersionString()
    version_text = ""
    if version != C_NULL
        ws = wxString(version, false)
        try
            version_text = String(ws)
        finally
            Base.delete!(ws)
        end
    end

    message = "This is the About dialog of the popup sample.\nWelcome to " *
              version_text

    message_ws = wxString(message)
    caption_ws = wxString("About Popup")
    try
        KwxFFI.kwxMessageBox(message_ws.ptr, caption_ws.ptr,
                             Cint(KwxFFI.OK() | KwxFFI.ICON_INFORMATION()),
                             state.frame.ptr, Cint(-1), Cint(-1))
    finally
        Base.delete!(message_ws)
        Base.delete!(caption_ws)
    end
    return nothing
end

# ------------------------------------------------------------------- menu bar

"`menu->Append(id, text, help)`."
function popup_menu_append!(menu::Ptr{Cvoid}, id::Integer, text::String,
                            help::String = "")
    text_ws = wxString(text)
    help_ws = wxString(help)
    try
        KwxFFI.wxMenu_Append(menu, Cint(id), text_ws.ptr, help_ws.ptr, Cint(0))
    finally
        Base.delete!(text_ws)
        Base.delete!(help_ws)
    end
    return nothing
end

"`MyFrame::MyFrame` menu bar: File(Test dialog, Exit) and Help(About)."
function build_menu_bar()
    empty = wxString("")

    file_menu = KwxFFI.wxMenu_Create(empty.ptr, Clong(0))
    help_menu = KwxFFI.wxMenu_Create(empty.ptr, Clong(0))
    Base.delete!(empty)

    file_menu == C_NULL && error("Failed to create the File menu")
    help_menu == C_NULL && error("Failed to create the Help menu")

    popup_menu_append!(file_menu, Popup_TestDialog, "&Test dialog\tAlt-T",
                       "Test dialog")
    popup_menu_append!(file_menu, Popup_Quit, "E&xit\tAlt-X", "Quit this program")

    popup_menu_append!(help_menu, Popup_About, "&About\tF1", "Show about dialog")

    menu_bar = KwxFFI.wxMenuBar_Create(Cint(0))
    menu_bar == C_NULL && error("Failed to create the menu bar")

    for (menu, title) in ((file_menu, "&File"), (help_menu, "&Help"))
        title_ws = wxString(title)
        try
            KwxFFI.wxMenuBar_Append(menu_bar, menu, title_ws.ptr)
        finally
            Base.delete!(title_ws)
        end
    end

    return wxMenuBar(menu_bar)
end

# ----------------------------------------------------------------- frame icon

"""
    load_frame_icon(frame)

`SetIcon(wxICON(sample))`.  The XPM is converted to sample.svg and loaded at its
original 32x32 size, then copied into a wxIcon for the frame.
"""
function load_frame_icon(frame::wxFrame)
    svg_path = joinpath(@__DIR__, "sample.svg")

    path_ws = wxString(svg_path)
    bundle = try
        KwxFFI.wxBitmapBundle_FromSVGFile(path_ws.ptr, Cint(32), Cint(32))
    finally
        Base.delete!(path_ws)
    end

    if bundle == C_NULL || KwxFFI.wxBitmapBundle_IsOk(bundle) == 0
        # An unreadable asset must not abort the whole sample.
        bundle == C_NULL || KwxFFI.wxBitmapBundle_Delete(bundle)
        return nothing
    end

    bitmap = KwxFFI.wxBitmapBundle_GetBitmap(bundle, Cint(32), Cint(32))
    icon = KwxFFI.wxIcon_CreateDefault()
    if bitmap != C_NULL && icon != C_NULL
        KwxFFI.wxIcon_CopyFromBitmap(icon, bitmap)
        KwxFFI.wxFrame_SetIcon(frame.ptr, icon)
    end

    # SetIcon() copied the icon, so all three temporaries are ours to release.
    icon == C_NULL || KwxFFI.wxIcon_Delete(icon)
    bitmap == C_NULL || KwxFFI.wxBitmap_Delete(bitmap)
    KwxFFI.wxBitmapBundle_Delete(bundle)
    return nothing
end

# ----------------------------------------------------------------- frame build

"""
    build_frame(state, title) -> wxFrame

`MyFrame::MyFrame(title)`.
"""
function build_frame(state::AppState, title::String)
    # wxFrame(nullptr, wxID_ANY, title, wxDefaultPosition, wxSize(500, 300))
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), title, -1, -1, 500, 300,
                    KwxFFI.DEFAULT_FRAME_STYLE())
    state.frame = frame

    # SetIcon(wxICON(sample));
    load_frame_icon(frame)

    # wxMenuBar *menuBar = new wxMenuBar; ... SetMenuBar(menuBar);
    set_menu_bar!(frame, build_menu_bar())

    # CreateStatusBar(2); SetStatusText("Welcome to wxWidgets!");
    create_status_bar(frame, 2, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Welcome to wxWidgets!", 0)

    panel = wxPanel(frame, -1, -1, -1, -1, -1, 0)

    button1 = wxButton(panel, Popup_StartSimplePopup, "Show simple popup",
                       20, 20, -1, -1, 0)
    button2 = wxButton(panel, Popup_StartScrolledPopup, "Show scrolled popup",
                       20, 70, -1, -1, 0)

    # m_logWin = new wxTextCtrl(panel, wxID_ANY, wxEmptyString,
    #                           wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE);
    log_window = wxTextCtrl(panel, KwxFFI.ID_ANY(), "", -1, -1, -1, -1,
                            KwxFFI.TE_MULTILINE())
    state.log_window = log_window
    # m_logWin->SetEditable(false);
    set_editable!(log_window, false)

    # wxLogTextCtrl* logger = new wxLogTextCtrl(m_logWin);
    # m_logOld = logger->SetActiveTarget(logger);
    # logger->DisableTimestamp();
    log_target = KwxFFI.wxLogTextCtrl_Create(log_window.ptr)
    if log_target != C_NULL
        KwxFFI.wxLog_SetActiveTarget(log_target)
        # logger->DisableTimestamp();  ==  wxLog::SetTimestamp(wxEmptyString)
        # The binding takes a `const char*`, i.e. a `Cstring`.
        KwxFFI.wxLog_SetTimestamp(log_target, Base.unsafe_convert(Cstring, ""))
        # The C++ frame leaks the logger; it must outlive every log call here.
        push!(POPUP_ROOTS, log_target)
    end

    border = popup_default_border()
    sizer = wxBoxSizer(KwxFFI.VERTICAL())
    add_window!(sizer, button1, 0, popup_flags(border = true), border, C_NULL)
    add_window!(sizer, button2, 0, popup_flags(border = true), border, C_NULL)
    add_window!(sizer, log_window, 0, popup_flags(expand = true, border = true),
                border, C_NULL)

    set_sizer!(panel, sizer, true)
    return frame
end

# ----------------------------------------------------------------- test dialog

"""
    show_test_dialog()

`MyDialog`.  Builds the dialog, runs it modally and returns the modal result.
"""
function show_test_dialog()
    # wxDialog(nullptr, wxID_ANY, "Test", wxPoint(50, 50), wxSize(400, 300))
    # `wxDialog(parent, id, title, left, top, width, height, style)`
    dlg = wxDialog(nothing, KwxFFI.ID_ANY(), "Test", 50, 50, 400, 300,
                   KwxFFI.DEFAULT_DIALOG_STYLE())

    panel = wxPanel(dlg, -1, -1, -1, -1, -1, 0)

    button1 = wxButton(panel, Popup_StartSimplePopup, "Show simple popup",
                       20, 20, -1, -1, 0)
    button2 = wxButton(panel, Popup_StartScrolledPopup, "Show scrolled popup",
                       20, 60, -1, -1, 0)
    ok_button = wxButton(panel, KwxFFI.ID_OK(), "OK", 20, 200, -1, -1, 0)

    border = popup_default_border()
    sizer = wxBoxSizer(KwxFFI.VERTICAL())
    add_window!(sizer, button1, 0, popup_flags(border = true), border, C_NULL)
    add_window!(sizer, button2, 0, popup_flags(border = true), border, C_NULL)
    add_spacer(sizer, 40)
    add_window!(sizer, ok_button, 0, popup_flags(border = true), border, C_NULL)

    # panel->SetSizerAndFit(topSizer);
    set_sizer_and_fit!(panel, sizer, true)

    # MyDialog members: the two popups created from this dialog.
    simple_popup = Ref{Union{SimplePopup, Nothing}}(nothing)
    scrolled_popup = Ref{Union{SimplePopup, Nothing}}(nothing)

    "`MyDialog::OnStartSimplePopup`."
    on_start_simple = function (event)
        popup_log(Popup_Separator)
        if simple_popup[] !== nothing
            dispose_popup!(simple_popup[])
        end
        sp = build_popup(dlg, false)
        simple_popup[] = sp

        button = KwxFFI.wxEvent_GetEventObject(event.ptr)
        x, y, width, height = position_popup_under(sp.window, button)
        popup_log("$(popup_ptr(sp.window.ptr)) Dialog Simple Popup Shown " *
                  "pos($x, $y) size($width, $height)")

        open_popup!(sp)
        return nothing
    end

    "`MyDialog::OnStartScrolledPopup`."
    on_start_scrolled = function (event)
        popup_log(Popup_Separator)
        if scrolled_popup[] !== nothing
            dispose_popup!(scrolled_popup[])
        end
        sp = build_popup(dlg, true)
        scrolled_popup[] = sp

        button = KwxFFI.wxEvent_GetEventObject(event.ptr)
        x, y, width, height = position_popup_under(sp.window, button)
        popup_log("$(popup_ptr(sp.window.ptr)) Dialog Scrolled Popup Shown " *
                  "pos($x, $y) size($width, $height)")

        open_popup!(sp)
        return nothing
    end

    wx_connect!(dlg, KwxFFI.EVT_BUTTON(), on_start_simple;
                id = Popup_StartSimplePopup)
    wx_connect!(dlg, KwxFFI.EVT_BUTTON(), on_start_scrolled;
                id = Popup_StartScrolledPopup)

    # dialog.ShowModal();
    result = Int(KwxFFI.wxDialog_ShowModal(dlg.ptr))

    # The C++ dialog is a stack object, so its destructor destroys the window,
    # taking any popup still parented to it along; dismiss those first, exactly
    # as the click that closed the dialog already would have.
    simple_popup[] === nothing || dispose_popup!(simple_popup[])
    scrolled_popup[] === nothing || dispose_popup!(scrolled_popup[])

    # The C++ dialog is a stack object, so its destructor destroys the window.
    # `Destroy()` defers the native deletion to idle time, so the dialog wrapper
    # (which roots the @cfunction trampolines of its event connections) has to
    # stay reachable until that deletion has run.
    KwxFFI.wxWindow_Destroy(dlg.ptr)
    # `Destroy()` only queues the native deletion.  The dialog's event closures
    # are Julia @cfunction pointers, so the deletion must run while the Julia
    # runtime is still alive; flush the pending deletes now instead of leaving
    # them to process teardown.
    KwxFFI.wxApp_Yield(KwxFFI.wxApp_GetApp(), Cint(0))
    push!(POPUP_ROOTS, dlg)
    return result
end

# ------------------------------------------------------------------ event wiring

"MyFrame event table."
function connect_frame_events(state::AppState)
    frame = state.frame

    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_quit(state, event);
                id = Popup_Quit)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_about(state, event);
                id = Popup_About)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_test_dialog(state, event);
                id = Popup_TestDialog)

    wx_connect!(frame, KwxFFI.EVT_ACTIVATE(),
                event -> frame_on_activate(event))

    wx_connect!(frame, KwxFFI.EVT_BUTTON(),
                event -> frame_on_start_simple_popup(state, event);
                id = Popup_StartSimplePopup)
    wx_connect!(frame, KwxFFI.EVT_BUTTON(),
                event -> frame_on_start_scrolled_popup(state, event);
                id = Popup_StartScrolledPopup)

    return nothing
end

# ------------------------------------------------------------------------ main

run_app(app_name = "Popup") do
    state = AppState()

    # MyFrame* frame = new MyFrame("Popup wxWidgets App");
    frame = build_frame(state, "Popup wxWidgets App")

    connect_frame_events(state)

    # frame->Show(true);
    set_top_window(frame)
    show(frame)
end
