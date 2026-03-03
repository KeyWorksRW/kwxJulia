# demo/demo.jl - Interactive demo of kwxJulia GUI features
# Part of kwxJulia — Julia bindings for wxWidgets via kwxFFI
#
# Demonstrates:
#   - Main frame with File/Edit/Help menus
#   - Status bar showing "Ready"
#   - wxPanel with vertical box sizer layout
#   - Horizontal child sizer with "Text:" label + text control with hint
#   - "Click Me" button that shows the text in a message box

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets
import WxWidgets: wxWindow  # abstract type — not re-exported by default

# Thin panel wrapper — no Julia wrapper exists for wxPanel yet
mutable struct wxPanel <: wxWindow
    ptr::Ptr{Cvoid}
    closures::Vector{Any}
    children::Vector{Any}
end

# Helper: append a menu item; keeps wxStrings alive across the ccall
function _menu_append(menu_ptr, id::Integer, label::String, help::String = "")
    l = wxString(label)
    h = wxString(help)
    KwxFFI.wxMenu_Append(menu_ptr, Cint(id), l.ptr, h.ptr, Cint(0))
end

run_app(app_name = "kwxJulia Demo") do

    #=================================================================
      Main frame
    =#
    frame = wxFrame(nothing, "kwxJulia Demo"; size = (480, 320))

    #=================================================================
      Menu bar: File / Edit / Help
    =#

    empty = wxString("")

    file_menu = KwxFFI.wxMenu_Create(empty.ptr, Clong(0))
    _menu_append(file_menu, KwxFFI.ID_NEW(),  "&New",  "Create new")
    _menu_append(file_menu, KwxFFI.ID_OPEN(), "&Open", "Open file")
    _menu_append(file_menu, KwxFFI.ID_SAVE(), "&Save", "Save file")
    KwxFFI.wxMenu_AppendSeparator(file_menu)
    _menu_append(file_menu, KwxFFI.ID_EXIT(), "E&xit", "Exit application")

    edit_menu = KwxFFI.wxMenu_Create(empty.ptr, Clong(0))
    _menu_append(edit_menu, KwxFFI.ID_UNDO(),  "&Undo")
    _menu_append(edit_menu, KwxFFI.ID_REDO(),  "&Redo")
    KwxFFI.wxMenu_AppendSeparator(edit_menu)
    _menu_append(edit_menu, KwxFFI.ID_CUT(),   "Cu&t")
    _menu_append(edit_menu, KwxFFI.ID_COPY(),  "&Copy")
    _menu_append(edit_menu, KwxFFI.ID_PASTE(), "&Paste")

    help_menu = KwxFFI.wxMenu_Create(empty.ptr, Clong(0))
    _menu_append(help_menu, KwxFFI.ID_ABOUT(), "&About", "About this demo")

    mb = KwxFFI.wxMenuBar_Create(Cint(0))
    let s = wxString("&File");  KwxFFI.wxMenuBar_Append(mb, file_menu, s.ptr) end
    let s = wxString("&Edit");  KwxFFI.wxMenuBar_Append(mb, edit_menu, s.ptr) end
    let s = wxString("&Help");  KwxFFI.wxMenuBar_Append(mb, help_menu, s.ptr) end
    set_menu_bar(frame, mb)

    # File > Exit: close the frame (generates wxEVT_CLOSE_WINDOW)
    wx_connect!(frame, KwxFFI.wxEVT_MENU(), evt -> close(frame, true);
                id = KwxFFI.ID_EXIT())

    # Help > About
    wx_connect!(frame, KwxFFI.wxEVT_MENU(),
                evt -> begin
                    msg   = wxString("kwxJulia Demo\nJulia bindings for wxWidgets via kwxFFI")
                    title = wxString("About Demo")
                    KwxFFI.kwxMessageBox(msg.ptr, title.ptr,
                        Cint(KwxFFI.OK() | KwxFFI.ICON_INFORMATION()),
                        C_NULL, Cint(-1), Cint(-1))
                end;
                id = KwxFFI.ID_ABOUT())

    # Window close (X button and programmatic close)
    on_close!(frame, evt -> exit_app())

    #=================================================================
      Status bar
    =#
    create_status_bar(frame)
    set_status_text(frame, "Ready")

    #=================================================================
      Panel + sizer layout
    =#
    panel_ptr = KwxFFI.wxPanel_Create(
        frame.ptr, Cint(KwxFFI.ID_ANY()),
        Cint(-1), Cint(-1), Cint(-1), Cint(-1), Cint(0))
    panel = wxPanel(panel_ptr, [], [])

    # Vertical box sizer (main layout)
    vbox = wxBoxSizer(:vertical)

    # Horizontal child sizer: "Text:" label + text control
    hbox = wxBoxSizer(:horizontal)

    label = wxStaticText(panel, "Text:")
    add!(hbox, label;
         proportion = 0,
         flags      = KwxFFI.ALL() | KwxFFI.ALIGN_CENTER_VERTICAL(),
         border     = 5)

    text_ctrl = wxTextCtrl(panel)
    hint = wxString("hint text")
    KwxFFI.wxTextEntry_SetHint(text_ctrl.ptr, hint.ptr)
    add!(hbox, text_ctrl;
         proportion = 1,
         flags      = KwxFFI.ALL() | KwxFFI.EXPAND(),
         border     = 5)

    add!(vbox, hbox;
         proportion = 0,
         flags      = KwxFFI.EXPAND() | KwxFFI.ALL(),
         border     = 5)

    # "Click Me" button
    button = wxButton(panel, "Click Me")
    add!(vbox, button;
         proportion = 0,
         flags      = KwxFFI.ALL(),
         border     = 10)

    KwxFFI.wxWindow_SetSizer(panel_ptr, vbox.ptr, Cint(1))

    #=================================================================
      Button event — show text in a message box
    =#
    on_click!(button) do evt
        text = get_value(text_ctrl)
        msg_s   = wxString(isempty(text) ? "(no text entered)" : text)
        title_s = wxString(isempty(text) ? "Demo" : "You typed")
        KwxFFI.kwxMessageBox(msg_s.ptr, title_s.ptr,
            Cint(KwxFFI.OK() | KwxFFI.ICON_INFORMATION()),
            C_NULL, Cint(-1), Cint(-1))
    end

    #=================================================================
      Show
    =#
    center(frame)
    show_window(frame)
end
