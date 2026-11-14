# about.jl — kwxJulia port of wxSamples/src/html/about/about.cpp
#
# The wxHtml "about dialog" sample: a frame titled "wxHtmlWindow testing
# application" with a File menu (About, Exit).  About opens a modal dialog that
# shows data/about.htm in a wxHtmlWindow with an SVG tiled background
# (data/bg.svg), a static line and an OK button.
#
# Run from this folder (the C++ sample loads its assets relative to the working
# directory; here they are resolved against @__DIR__ instead):
#   julia --startup-file=no .\about.jl
#
# Notes on the port:
# * `MyApp::OnInit` calls `wxImage::AddHandler(new wxPNGHandler)`.  `run_app`
#   already runs `wxApp_InitAllImageHandlers()` before the setup block, so PNG
#   (and every other format) is registered; adding a second PNG handler only
#   makes wxWidgets log "Adding duplicate image handler for 'PNG file'".
#   The handler registration is therefore left to the application layer.
# * `GetInternalRepresentation()` returns a borrowed `wxHtmlContainerCell`
#   wrapper (no finalizer, never deleted); its width/height are read with the
#   bound `get_width` / `get_height` accessors, and a failed lookup is
#   detected on `.ptr` (`==` against C_NULL is not defined for wrappers).
# * `wxDialog dlg(...)` is a stack object in C++, so it is destroyed after
#   ShowModal with the bound `destroy()`; the queued delete is flushed with
#   `wxApp::Yield()` before the handler returns.
# * `SetIcon(wxICON(sample))` loads sample.svg (converted pixel for pixel from
#   wxSamples/src/sample.xpm) through `wxBitmapBundle::GetIcon()` at its
#   original 32x32 size.
# * data/bg.svg ships byte-identical to the C++ sample (no flattening).  This
#   wxWidgets build renders wxBitmapBundle::FromSVGFile with LunaSVG, not
#   nanosvg: kwxFFI's CMakeLists.txt forces wxUSE_LUNASVG=builtin and
#   wxUSE_NANOSVG=OFF, and setup.h agrees for every configuration.  LunaSVG
#   implements all of the constructs the Inkscape file uses -- nested
#   <g transform>, group opacity, clipPath and <use>/xlink:href -- so the
#   artwork, the group-alpha compositing and the viewBox (17.777x13.096) are
#   the original ones.

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

using WxWidgets

const SAMPLE_DIR = @__DIR__

# The event table matches on the standard ids used by the File menu.
const ABOUT_QUIT = KwxFFI.ID_EXIT()
const ABOUT_ABOUT = KwxFFI.ID_ABOUT()

# Keep the frame reachable for the whole run: wx_connect! stores the event
# closures inside the frame wrapper, which the C++ loop calls back into.
const ROOTS = Any[]

"""
    load_frame_icon(frame)

`SetIcon(wxICON(sample))`.  sample.svg is the XPM conversion; the bundle is
read at its original 32x32 size and `GetIcon()` hands back an owned wxIcon.
"""
function load_frame_icon(frame::wxFrame)
    bundle = wxBitmapBundle_FromSVGFile(joinpath(SAMPLE_DIR, "sample.svg"), 32, 32)
    if bundle.ptr == C_NULL || !is_ok(bundle)
        # An unreadable asset must not abort the whole sample.
        bundle.ptr == C_NULL || Base.delete!(bundle)
        return nothing
    end

    icon = get_icon(bundle, 32, 32)   # owned wxIcon
    if icon.ptr != C_NULL
        set_icon!(frame, icon)        # SetIcon() copies the icon
    end

    # SetIcon() copied the icon, so both temporaries are ours to release.
    icon.ptr == C_NULL || Base.delete!(icon)
    Base.delete!(bundle)
    return nothing
end

"""`MyFrame::MyFrame` menu bar: File -> About, Exit."""
function build_menu_bar()
    # wxMenu *menuFile = new wxMenu;  menuFile->Append(wxID_ABOUT);
    # menuFile->Append(wxID_EXIT);
    file_menu = wxMenu("", 0)
    # Append(id) uses the stock label of the standard id (&About, E&xit).
    append_by_id!(file_menu, ABOUT_ABOUT)
    append_by_id!(file_menu, ABOUT_QUIT)

    # wxMenuBar *menuBar = new wxMenuBar; menuBar->Append(menuFile, "&File");
    menu_bar = wxMenuBar(0)
    append(menu_bar, file_menu, "&File")
    return menu_bar
end

