# ============================================================================
# wxWidgets "menu" sample  ->  kwxJulia port
#
# C++ source: C:/rwCode/wxSamples/src/menu/menu.cpp  (1472 lines)
#
# Structure of the port
# ---------------------
#   MyApp::OnInit          -> run_app(app_name = ...) do ... end
#   MyFrame ctor           -> build_app()
#   MyDialog               -> run_test_dialog()
#   MyEvtHandler           -> frame-level catch-all EVT_MENU handler bound last
#                             (wxWidgets calls the most recently bound handler
#                              first, which is exactly the priority a pushed
#                              wxEvtHandler has in the C++ sample)
#   event table            -> wx_connect! calls in connect_frame_events()
#   member variables       -> MenuState
#
# Binding notes (see the final report)
# ------------------------------------
#   * `wxMenu::Break()` only exists on MSW; `break_!` is used, which is the
#     bound wrapper of `wxMenu_Break`.  The `#else AppendSeparator()` branch of
#     the C++ source is the non-MSW platform branch and is not ported.
#   * `wxMenuItem::GetAccel()` is not bound, so OnGetMenuItemInfo recovers the
#     accelerator text from `GetItemLabel()` (which includes the `"\t..."`
#     part), reproducing the C++ "Its accelerator is ..." / "It doesn't have an
#     accelerator" output exactly.
#   * `wxFileHistory::SetMenuPathStyle()` is not bound (the `wxFH_PATH_SHOW_*`
#     constants are).  The three radio items exist and are connected, but the
#     handler logs the gap instead of silently doing nothing.
#   * `EVT_MENU_RANGE(id1, id2, f)` is `EVT_MENU` with an id range in wx, so it
#     is expressed with `wx_connect!(...; id = 500, last_id = 504)`.
#     `EVT_MENU_HIGHLIGHT_ALL` is `EVT_MENU_HIGHLIGHT` for every id, expressed
#     as `id = wxID_ANY`.
#   * `wxMenuItem::SetBitmap` is bound for `wxBitmap` only (`set_bitmaps!` needs
#     a checked/unchecked pair of `wxBitmapBundle`s), so the two art bitmaps are
#     fetched at the wxART_MENU size hint instead of as scalable bundles.
#   * The C++ frame destructor (`delete m_fileHistory`, `PopEventHandler`,
#     restore the old wxLog target) runs when the process is shutting down
#     anyway; the port leaves those native objects for process teardown rather
#     than touching wxWidgets after the main loop has returned.
# ============================================================================

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

using WxWidgets

# --------------------------------------------------------------------- ids
# enum { ... } of menu.cpp:267

const Menu_File_ClearLog    = 100
const Menu_File_ShowDialog  = 101

const Menu_MenuBar_Toggle   = 200
const Menu_MenuBar_Append   = 201
const Menu_MenuBar_Insert   = 202
const Menu_MenuBar_Delete   = 203
const Menu_MenuBar_Enable   = 204
const Menu_MenuBar_GetLabel = 205
const Menu_MenuBar_SetLabel = 206
const Menu_MenuBar_FindMenu = 207

const Menu_Menu_Append      = 300
const Menu_Menu_AppendSub   = 301
const Menu_Menu_Insert      = 302
const Menu_Menu_Delete      = 303
const Menu_Menu_DeleteSub   = 304
const Menu_Menu_Enable      = 305
const Menu_Menu_Check       = 306
const Menu_Menu_GetLabel    = 307
const Menu_Menu_SetLabel    = 308
const Menu_Menu_GetInfo     = 309
const Menu_Menu_FindItem    = 310
const Menu_Menu_FileHistory1 = 311
const Menu_Menu_FileHistory2 = 312
const Menu_Menu_FileHistory3 = 313

const Menu_Test_Normal      = 400
const Menu_Test_Check       = 401
const Menu_Test_Radio1      = 402
const Menu_Test_Radio2      = 403
const Menu_Test_Radio3      = 404

const Menu_SubMenu          = 450
const Menu_SubMenu_Normal   = 451
const Menu_SubMenu_Check    = 452
const Menu_SubMenu_Radio1   = 453
const Menu_SubMenu_Radio2   = 454
const Menu_SubMenu_Radio3   = 455

const Menu_Dummy_First      = 500
const Menu_Dummy_Second     = 501
const Menu_Dummy_Third      = 502
const Menu_Dummy_Fourth     = 503
const Menu_Dummy_Last       = 504

const Menu_Popup_ToBeDeleted = 2000
const Menu_Popup_ToBeGreyed  = 2001
const Menu_Popup_ToBeChecked = 2002
const Menu_Popup_Submenu     = 2003
const Menu_PopupChoice       = 2004

# `SetIcon(wxICON(sample))` size of the converted sample.xpm.
const MENU_ICON_SIZE = 32

# The 68 stock ids of the "&Standard items demo" submenu, in source order.
const STOCK_MENU_IDS = [
    KwxFFI.ID_ADD, KwxFFI.ID_APPLY, KwxFFI.ID_BACKWARD, KwxFFI.ID_BOLD,
    KwxFFI.ID_BOTTOM, KwxFFI.ID_CANCEL, KwxFFI.ID_CDROM, KwxFFI.ID_CLEAR,
    KwxFFI.ID_CLOSE, KwxFFI.ID_CONVERT, KwxFFI.ID_COPY, KwxFFI.ID_CUT,
    KwxFFI.ID_DELETE, KwxFFI.ID_DOWN, KwxFFI.ID_EXECUTE, KwxFFI.ID_EXIT,
    KwxFFI.ID_FIND, KwxFFI.ID_FIRST, KwxFFI.ID_FLOPPY, KwxFFI.ID_FORWARD,
    KwxFFI.ID_HARDDISK, KwxFFI.ID_HELP, KwxFFI.ID_HOME, KwxFFI.ID_INDENT,
    KwxFFI.ID_INDEX, KwxFFI.ID_INFO, KwxFFI.ID_ITALIC, KwxFFI.ID_JUMP_TO,
    KwxFFI.ID_JUSTIFY_CENTER, KwxFFI.ID_JUSTIFY_FILL, KwxFFI.ID_JUSTIFY_LEFT,
    KwxFFI.ID_JUSTIFY_RIGHT, KwxFFI.ID_LAST, KwxFFI.ID_NETWORK, KwxFFI.ID_NEW,
    KwxFFI.ID_NO, KwxFFI.ID_OK, KwxFFI.ID_OPEN, KwxFFI.ID_PASTE,
    KwxFFI.ID_PREFERENCES, KwxFFI.ID_PREVIEW, KwxFFI.ID_PRINT,
    KwxFFI.ID_PROPERTIES, KwxFFI.ID_REDO, KwxFFI.ID_REFRESH, KwxFFI.ID_REMOVE,
    KwxFFI.ID_REPLACE, KwxFFI.ID_REVERT_TO_SAVED, KwxFFI.ID_SAVE,
    KwxFFI.ID_SAVEAS, KwxFFI.ID_SELECT_COLOR, KwxFFI.ID_SELECT_FONT,
    KwxFFI.ID_SORT_ASCENDING, KwxFFI.ID_SORT_DESCENDING, KwxFFI.ID_SPELL_CHECK,
    KwxFFI.ID_STOP, KwxFFI.ID_STRIKETHROUGH, KwxFFI.ID_TOP, KwxFFI.ID_UNDELETE,
    KwxFFI.ID_UNDERLINE, KwxFFI.ID_UNDO, KwxFFI.ID_UNINDENT, KwxFFI.ID_UP,
    KwxFFI.ID_YES, KwxFFI.ID_ZOOM_100, KwxFFI.ID_ZOOM_FIT, KwxFFI.ID_ZOOM_IN,
    KwxFFI.ID_ZOOM_OUT,
]

