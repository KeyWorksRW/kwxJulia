# demo/demo.jl - Interactive demo of kwxJulia GUI features
# Part of kwxJulia — Julia bindings for wxWidgets via kwxFFI
#
# Shows the generated wx/ API: menus, status bar, panel, sizers and events.

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

run_app(app_name = "kwxJulia Demo") do
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "kwxJulia Demo",
                    -1, -1, 480, 320, KwxFFI.DEFAULT_FRAME_STYLE())

    # ------------------------------------------------------------- menus
    file_menu = wxMenu("", 0)
    Base.append!(file_menu, KwxFFI.ID_NEW(), "&New", "Create new", false)
    Base.append!(file_menu, KwxFFI.ID_OPEN(), "&Open", "Open file", false)
    Base.append!(file_menu, KwxFFI.ID_SAVE(), "&Save", "Save file", false)
    append_separator!(file_menu)
    Base.append!(file_menu, KwxFFI.ID_EXIT(), "E&xit", "Exit application", false)

    edit_menu = wxMenu("", 0)
    Base.append!(edit_menu, KwxFFI.ID_UNDO(), "&Undo", "", false)
    Base.append!(edit_menu, KwxFFI.ID_REDO(), "&Redo", "", false)
    append_separator!(edit_menu)
    Base.append!(edit_menu, KwxFFI.ID_CUT(), "Cu&t", "", false)
    Base.append!(edit_menu, KwxFFI.ID_COPY(), "&Copy", "", false)
    Base.append!(edit_menu, KwxFFI.ID_PASTE(), "&Paste", "", false)

    help_menu = wxMenu("", 0)
    Base.append!(help_menu, KwxFFI.ID_ABOUT(), "&About", "About this demo", false)

    menu_bar = wxMenuBar(0)
    append(menu_bar, file_menu, "&File")
    append(menu_bar, edit_menu, "&Edit")
    append(menu_bar, help_menu, "&Help")
    set_menu_bar!(frame, menu_bar)

    # File > Exit
    wx_connect!(frame, KwxFFI.EVT_MENU(), evt -> close(frame, true);
                id = KwxFFI.ID_EXIT())

    # Help > About
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                evt -> begin
                    msg = wxString("kwxJulia Demo\nJulia bindings for wxWidgets via kwxFFI")
                    title = wxString("About Demo")
                    try
                        KwxFFI.kwxMessageBox(msg.ptr, title.ptr,
                                             Cint(KwxFFI.OK() | KwxFFI.ICON_INFORMATION()),
                                             C_NULL, Cint(-1), Cint(-1))
                    finally
                        Base.delete!(msg)
                        Base.delete!(title)
                    end
                end;
                id = KwxFFI.ID_ABOUT())

    wx_connect!(frame, KwxFFI.EVT_CLOSE_WINDOW(), evt -> exit_app())

    # --------------------------------------------------------- status bar
    create_status_bar(frame, 1, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Ready", 0)

    # ------------------------------------------------------ panel + sizers
    panel = wxPanel(frame, KwxFFI.ID_ANY(), -1, -1, -1, -1, 0)

    vbox = wxBoxSizer(KwxFFI.VERTICAL())
    hbox = wxBoxSizer(KwxFFI.HORIZONTAL())

    label = wxStaticText(panel, KwxFFI.ID_ANY(), "Text:", -1, -1, -1, -1, 0)
    add_window!(hbox, label, 0, KwxFFI.ALL() | KwxFFI.ALIGN_CENTER_VERTICAL(), 5, C_NULL)

    text_ctrl = wxTextCtrl(panel, KwxFFI.ID_ANY(), "", -1, -1, -1, -1, 0)
    hint = wxString("hint text")
    try
        KwxFFI.wxTextEntry_SetHint(text_ctrl.ptr, hint.ptr)
    finally
        Base.delete!(hint)
    end
    add_window!(hbox, text_ctrl, 1, KwxFFI.ALL() | KwxFFI.EXPAND(), 5, C_NULL)

    add_sizer!(vbox, hbox, 0, KwxFFI.EXPAND() | KwxFFI.ALL(), 5, C_NULL)

    button = wxButton(panel, KwxFFI.ID_ANY(), "Click Me", -1, -1, -1, -1, 0)
    add_window!(vbox, button, 0, KwxFFI.ALL(), 10, C_NULL)

    set_sizer!(panel, vbox, true)

    # -------------------------------------------------------------- button
    wx_connect!(button, KwxFFI.EVT_BUTTON()) do evt
        text = get_value(text_ctrl)
        msg_s = wxString(isempty(text) ? "(no text entered)" : text)
        title_s = wxString(isempty(text) ? "Demo" : "You typed")
        try
            KwxFFI.kwxMessageBox(msg_s.ptr, title_s.ptr,
                                 Cint(KwxFFI.OK() | KwxFFI.ICON_INFORMATION()),
                                 C_NULL, Cint(-1), Cint(-1))
        finally
            Base.delete!(msg_s)
            Base.delete!(title_s)
        end
    end

    centre!(frame, KwxFFI.CENTRE())
    show(frame)
end