"""
    show_about(frame)

`MyFrame::OnAbout`: the modal About dialog.
"""
function show_about(frame::wxFrame)
    # wxDialog dlg(this, wxID_ANY, wxString(_("About")));
    dlg = wxDialog(frame, KwxFFI.ID_ANY(), "About",
                   -1, -1, -1, -1, KwxFFI.DEFAULT_DIALOG_STYLE())

    # topsizer = new wxBoxSizer(wxVERTICAL);
    topsizer = wxBoxSizer(KwxFFI.VERTICAL())

    # html = new wxHtmlWindow(&dlg, wxID_ANY, wxDefaultPosition,
    #                         wxSize(380, 160), wxHW_SCROLLBAR_NEVER);
    html = wxHtmlWindow(dlg, KwxFFI.ID_ANY(), -1, -1, 380, 160,
                        KwxFFI.HW_SCROLLBAR_NEVER(), "htmlWindow")

    # html->SetBorders(0);
    set_borders!(html, 0)

    # html->LoadPage("data/about.htm");
    load_page(html, joinpath(SAMPLE_DIR, "data", "about.htm"))

    # html->SetHTMLBackgroundImage(wxBitmapBundle::FromSVGFile("data/bg.svg",
    #                                                         wxSize(65, 45)));
    bg = wxBitmapBundle_FromSVGFile(joinpath(SAMPLE_DIR, "data", "bg.svg"), 65, 45)
    if bg.ptr != C_NULL && is_ok(bg)
        set_background_image!(html, bg)
    end

    # html->SetInitialSize(wxSize(html->GetInternalRepresentation()->GetWidth(),
    #                             html->GetInternalRepresentation()->GetHeight()));
    cell = get_internal_representation(html)   # borrowed wrapper
    if cell.ptr != C_NULL
        # GetWidth()/GetHeight() of the parsed container cell.
        set_initial_size(html, get_width(cell), get_height(cell))
    end

    # topsizer->Add(html, wxSizerFlags(1).DoubleBorder());
    flags = wxSizerFlags(1)
    double_border!(flags, KwxFFI.ALL())
    add_window_flags!(topsizer, html, flags)
    Base.delete!(flags)

    # topsizer->Add(new wxStaticLine(&dlg, wxID_ANY),
    #               wxSizerFlags().Expand().DoubleHorzBorder());
    line = wxStaticLine(dlg, KwxFFI.ID_ANY(), -1, -1, -1, -1, KwxFFI.LI_HORIZONTAL())
    flags = wxSizerFlags(0)
    expand!(flags)
    double_horz_border!(flags)
    add_window_flags!(topsizer, line, flags)
    Base.delete!(flags)

    # wxButton *bu1 = new wxButton(&dlg, wxID_OK, _("OK")); bu1->SetDefault();
    ok_button = wxButton(dlg, KwxFFI.ID_OK(), "OK", -1, -1, -1, -1, 0)
    set_default!(ok_button)

    # topsizer->Add(bu1, wxSizerFlags().Right().TripleBorder());
    flags = wxSizerFlags(0)
    right!(flags)
    triple_border!(flags, KwxFFI.ALL())
    add_window_flags!(topsizer, ok_button, flags)
    Base.delete!(flags)

    # dlg.SetSizer(topsizer); topsizer->Fit(&dlg); dlg.ShowModal();
    set_sizer!(dlg, topsizer, true)
    fit!(topsizer, dlg)
    show_modal(dlg)

    # The C++ dialog is a stack object, so its destructor destroys the window.
    destroy(dlg)

    # Destroy() only queues the deletion; run it while Julia is still alive so
    # the dialog and its children do not outlive their wrappers.
    Base.yield(wxApp_GetApp(), false)

    bg.ptr == C_NULL || Base.delete!(bg)
    return nothing
end

run_app(app_name = "about") do
    # wxImage::AddHandler(new wxPNGHandler); -- already done by run_app.

    # MyFrame *frame = new MyFrame(_("wxHtmlWindow testing application"));
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "wxHtmlWindow testing application",
                    -1, -1, -1, -1, KwxFFI.DEFAULT_FRAME_STYLE())
    push!(ROOTS, frame)

    # SetIcon(wxICON(sample)); SetMenuBar(menuBar);
    load_frame_icon(frame)
    set_menu_bar!(frame, build_menu_bar())

    # wxBEGIN_EVENT_TABLE(MyFrame, wxFrame)
    #    EVT_MENU(wxID_ABOUT, MyFrame::OnAbout)
    #    EVT_MENU(wxID_EXIT,  MyFrame::OnQuit)
    # wxEND_EVENT_TABLE()
    on_quit = event -> close(frame, true)
    wx_connect!(frame, KwxFFI.EVT_MENU(), on_quit; id = ABOUT_QUIT)

    on_about = event -> show_about(frame)
    wx_connect!(frame, KwxFFI.EVT_MENU(), on_about; id = ABOUT_ABOUT)

    # frame->Show();
    set_top_window(frame)
    show(frame)
end