# Native objects that must outlive the Julia references to them.
const MENU_ROOTS = Any[]

# ------------------------------------------------------------------- state

mutable struct MenuState
    frame::Any                 # wxFrame
    menubar::Any               # wxMenuBar (this port keeps it; C++ calls GetMenuBar)
    textctrl::Any              # wxTextCtrl used for logging (USE_LOG_WINDOW)
    detached_menu::Any         # m_menu, wxMenu or nothing
    count_dummy::Int           # m_countDummy
    file_history_menu::Any     # m_fileHistoryMenu
    file_history::Any          # m_fileHistory
    check_bundles::Any         # the two 8x8 wxBitmapBundles of the '&Test' menu
end

MenuState() = MenuState(nothing, nothing, nothing, nothing, 0, nothing, nothing,
                        nothing)

# ----------------------------------------------------------------- logging
# USE_LOG_WINDOW is on: every wxLogMessage lands in the frame's text control
# through the wxLogTextCtrl active target installed by build_app().

"""
    menu_log(text)

`wxLogMessage(text)` into the active target (the frame's log text control).
The free function takes a `wxString*` and has no wrapper.
"""
function menu_log(text::AbstractString)
    ws = wxString(text)
    try
        KwxFFI.LogMessage(ws.ptr)
    finally
        Base.delete!(ws)
    end
    return nothing
end

"`wxLogWarning(text)`."
function menu_log_warning(text::AbstractString)
    ws = wxString(text)
    try
        KwxFFI.LogWarning(ws.ptr)
    finally
        Base.delete!(ws)
    end
    return nothing
end

"`wxLogError(text)`."
function menu_log_error(text::AbstractString)
    ws = wxString(text)
    try
        KwxFFI.LogError(ws.ptr)
    finally
        Base.delete!(ws)
    end
    return nothing
end

"`wxLogStatus(frame, text)` - writes the frame's status bar pane 0."
function menu_log_status(frame, text::AbstractString)
    ws = wxString(text)
    try
        KwxFFI.LogStatusWindow(frame.ptr, ws.ptr)
    finally
        Base.delete!(ws)
    end
    return nothing
end

"`wxGetTextFromUser(msg, caption, default, parent)`; `\"\"` when cancelled."
function menu_get_text_from_user(st::MenuState, message::String, caption::String,
                                 default_text::String)
    ptr = GC.@preserve message caption default_text begin
        KwxFFI.wxGetTextFromUserEx(Base.unsafe_convert(Cstring, message),
                                   Base.unsafe_convert(Cstring, caption),
                                   Base.unsafe_convert(Cstring, default_text),
                                   st.frame.ptr, Cint(-1), Cint(-1), Cint(1))
    end
    ptr == C_NULL && return ""
    # The *Ex entry point hands back a wxString the caller owns.
    ws = wxString(ptr, false)
    try
        return String(ws)
    finally
        Base.delete!(ws)
    end
end

"Read the C string behind a `wxART_*` constant (a `const char*` in the FFI)."
function menu_art_id(ptr::Ptr{Cvoid}, fallback::String)
    ptr == C_NULL && return fallback
    text = unsafe_string(Ptr{UInt8}(ptr))
    return isempty(text) ? fallback : text
end

"`wxArtProvider::GetBitmap(id, client, wxART_MENU size hint)` as a wxBitmap."
function menu_art_bitmap(id::Function, client::Function)
    art_id = menu_art_id(id(), "wxART_")
    client_id = menu_art_id(client(), "wxART_MENU")
    return wxArtProvider_GetBitmap(art_id, client_id, 16, 16)
end

"`wxFileName(name).GetAbsolutePath()` - resolved against the process cwd."
function menu_absolute_path(name::String)
    path_format = KwxFFI.PATH_NATIVE()
    file_name = wxFileName(name, path_format)
    try
        return get_absolute_path(file_name, pwd(), path_format)
    finally
        Base.delete!(file_name)
    end
end

"""
    menu_accelerator_text(item) -> String

`wxMenuItem::GetAccel()` is not bound.  `GetItemLabel()` returns the label
*including* its accelerator, and this sample always supplies accelerators as the
`"\t..."` part of the label, so the accelerator text is recovered from it and
the `""` result means "no accelerator" - the same distinction the C++ code makes.
"""
function menu_accelerator_text(item)
    label = get_item_label(item)
    tab = findfirst('\t', label)
    tab === nothing && return ""
    return strip(label[nextind(label, tab):end])
end

# --------------------------------------------------------- menu primitives

"`new wxMenu` - the C++ default constructor is `wxMenu(\"\", 0)`."
menu_new() = wxMenu("", 0)

"`wxICON(sample)` from the converted sample.xpm."
function load_frame_icon(frame)
    svg_path = joinpath(@__DIR__, "sample.svg")

    path_ws = wxString(svg_path)
    bundle = try
        KwxFFI.wxBitmapBundle_FromSVGFile(path_ws.ptr, Cint(MENU_ICON_SIZE),
                                          Cint(MENU_ICON_SIZE))
    finally
        Base.delete!(path_ws)
    end

    if bundle == C_NULL || KwxFFI.wxBitmapBundle_IsOk(bundle) == 0
        bundle == C_NULL || KwxFFI.wxBitmapBundle_Delete(bundle)
        return nothing
    end

    bitmap = KwxFFI.wxBitmapBundle_GetBitmap(bundle, Cint(MENU_ICON_SIZE),
                                             Cint(MENU_ICON_SIZE))
    icon = KwxFFI.wxIcon_CreateDefault()
    if bitmap != C_NULL && icon != C_NULL
        KwxFFI.wxIcon_CopyFromBitmap(icon, bitmap)
        KwxFFI.wxFrame_SetIcon(frame.ptr, icon)
    end

    # SetIcon() copied the icon, so the temporaries are ours to release.
    icon == C_NULL || KwxFFI.wxIcon_Delete(icon)
    bitmap == C_NULL || KwxFFI.wxBitmap_Delete(bitmap)
    KwxFFI.wxBitmapBundle_Delete(bundle)
    return nothing
