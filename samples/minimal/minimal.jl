# minimal.jl — kwxJulia port of wxSamples/src/minimal/minimal.cpp
#
# The minimal wxWidgets sample: a frame titled "Minimal wxWidgets App" with the
# application icon, a File menu (Exit), a Help menu (About), a two-pane status
# bar, and an About message box.
#
# Run from the repository root:
#   julia samples\minimal\minimal.jl
#
# WxWidgets.jl exports neither wxMenu, wxMenuBar nor a message-box wrapper, so
# the generated KwxFFI entries (reachable as KwxFFI.<name>) are the only public
# route for the menu bar, the frame icon and wxMessageBox.  Raw KwxFFI calls
# used: wxMenu_Create, wxMenu_Append, wxMenuBar_Create, wxMenuBar_Append,
# wxBitmapBundle_FromSVGFile/IsOk/GetBitmap/Delete,
# wxIcon_CreateDefault/CopyFromBitmap/Delete, wxFrame_SetIcon, wxBitmap_Delete,
# kwxMessageBox, wxVersionString and wxGetOsDescription.
#
# The C++ sample sets its icon with SetIcon(wxICON(sample)).  The XPM it includes
# from ../sample.xpm is converted pixel for pixel to sample.svg and loaded at its
# original 32x32 size.
#
# Event accessors in wx/events_gen.jl drop the C++ `wx` prefix: the menu event is
# KwxFFI.EVT_MENU().
#
# wxString-returning free functions (wxVersionString, wxGetOsDescription) return
# a caller-owned wxString*; `take_wxstring` converts and deletes it on every path.

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

using WxWidgets

# enum { Minimal_Quit = wxID_EXIT, Minimal_About = wxID_ABOUT }
const MINIMAL_QUIT = KwxFFI.ID_EXIT()
const MINIMAL_ABOUT = KwxFFI.ID_ABOUT()

# The C++ side holds only a raw pointer to the frame, and wx_connect! stores its
# callbacks inside the frame wrapper itself. Root the wrapper for the lifetime of
# the run so the whole (cyclic) structure stays reachable from Julia roots while
# the event loop, which runs outside Julia, dispatches into those callbacks.
const ROOTS = Any[]

"""Convert a caller-owned `wxString*` and release it."""
function take_wxstring(ptr::Ptr{Cvoid})
    ptr == C_NULL && return ""
    ws = wxString(ptr, false)
    try
        return String(ws)
    finally
        Base.delete!(ws)
    end
end

"""Append one menu item; both wxStrings stay bound to locals during the ccall."""
function append_item(menu::Ptr{Cvoid}, id::Integer, label::String, help::String)
    label_ws = wxString(label)
    help_ws = wxString(help)
    try
        KwxFFI.wxMenu_Append(menu, Cint(id), label_ws.ptr, help_ws.ptr, Cint(0))
    finally
        Base.delete!(label_ws)
        Base.delete!(help_ws)
    end
    return nothing
end

"""Append a submenu; the title wxString stays bound to a local during the ccall."""
function append_submenu(menu_bar::Ptr{Cvoid}, menu::Ptr{Cvoid}, title::String)
    title_ws = wxString(title)
    try
        KwxFFI.wxMenuBar_Append(menu_bar, menu, title_ws.ptr)
    finally
        Base.delete!(title_ws)
    end
    return nothing
end

"""Build the menu bar: File -> Exit, Help -> About."""
function build_menu_bar()
    # wxMenu *fileMenu = new wxMenu; wxMenu *helpMenu = new wxMenu;
    empty_title = wxString("")
    file_menu = KwxFFI.wxMenu_Create(empty_title.ptr, Clong(0))
    help_menu = KwxFFI.wxMenu_Create(empty_title.ptr, Clong(0))
    Base.delete!(empty_title)  # wxMenu stores its own copy of the title.

    file_menu == C_NULL && error("Failed to create the File menu")
    help_menu == C_NULL && error("Failed to create the Help menu")

    # helpMenu->Append(Minimal_About, "&About\tF1", "Show about dialog");
    append_item(help_menu, MINIMAL_ABOUT, "&About\tF1", "Show about dialog")

    # fileMenu->Append(Minimal_Quit, "E&xit\tAlt-X", "Quit this program");
    append_item(file_menu, MINIMAL_QUIT, "E&xit\tAlt-X", "Quit this program")

    # menuBar->Append(fileMenu, "&File"); menuBar->Append(helpMenu, "&Help");
    menu_bar = KwxFFI.wxMenuBar_Create(Cint(0))
    menu_bar == C_NULL && error("Failed to create the menu bar")
    append_submenu(menu_bar, file_menu, "&File")
    append_submenu(menu_bar, help_menu, "&Help")

    # The menu bar is owned by the frame once attached; the generated wrapper is
    # only the handle set_menu_bar! expects.
    return wxMenuBar(menu_bar)
end

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

"""MyFrame::OnAbout — wxMessageBox(...) with the wxOK | wxICON_INFORMATION style."""
function show_about(frame)
    # "Welcome to %s!\n\nThis is the minimal wxWidgets sample\nrunning under %s.",
    # wxVERSION_STRING, wxGetOsDescription()
    version_text = take_wxstring(KwxFFI.wxVersionString())
    os_text = take_wxstring(KwxFFI.wxGetOsDescription())

    message = "Welcome to " * version_text * "!\n" *
              "\n" *
              "This is the minimal wxWidgets sample\n" *
              "running under " * os_text * "."

    message_ws = wxString(message)
    caption_ws = wxString("About wxWidgets minimal sample")
    try
        KwxFFI.kwxMessageBox(message_ws.ptr, caption_ws.ptr,
                             Cint(KwxFFI.OK() | KwxFFI.ICON_INFORMATION()),
                             frame.ptr, Cint(-1), Cint(-1))
    finally
        Base.delete!(message_ws)
        Base.delete!(caption_ws)
    end
    return nothing
end

run_app(app_name = "minimal") do
    # MyFrame *frame = new MyFrame("Minimal wxWidgets App");
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "Minimal wxWidgets App",
                    -1, -1, -1, -1, KwxFFI.DEFAULT_FRAME_STYLE())
    push!(ROOTS, frame)

    # SetIcon(wxICON(sample));
    load_frame_icon(frame)

    set_menu_bar!(frame, build_menu_bar())

    # Event table: EVT_MENU(Minimal_Quit, ...), EVT_MENU(Minimal_About, ...)
    #
    # wx_connect!(window, event_type, handler; id, last_id) takes the handler as
    # its third positional argument, so the closures are passed explicitly.

    # Close(true)
    on_quit = event -> close(frame, true)
    wx_connect!(frame, KwxFFI.EVT_MENU(), on_quit; id = MINIMAL_QUIT)

    on_about = event -> show_about(frame)
    wx_connect!(frame, KwxFFI.EVT_MENU(), on_about; id = MINIMAL_ABOUT)

    # CreateStatusBar(2); SetStatusText("Welcome to wxWidgets!");
    create_status_bar(frame, 2, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Welcome to wxWidgets!", 0)

    # frame->Show(true);
    set_top_window(frame)
    show(frame)
end