end

"""
    create_dummy_menu(st; want_title)

`MyFrame::CreateDummyMenu(wxString *title)`.  Returns `(menu, title)`; the title
is only filled in (and `m_countDummy` advanced) when `want_title` is true.
"""
function create_dummy_menu(st::MenuState; want_title::Bool)
    menu = menu_new()
    append!(menu, Menu_Dummy_First, "&First item\tCtrl-F1", "", false)
    append_separator!(menu)
    append_check_item!(menu, Menu_Dummy_Second, "&Second item\tCtrl-F2", "")

    title = ""
    if want_title
        st.count_dummy += 1
        title = "Dummy menu &$(st.count_dummy)"
    end
    return menu, title
end

"The 'Test' menu of the menu bar."
function get_test_menu(st::MenuState)
    index = find_menu(st.menubar, "Test")
    index == KwxFFI.NOT_FOUND() && return nothing
    return get_menu(st.menubar, index)
end

"`MyFrame::GetLastMenuItem()` - the last item of the 'Test' menu."
function get_last_menu_item(st::MenuState)
    menu = get_test_menu(st)
    menu === nothing && (menu_log_warning("no 'Test' menu?"); return nothing)

    count = Int(get_menu_item_count(menu))
    if count == 0
        menu_log_warning("No last item in the 'Test' menu!")
        return nothing
    end
    return find_item_by_position(menu, count - 1)
end

# 8x8 bitmaps for the three bitmap check items of the '&Test' menu
# (__WXMSW__ && wxUSE_IMAGE branch).
function create_test_bitmaps()
    # wxBitmap bmpUnchecked(8, 8);
    bmp_unchecked = wxBitmap(8, 8, -1)

    # wxImage imageChecked(8, 8); imageChecked.Clear(0xff);
    image_checked = wxImage(8, 8)
    clear!(image_checked, 0xff)

    # wxBitmap bmpChecked(imageChecked);
    bmp_checked = wxBitmap(image_checked, -1)

    checked_vector = wxBitmapVector()
    add!(checked_vector, bmp_checked)
    unchecked_vector = wxBitmapVector()
    add!(unchecked_vector, bmp_unchecked)

    bundle_checked = wxBitmapBundle_FromBitmaps(checked_vector)
    bundle_unchecked = wxBitmapBundle_FromBitmaps(unchecked_vector)

    # The vectors are only needed to build the bundles.
    Base.delete!(checked_vector)
    Base.delete!(unchecked_vector)

    return bundle_checked, bundle_unchecked
end

"Append a checkable item carrying the checked/unchecked bitmaps."
function append_bitmap_check_item!(menu, st::MenuState, label::String,
                                   bitmaps_first::Bool, initially_checked::Bool)
    bundle_checked, bundle_unchecked = st.check_bundles
    item = wxMenuItem(KwxFFI.ID_ANY(), label, "", KwxFFI.ITEM_CHECK(), nothing)
    if bitmaps_first
        # new wxMenuItem(...); item->SetBitmaps(...); menu->Append(item);
        set_bitmaps!(item, bundle_checked, bundle_unchecked)
        append_item!(menu, item)
    else
        # menu->Append(item); [item->Check();] item->SetBitmaps(...);
        append_item!(menu, item)
        if initially_checked
            check!(item, true)
        end
        set_bitmaps!(item, bundle_checked, bundle_unchecked)
    end
    return nothing
end

# ---------------------------------------------------------------- the menus
# MyFrame ctor, menu construction part (menu.cpp:483-717).

function build_menu_bar(st::MenuState)
    file_menu = menu_new()

    # ---- &File / &Standard items demo
    stock_menu = menu_new()
    for stock in STOCK_MENU_IDS
        append_by_id!(stock_menu, stock())
    end
    append_sub_menu(file_menu, stock_menu, "&Standard items demo", "")

    # ---- &File / Clear &log  (with the wxART_DELETE bitmap)
    clear_item = wxMenuItem(Menu_File_ClearLog, "Clear &log\tCtrl-L", "",
                            KwxFFI.ITEM_NORMAL(), nothing)
    set_bitmap!(clear_item, menu_art_bitmap(KwxFFI.ART_DELETE, KwxFFI.ART_MENU))
    append_item!(file_menu, clear_item)
    append_separator!(file_menu)

    # ---- &File / Show &Dialog
    append!(file_menu, Menu_File_ShowDialog, "Show &Dialog\tCtrl-D",
            "Show a dialog", false)
    append_separator!(file_menu)

    # ---- &File / Sample file history
    st.file_history_menu = menu_new()
    st.file_history = wxFileHistory(9)
    use_menu!(st.file_history, st.file_history_menu)
    add_file_to_history!(st.file_history, menu_absolute_path("menu.cpp"))
    add_file_to_history!(st.file_history, menu_absolute_path("Makefile.in"))
    add_file_to_history!(st.file_history,
                         menu_absolute_path(joinpath("minimal", "minimal.cpp")))
    append_sub_menu(file_menu, st.file_history_menu, "Sample file history", "")

    # ---- &File / E&xit
    append!(file_menu, KwxFFI.ID_EXIT(), "E&xit\tAlt-X", "Quit menu sample", false)

    # ---- Menu&bar
    menubar_menu = menu_new()
    append!(menubar_menu, Menu_MenuBar_Append, "&Append menu\tCtrl-A",
            "Append a menu to the menubar", false)
    append!(menubar_menu, Menu_MenuBar_Insert, "&Insert menu\tCtrl-I",
            "Insert a menu into the menubar", false)
    append!(menubar_menu, Menu_MenuBar_Delete, "&Delete menu\tCtrl-D",
            "Delete the last menu from the menubar", false)
    append!(menubar_menu, Menu_MenuBar_Toggle, "&Toggle menu\tCtrl-T",
            "Toggle the first menu in the menubar", true)
    append_separator!(menubar_menu)
    append!(menubar_menu, Menu_MenuBar_Enable, "&Enable menu\tCtrl-E",
            "Enable or disable the last menu", true)
    append_separator!(menubar_menu)
    append!(menubar_menu, Menu_MenuBar_GetLabel, "&Get menu label\tCtrl-G",
            "Get the label of the last menu", false)
    append!(menubar_menu, Menu_MenuBar_SetLabel, "&Set menu label\tCtrl-S",
            "Change the label of the last menu", false)
    append_separator!(menubar_menu)
    append!(menubar_menu, Menu_MenuBar_FindMenu, "&Find menu from label\tCtrl-F",
            "Find a menu by searching for its label", false)

    sub_menu = menu_new()
    append!(sub_menu, Menu_SubMenu_Normal, "&Normal submenu item",
            "Disabled submenu item", false)
    append_check_item!(sub_menu, Menu_SubMenu_Check, "&Check submenu item",
                       "Check submenu item")
    append_radio_item!(sub_menu, Menu_SubMenu_Radio1, "Radio item &1", "Radio item")
    append_radio_item!(sub_menu, Menu_SubMenu_Radio2, "Radio item &2", "Radio item")
    append_radio_item!(sub_menu, Menu_SubMenu_Radio3, "Radio item &3", "Radio item")
    append_sub!(menubar_menu, Menu_SubMenu, "Submenu", sub_menu, "")

    # ---- &Menu
    menu_menu = menu_new()
    append!(menu_menu, Menu_Menu_Append, "&Append menu item\tAlt-A",
            "Append a menu item to the 'Test' menu", false)
    append!(menu_menu, Menu_Menu_AppendSub, "&Append sub menu\tAlt-S",
            "Append a sub menu to the 'Test' menu", false)
    append!(menu_menu, Menu_Menu_Insert, "&Insert menu item\tAlt-I",
            "Insert a menu item in head of the 'Test' menu", false)
    append!(menu_menu, Menu_Menu_Delete, "&Delete menu item\tAlt-D",
            "Delete the last menu item from the 'Test' menu", false)
    append!(menu_menu, Menu_Menu_DeleteSub, "Delete last &submenu\tAlt-K",
            "Delete the last submenu from the 'Test' menu", false)
    append_separator!(menu_menu)
    append!(menu_menu, Menu_Menu_Enable, "&Enable menu item\tAlt-E",
            "Enable or disable the last menu item", true)
    append!(menu_menu, Menu_Menu_Check, "&Check menu item\tAlt-C",
            "Check or uncheck the last menu item", true)

    # menuMenu->Break();  (__WXMSW__ branch - on MSW this really is a menu
    # column break, the other platforms get an extra separator instead)
    break_!(menu_menu)

    append!(menu_menu, Menu_Menu_GetInfo, "Get menu item inf&o\tAlt-O",
            "Show the state of the last menu item", false)
    append!(menu_menu, Menu_Menu_SetLabel, "Set menu item label\tAlt-L",
            "Set the label of a menu item", false)
    append_separator!(menu_menu)
    append!(menu_menu, Menu_Menu_FindItem, "Find menu item from label",
            "Find a menu item by searching for its label", false)

    history_style_menu = menu_new()
    append_radio_item!(history_style_menu, Menu_Menu_FileHistory1, "Hide current path", "")
    append_radio_item!(history_style_menu, Menu_Menu_FileHistory2, "Hide all paths", "")
    append_radio_item!(history_style_menu, Menu_Menu_FileHistory3, "Show all paths", "")
    append_separator!(menu_menu)
    append_sub_menu(menu_menu, history_style_menu, "Select file history menu style", "")

    # ---- &Test
    test_menu = menu_new()
    append!(test_menu, Menu_Test_Normal, "&Normal item", "", false)
    append_separator!(test_menu)
    append_check_item!(test_menu, Menu_Test_Check, "&Check item", "")

    append_bitmap_check_item!(test_menu, st, "Check item with bitmaps", true, false)
    append_bitmap_check_item!(test_menu, st, "Check item with bitmaps set afterwards",
                              false, false)
    append_bitmap_check_item!(test_menu, st,
                              "Check item with bitmaps set afterwards (initially checked)",
                              false, true)

    append_separator!(test_menu)
    append_radio_item!(test_menu, Menu_Test_Radio1, "Radio item &1", "")
    append_radio_item!(test_menu, Menu_Test_Radio2, "Radio item &2", "")
    append_radio_item!(test_menu, Menu_Test_Radio3, "Radio item &3", "")

    # ---- &Help
    help_menu = menu_new()
    append!(help_menu, KwxFFI.ID_ABOUT(), "&About\tF1", "About menu sample", false)

    # ---- the bar itself
    menu_bar = wxMenuBar(KwxFFI.MB_DOCKABLE())
    append(menu_bar, file_menu, "&File")
    append(menu_bar, menubar_menu, "Menu&bar")
    append(menu_bar, menu_menu, "&Menu")
    append(menu_bar, test_menu, "&Test")
    append(menu_bar, help_menu, "&Help")

    # these items should be initially checked
    check!(menu_bar, Menu_MenuBar_Toggle, true)
    check!(menu_bar, Menu_MenuBar_Enable, true)
    check!(menu_bar, Menu_Menu_Enable, true)
    check!(menu_bar, Menu_Menu_Check, false)

    return menu_bar
end

# -------------------------------------------------------------- frame build

"""
    build_app() -> MenuState

`MyFrame::MyFrame()`.
"""
function build_app()
    st = MenuState()

    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "wxWidgets menu sample",
                    -1, -1, -1, -1, KwxFFI.DEFAULT_FRAME_STYLE())
    st.frame = frame

    # SetIcon(wxICON(sample));
    load_frame_icon(frame)

    # CreateStatusBar();  ->  CreateStatusBar(1, wxSTB_DEFAULT_STYLE, 0)
    create_status_bar(frame, 1, KwxFFI.STB_DEFAULT_STYLE(), 0)

    # the 8x8 bitmaps of the '&Test' menu; they must outlive the menu items
    st.check_bundles = create_test_bitmaps()

    # create the menubar, associate it with the frame
    st.menubar = build_menu_bar(st)
    set_menu_bar!(frame, st.menubar)

    # the log text window, created after the menu bar just like the C++ ctor
    textctrl = wxTextCtrl(frame, KwxFFI.ID_ANY(), "", -1, -1, -1, -1,
                          KwxFFI.TE_MULTILINE())
    st.textctrl = textctrl
    set_editable!(textctrl, false)

    wxLog_DisableTimestamp()
    log_target = KwxFFI.wxLogTextCtrl_Create(textctrl.ptr)
    if log_target != C_NULL
        KwxFFI.wxLog_SetActiveTarget(log_target)
        push!(MENU_ROOTS, log_target)
    end

    menu_log("Brief explanations: the commands in the \"Menu\" menu " *
             "append/insert/delete items to/from the \"Test\" menu.\n" *
             "The commands in the \"Menubar\" menu work with the " *
             "menubar itself.\n\n" *
             "Right click the band below to test popup menus.\n")

    return st
end

# ----------------------------------------------------------------- handlers
# menu.cpp: MyFrame callbacks.

"`MyFrame::LogMenuEvent` - called by the pushed MyEvtHandler."
function log_menu_event(st::MenuState, event)
    id = get_id(event)
    message = "Menu command $(id)"

    item = find_item(st.menubar, id)
    command = wxCommandEvent(event.ptr)
    if (item.ptr != C_NULL && is_checkable(item)) || id == Menu_Popup_ToBeChecked
        message *= is_checked(command) ? " (the item is currently checked)" :
                                         " (the item is currently not checked)"
    end
    menu_log(message)
    return nothing
end

"`MyFrame::OnQuit`."
function frame_on_quit(st::MenuState, event)
    Base.close(st.frame, true)
    return nothing
end

"`MyFrame::OnClearLog`."
function frame_on_clear_log(st::MenuState, event)
    clear!(st.textctrl)
    return nothing
end

"`MyFrame::OnClearLogUpdateUI`."
function frame_on_clear_log_update_ui(st::MenuState, event)
    ui = wxUpdateUIEvent(event.ptr)
    enable!(ui, get_number_of_lines(st.textctrl) > 5)
    return nothing
end

"`MyFrame::OnShowDialog`."
function frame_on_show_dialog(st::MenuState, event)
    run_test_dialog(st)
    return nothing
end

"`MyFrame::OnAbout`."
function frame_on_about(st::MenuState, event)
    message = wxString("wxWidgets menu sample\n(c) 1999-2001 Vadim Zeitlin")
    caption = wxString("About wxWidgets menu sample")
    try
        KwxFFI.kwxMessageBox(message.ptr, caption.ptr,
                             Cint(KwxFFI.OK() | KwxFFI.ICON_INFORMATION()),
                             C_NULL, Cint(-1), Cint(-1))
    finally
        Base.delete!(message)
        Base.delete!(caption)
    end
    return nothing
end

# -------------------------------------------------------------- menu bar ops

"`MyFrame::OnDeleteMenu`."
function frame_on_delete_menu(st::MenuState, event)
    count = get_menu_count(st.menubar)
    if count == 4
        # don't let delete the first 4 menus
        menu_log_error("Can't delete any more menus")
    else
        removed = remove(st.menubar, count - 1)
        # `delete mbar->Remove(count - 1);`
        removed.ptr == C_NULL || delete_pointer!(removed)
    end
    return nothing
end

"`MyFrame::OnInsertMenu`."
function frame_on_insert_menu(st::MenuState, event)
    menu, title = create_dummy_menu(st; want_title = true)
    # Insert before the 'Help' menu, otherwise repeated Deletes would remove
    # the 'Test' menu.
    insert(st.menubar, 4, menu, title)
    return nothing
end

"`MyFrame::OnAppendMenu`."
function frame_on_append_menu(st::MenuState, event)
    menu, title = create_dummy_menu(st; want_title = true)
    append(st.menubar, menu, title)
    return nothing
end

"`MyFrame::OnToggleMenu`."
function frame_on_toggle_menu(st::MenuState, event)
    if st.detached_menu === nothing
        # hide the menu
        st.detached_menu = remove(st.menubar, 0)
    else
        # restore it
        insert(st.menubar, 0, st.detached_menu, "&File")
        st.detached_menu = nothing
    end
    return nothing
end

"`MyFrame::OnEnableMenu`."
function frame_on_enable_menu(st::MenuState, event)
    count = get_menu_count(st.menubar)
    enable_top!(st.menubar, count - 1, is_checked(wxCommandEvent(event.ptr)))
    return nothing
end

"`MyFrame::OnGetLabelMenu`."
function frame_on_get_label_menu(st::MenuState, event)
    count = get_menu_count(st.menubar)
    count == 0 && return nothing
    menu_log("The label of the last menu item is '$(get_menu_label(st.menubar, count - 1))'")
    return nothing
end

"`MyFrame::OnSetLabelMenu`."
function frame_on_set_label_menu(st::MenuState, event)
    count = get_menu_count(st.menubar)
    count == 0 && return nothing

    label = menu_get_text_from_user(st, "Enter new label: ",
                                    "Change last menu text",
                                    get_menu_label(st.menubar, count - 1))
    if !isempty(label)
        set_menu_label!(st.menubar, count - 1, label)
    end
    return nothing
end

"`MyFrame::OnFindMenu`."
function frame_on_find_menu(st::MenuState, event)
    count = get_menu_count(st.menubar)
    count == 0 && return nothing

    label = menu_get_text_from_user(st, "Enter label to search for: ",
                                    "Find menu", "")
    if !isempty(label)
        index = find_menu(st.menubar, label)
        if index == KwxFFI.NOT_FOUND()
            menu_log_warning("No menu with label '$label'")
        else
            menu_log("Menu $(index) has label '$label'")
        end
    end
    return nothing
end

# ------------------------------------------------------------ menu item ops

"`MyFrame::OnDummy` (EVT_MENU_RANGE over the five dummy ids)."
function frame_on_dummy(st::MenuState, event)
    menu_log("Dummy item #$(get_id(event) - Menu_Dummy_First + 1)")
    return nothing
end

"`MyFrame::OnAppendMenuItem`."
function frame_on_append_menu_item(st::MenuState, event)
    menu = get_test_menu(st)
    menu === nothing && return nothing

    append_separator!(menu)
    append!(menu, Menu_Dummy_Third, "&Third dummy item\tCtrl-F3",
            "Checkable item", true)
    return nothing
end

"`MyFrame::OnAppendSubMenu`."
function frame_on_append_sub_menu(st::MenuState, event)
    menu = get_test_menu(st)
    menu === nothing && return nothing

    sub, _ = create_dummy_menu(st; want_title = false)
    append_sub!(menu, Menu_Dummy_Last, "&Dummy sub menu", sub, "Dummy sub menu help")
    return nothing
end

"`MyFrame::OnDeleteMenuItem`."
function frame_on_delete_menu_item(st::MenuState, event)
    menu = get_test_menu(st)
    menu === nothing && return nothing

    count = Int(get_menu_item_count(menu))
    if count == 0
        menu_log_warning("No items to delete!")
    else
        item = find_item_by_position(menu, count - 1)
        item.ptr == C_NULL || destroy_by_item!(menu, item)
    end
    return nothing
end

"`MyFrame::OnDeleteSubMenu`."
function frame_on_delete_sub_menu(st::MenuState, event)
    menu = get_test_menu(st)
    menu === nothing && return nothing

    count = Int(get_menu_item_count(menu))
    for n in (count - 1):-1:0
        item = find_item_by_position(menu, n)
        if item.ptr != C_NULL && is_sub_menu(item)
            destroy_by_item!(menu, item)
            return nothing
        end
    end
    menu_log_warning("No submenu to delete!")
    return nothing
end

"`MyFrame::OnInsertMenuItem`."
function frame_on_insert_menu_item(st::MenuState, event)
    menu = get_test_menu(st)
    menu === nothing && return nothing

    insert_item!(menu, 0, wxMenuItem(Menu_Dummy_Fourth,
                                     "Fourth dummy item\tCtrl-F4", "",
                                     KwxFFI.ITEM_NORMAL(), nothing))
    # wxMenuItem::New(menu, wxID_SEPARATOR)
    insert_item!(menu, 1, wxMenuItem())
    return nothing
end

"`MyFrame::OnEnableMenuItem`."
function frame_on_enable_menu_item(st::MenuState, event)
    item = get_last_menu_item(st)
    if item !== nothing
        enable!(item, !is_enabled(item))
    end
    return nothing
end

"`MyFrame::OnCheckMenuItem`."
function frame_on_check_menu_item(st::MenuState, event)
    item = get_last_menu_item(st)
    if item !== nothing && is_checkable(item)
        toggle!(item)
    end
    return nothing
end

"`MyFrame::OnUpdateCheckMenuItemUI`."
function frame_on_update_check_menu_item_ui(st::MenuState, event)
    ui = wxUpdateUIEvent(event.ptr)
    # wxLogNull nolog; - suppresses the "No last item" warning of GetLastMenuItem
    nolog = wxLogNull()
    try
        item = get_last_menu_item(st)
        enable!(ui, item !== nothing && is_checkable(item))
    finally
        Base.delete!(nolog)
    end
    return nothing
end

"`MyFrame::OnGetLabelMenuItem`."
function frame_on_get_label_menu_item(st::MenuState, event)
    item = get_last_menu_item(st)
    if item !== nothing
        menu_log("The label of the last menu item is '$(get_item_label(item))'")
    end
    return nothing
end

"`MyFrame::OnSetLabelMenuItem`."
function frame_on_set_label_menu_item(st::MenuState, event)
    item = get_last_menu_item(st)
    if item !== nothing
        label = menu_get_text_from_user(st, "Enter new label: ",
                                        "Change last menu item text",
                                        get_item_label(item))
        # label.Replace("\\t", "\t")
        label = replace(label, "\\t" => "\t")
        if !isempty(label)
            set_item_label!(item, label)
        end
    end
    return nothing
end

"`MyFrame::OnGetMenuItemInfo`."
function frame_on_get_menu_item_info(st::MenuState, event)
    item = get_last_menu_item(st)
    if item !== nothing
        message = "The item is " * (is_enabled(item) ? "enabled" : "disabled") * "\n"
        if is_checkable(item)
            message *= "It is checkable and " * (is_checked(item) ? "" : "un") *
                       "checked\n"
        end
        # wxMenuItem::GetAccel() itself is not bound; GetItemLabel() returns the
        # label including its accelerator, so the accelerator text is recovered
        # from the label (this sample always supplies it as "\t...").
        accel = menu_accelerator_text(item)
        if isempty(accel)
            message *= "It doesn't have an accelerator"
        else
            message *= "Its accelerator is " * accel
        end
        menu_log(message)
    end
    return nothing
end

"`MyFrame::OnFindMenuItem`."
function frame_on_find_menu_item(st::MenuState, event)
    count = get_menu_count(st.menubar)
    count == 0 && return nothing

    label = menu_get_text_from_user(st, "Enter label to search for: ",
                                    "Find menu item", "")
    if !isempty(label)
        index = KwxFFI.NOT_FOUND()
        menuindex = 0
        while menuindex < count && index == KwxFFI.NOT_FOUND()
            menu = get_menu(st.menubar, menuindex)
            index = find_menu_item(st.menubar, get_title(menu), label)
            menuindex += 1
        end
        if index == KwxFFI.NOT_FOUND()
            menu_log_warning("No menu item with label '$label'")
        else
            menu_log("Menu item $(index) in menu $(menuindex) has label '$label'")
        end
    end
    return nothing
end

# ------------------------------------------------------------- test menu ops

"`MyFrame::OnTestNormal`."
function frame_on_test_normal(st::MenuState, event)
    menu_log("Normal item selected")
    return nothing
end

"`MyFrame::OnTestCheck`."
function frame_on_test_check(st::MenuState, event)
    message = "Check item " * (is_checked(wxCommandEvent(event.ptr)) ? "" : "un") *
              "checked"
    menu_log(message)
    return nothing
end

"`MyFrame::OnTestRadio`."
function frame_on_test_radio(st::MenuState, event)
    menu_log("Radio item $(get_id(event) - Menu_Test_Radio1 + 1) selected")
    return nothing
end

"`MyFrame::OnUpdateSubMenuNormal`."
function frame_on_update_submenu_normal(st::MenuState, event)
    enable!(wxUpdateUIEvent(event.ptr), false)
    return nothing
end

"`MyFrame::OnUpdateSubMenuCheck`."
function frame_on_update_submenu_check(st::MenuState, event)
    enable!(wxUpdateUIEvent(event.ptr), true)
    return nothing
end

"`MyFrame::OnUpdateSubMenuRadio`."
function frame_on_update_submenu_radio(st::MenuState, event)
    which = get_id(event) - Menu_SubMenu_Radio1 + 1
    check!(wxUpdateUIEvent(event.ptr), which == 2)
    return nothing
end

# ------------------------------------------------------- file history items

"`MyFrame::OnFileHistoryMenuItem`."
function frame_on_file_history_menu_item(st::MenuState, event)
    event_id = get_id(event)
    fname = get_history_file(st.file_history, event_id - KwxFFI.ID_FILE1())

    message = wxString("Selected file $(fname)")
    caption = wxString("File history activated")
    try
        # wxMessageBox(msg, caption, style) - no parent
        KwxFFI.kwxMessageBox(message.ptr, caption.ptr,
                             Cint(KwxFFI.OK() | KwxFFI.ICON_INFORMATION()),
                             C_NULL, Cint(-1), Cint(-1))
    finally
        Base.delete!(message)
        Base.delete!(caption)
    end

    add_file_to_history!(st.file_history, fname)
    return nothing
end

"`MyFrame::OnFileHistoryStyleItem` - blocked by a missing binding."
function frame_on_file_history_style_item(st::MenuState, event)
    which = get_id(event) - Menu_Menu_FileHistory1 + 1
    # GAP: the wxFH_PATH_SHOW_* values are bound but
    # wxFileHistory::SetMenuPathStyle() is not, so the selected style cannot be
    # applied and the history menu keeps its default path rendering.
    menu_log_warning("File history path style $(which) selected, but " *
                     "wxFileHistory::SetMenuPathStyle() is not bound")
    return nothing
end

# ----------------------------------------------------------- menu open/close

"`MyFrame::LogMenuOpenCloseOrHighlight`."
function log_menu_open_close_or_highlight(st::MenuState, event, what::String)
    menu_event = wxMenuEvent(event.ptr)
    message = "A " * (is_popup(menu_event) ? "popup " : "") *
              "menu has been " * what

    if get_event_type(event) == KwxFFI.EVT_MENU_HIGHLIGHT()
        message *= " (id=$(get_id(event)) in "
    else
        message *= " ("
    end

    menu_ptr = get_menu(menu_event)
    if menu_ptr != C_NULL
        menu = wxMenu(menu_ptr)
        message *= "menu with title \"$(get_title(menu))\")"
    else
        message *= "no menu provided)"
    end
    message *= "."

    menu_log_status(st.frame, message)
    return nothing
end

"`MyFrame::OnMenuOpen`."
function frame_on_menu_open(st::MenuState, event)
    log_menu_open_close_or_highlight(st, event, "opened")
    skip!(event, true)
    return nothing
end

"`MyFrame::OnMenuClose`."
function frame_on_menu_close(st::MenuState, event)
    log_menu_open_close_or_highlight(st, event, "closed")
    skip!(event, true)
    return nothing
end

"`MyFrame::OnMenuHighlight`."
function frame_on_menu_highlight(st::MenuState, event)
    log_menu_open_close_or_highlight(st, event, "highlighted")
    skip!(event, true)
    return nothing
end

# ------------------------------------------------------------ context menus

"`MyFrame::ShowContextMenu(pos)`."
function show_context_menu(st::MenuState, pos_x::Int, pos_y::Int)
    menu = menu_new()

    if wxGetKeyState(KwxFFI.K_SHIFT()) != 0
        # when Shift is pressed, demonstrate the simple function returning the
        # id of the item selected in the popup menu
        set_title!(menu, "Choose one of:")
        choices = ("Apple", "Banana", "Cherry")
        for (n, choice) in enumerate(choices)
            append!(menu, Menu_PopupChoice + n - 1, choice, "", false)
        end

        rc = get_popup_menu_selection_from_user(st.frame, menu, pos_x, pos_y)
        if rc == KwxFFI.ID_NONE()
            menu_log("No selection")
        else
            menu_log("You have selected \"$(choices[rc - Menu_PopupChoice + 1])\"")
        end
    else
        append!(menu, KwxFFI.ID_ABOUT(), "&About", "", false)
        sub, _ = create_dummy_menu(st; want_title = false)
        append_sub!(menu, Menu_Popup_Submenu, "&Submenu", sub, "")
        append!(menu, Menu_Popup_ToBeDeleted, "To be &deleted", "", false)
        append_check_item!(menu, Menu_Popup_ToBeChecked, "To be &checked", "")
        append!(menu, Menu_Popup_ToBeGreyed, "To be &greyed",
                "This menu item should be initially greyed out", false)
        append_separator!(menu)

        exit_item = wxMenuItem(KwxFFI.ID_EXIT(), "E&xit", "",
                               KwxFFI.ITEM_NORMAL(), nothing)
        set_bitmap!(exit_item, menu_art_bitmap(KwxFFI.ART_QUIT, KwxFFI.ART_MENU))
        append_item!(menu, exit_item)

        delete_by_id!(menu, Menu_Popup_ToBeDeleted)
        check!(menu, Menu_Popup_ToBeChecked, true)
        enable!(menu, Menu_Popup_ToBeGreyed, false)

        popup_menu(st.frame, menu, pos_x, pos_y)
    end

    # The C++ menu is a stack object destroyed when ShowContextMenu() returns.
    menu.ptr == C_NULL || delete_pointer!(menu)
    return nothing
end

"`MyFrame::OnContextMenu`."
function frame_on_context_menu(st::MenuState, event)
    context = wxContextMenuEvent(event.ptr)
    x = Ref{Int32}(0)
    y = Ref{Int32}(0)
    get_position!(context, x, y)
    pos_x = Int(x[])
    pos_y = Int(y[])

    if pos_x == -1 && pos_y == -1
        # If from keyboard
        size = get_size(st.frame)
        pos_x = get_width(size) ÷ 2
        pos_y = get_height(size) ÷ 2
    else
        point = screen_to_client(st.frame, pos_x, pos_y)
        pos_x = get_x(point)
        pos_y = get_y(point)
    end

    show_context_menu(st, pos_x, pos_y)
    return nothing
end

"`MyFrame::OnSize` - the band below the text control is kept for popup tests."
function frame_on_size(st::MenuState, event)
    st.textctrl === nothing && return nothing

    size = get_client_size(st.frame)
    set_size!(st.textctrl, 0, 0, get_width(size), (3 * get_height(size)) ÷ 4, 0)
    # No skip!(): wxFrameBase would otherwise let the text control fill the frame.
    return nothing
end

# ---------------------------------------------------------------- the dialog

"`MyDialog::LogMenuOpenCloseOrHighlight`."
function dialog_log_open_close_or_highlight(textctrl, event, what::String)
    menu_event = wxMenuEvent(event.ptr)
    message = "A " * (is_popup(menu_event) ? "popup " : "") *
              "menu has been " * what
    if get_event_type(event) == KwxFFI.EVT_MENU_HIGHLIGHT()
        message *= " (id=$(get_id(event)))"
    end
    message *= ".\n"
    append_text!(textctrl, message)
    return nothing
end

"`MyDialog::ShowContextMenu(pos)`."
function show_dialog_context_menu(dlg, pos_x::Int, pos_y::Int)
    menu = menu_new()

    append!(menu, KwxFFI.ID_ABOUT(), "&About", "", false)
    append!(menu, Menu_Popup_ToBeDeleted, "To be &deleted", "", false)
    append_check_item!(menu, Menu_Popup_ToBeChecked, "To be &checked", "")
    append!(menu, Menu_Popup_ToBeGreyed, "To be &greyed",
            "This menu item should be initially greyed out", false)
    append_separator!(menu)
    append!(menu, KwxFFI.ID_EXIT(), "E&xit", "", false)

    delete_by_id!(menu, Menu_Popup_ToBeDeleted)
    check!(menu, Menu_Popup_ToBeChecked, true)
    enable!(menu, Menu_Popup_ToBeGreyed, false)

    popup_menu(dlg, menu, pos_x, pos_y)

    menu.ptr == C_NULL || delete_pointer!(menu)
    return nothing
end

"`MyDialog::OnContextMenu`."
function dialog_on_context_menu(dlg, textctrl, event)
    context = wxContextMenuEvent(event.ptr)
    x = Ref{Int32}(0)
    y = Ref{Int32}(0)
    get_position!(context, x, y)
    pos_x = Int(x[])
    pos_y = Int(y[])

    if pos_x == -1 && pos_y == -1
        size = get_size(dlg)
        pos_x = get_width(size) ÷ 2
        pos_y = get_height(size) ÷ 2
    else
        point = screen_to_client(dlg, pos_x, pos_y)
        pos_x = get_x(point)
        pos_y = get_y(point)
    end

    show_dialog_context_menu(dlg, pos_x, pos_y)
    return nothing
end

"""
    run_test_dialog(st)

`MyDialog dlg(this); dlg.ShowModal();`
"""
function run_test_dialog(st::MenuState)
    dlg = wxDialog(st.frame, KwxFFI.ID_ANY(), "Test Dialog", -1, -1, -1, -1,
                   KwxFFI.DEFAULT_DIALOG_STYLE())

    textctrl = wxTextCtrl(dlg, KwxFFI.ID_ANY(), "", -1, -1, -1, -1,
                          KwxFFI.TE_MULTILINE())
    set_editable!(textctrl, false)
    append_text!(textctrl, "Dialogs do not have menus, but popup menus should " *
                           "function the same\n\n" *
                           "Right click this text ctrl to test popup menus.\n")

    wx_connect!(dlg, KwxFFI.EVT_CONTEXT_MENU(),
                event -> dialog_on_context_menu(dlg, textctrl, event))
    wx_connect!(dlg, KwxFFI.EVT_MENU_OPEN(),
                event -> (dialog_log_open_close_or_highlight(textctrl, event, "opened");
                          skip!(event, true); nothing))
    wx_connect!(dlg, KwxFFI.EVT_MENU_CLOSE(),
                event -> (dialog_log_open_close_or_highlight(textctrl, event, "closed");
                          skip!(event, true); nothing))
    wx_connect!(dlg, KwxFFI.EVT_MENU_HIGHLIGHT(),
                event -> (dialog_log_open_close_or_highlight(textctrl, event, "highlighted");
                          skip!(event, true); nothing))

    result = show_modal(dlg)

    # The C++ dialog is a stack object, so its destructor destroys the window.
    # Destroy() only queues the native deletion; flush it while Julia still owns
    # the @cfunction trampolines of the dialog's event connections.
    KwxFFI.wxWindow_Destroy(dlg.ptr)
    KwxFFI.wxApp_Yield(KwxFFI.wxApp_GetApp(), Cint(0))
    push!(MENU_ROOTS, dlg)
    return result
end

# ------------------------------------------------------------ event wiring

"`wxBEGIN_EVENT_TABLE(MyFrame, wxFrame)`."
function connect_frame_events(st::MenuState)
    frame = st.frame

    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_quit(st, event);
                id = KwxFFI.ID_EXIT())
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_clear_log(st, event);
                id = Menu_File_ClearLog)
    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_clear_log_update_ui(st, event);
                id = Menu_File_ClearLog)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_show_dialog(st, event);
                id = Menu_File_ShowDialog)

    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_about(st, event);
                id = KwxFFI.ID_ABOUT())

    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_toggle_menu(st, event);
                id = Menu_MenuBar_Toggle)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_append_menu(st, event);
                id = Menu_MenuBar_Append)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_insert_menu(st, event);
                id = Menu_MenuBar_Insert)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_delete_menu(st, event);
                id = Menu_MenuBar_Delete)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_enable_menu(st, event);
                id = Menu_MenuBar_Enable)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_get_label_menu(st, event);
                id = Menu_MenuBar_GetLabel)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_set_label_menu(st, event);
                id = Menu_MenuBar_SetLabel)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_find_menu(st, event);
                id = Menu_MenuBar_FindMenu)

    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_append_menu_item(st, event); id = Menu_Menu_Append)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_append_sub_menu(st, event); id = Menu_Menu_AppendSub)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_insert_menu_item(st, event); id = Menu_Menu_Insert)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_delete_menu_item(st, event); id = Menu_Menu_Delete)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_delete_sub_menu(st, event); id = Menu_Menu_DeleteSub)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_enable_menu_item(st, event); id = Menu_Menu_Enable)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_check_menu_item(st, event); id = Menu_Menu_Check)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_get_label_menu_item(st, event); id = Menu_Menu_GetLabel)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_set_label_menu_item(st, event); id = Menu_Menu_SetLabel)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_get_menu_item_info(st, event); id = Menu_Menu_GetInfo)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_find_menu_item(st, event); id = Menu_Menu_FindItem)

    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_test_normal(st, event);
                id = Menu_Test_Normal)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_test_check(st, event);
                id = Menu_Test_Check)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_test_radio(st, event);
                id = Menu_Test_Radio1)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_test_radio(st, event);
                id = Menu_Test_Radio2)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_test_radio(st, event);
                id = Menu_Test_Radio3)

    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_file_history_menu_item(st, event);
                id = KwxFFI.ID_FILE1())
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_file_history_menu_item(st, event);
                id = KwxFFI.ID_FILE2())
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_file_history_menu_item(st, event);
                id = KwxFFI.ID_FILE3())

    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_file_history_style_item(st, event);
                id = Menu_Menu_FileHistory1)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_file_history_style_item(st, event);
                id = Menu_Menu_FileHistory2)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_file_history_style_item(st, event);
                id = Menu_Menu_FileHistory3)

    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_update_submenu_normal(st, event);
                id = Menu_SubMenu_Normal)
    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_update_submenu_check(st, event);
                id = Menu_SubMenu_Check)
    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_update_submenu_radio(st, event);
                id = Menu_SubMenu_Radio1)
    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_update_submenu_radio(st, event);
                id = Menu_SubMenu_Radio2)
    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_update_submenu_radio(st, event);
                id = Menu_SubMenu_Radio3)

    # EVT_MENU_RANGE(Menu_Dummy_First, Menu_Dummy_Last, OnDummy)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_dummy(st, event);
                id = Menu_Dummy_First, last_id = Menu_Dummy_Last)

    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_update_check_menu_item_ui(st, event);
                id = Menu_Menu_Check)

    wx_connect!(frame, KwxFFI.EVT_CONTEXT_MENU(),
                event -> frame_on_context_menu(st, event))

    wx_connect!(frame, KwxFFI.EVT_MENU_OPEN(), event -> frame_on_menu_open(st, event))
    wx_connect!(frame, KwxFFI.EVT_MENU_CLOSE(), event -> frame_on_menu_close(st, event))
    # EVT_MENU_HIGHLIGHT_ALL is wxEVT_MENU_HIGHLIGHT for every id.
    wx_connect!(frame, KwxFFI.EVT_MENU_HIGHLIGHT(),
                event -> frame_on_menu_highlight(st, event))

    wx_connect!(frame, KwxFFI.EVT_SIZE(), event -> frame_on_size(st, event))

    # PushEventHandler(new MyEvtHandler(this)): the pushed handler sees every
    # menu command before the frame's own table.  wxWidgets calls the most
    # recently bound handler first, so this catch-all is bound last.
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> (log_menu_event(st, event); skip!(event, true); nothing))

    return nothing
end

# -------------------------------------------------------------------- main

const MENU_STATE = Ref{Any}(nothing)

run_app(app_name = "wxWidgets menu sample") do
    state = build_app()
    MENU_STATE[] = state

    connect_frame_events(state)

    # frame->Show(true);
    set_top_window(state.frame)
    show(state.frame)

    # frame->SetStatusText("Welcome to wxWidgets menu sample");
    set_status_text!(state.frame, "Welcome to wxWidgets menu sample", 0)
end
