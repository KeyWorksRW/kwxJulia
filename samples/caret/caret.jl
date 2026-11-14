# caret.jl — kwxJulia port of wxSamples/src/caret/caret.cpp
#
# The wxCaret sample: a "Caret wxWidgets sample" frame with a File menu
# (Blink time…, Font size…, Move caret, About, Exit), a two-pane status bar and
# a scrolled canvas that owns a wxCaret.  Typing writes into a character grid,
# the arrow keys / Home / End / Return move the caret, and the mouse wheel or
# scrollbars scroll the canvas.
#
# Run from the repository root:
#   julia samples\caret\caret.jl
#
# Mapping of the C++ structure onto this port:
#   MyApp::OnInit                 -> the run_app block at the bottom
#   MyFrame::MyFrame              -> the wxFrame(...) call in the run_app block
#                                    plus build_menu_bar()
#   MyFrame::OnQuit/OnAbout/...   -> frame_on_quit() / frame_on_about() / ...
#   MyCanvas::MyCanvas            -> build_canvas()
#   MyCanvas::SetFontSize         -> canvas_set_font_size!
#   MyCanvas::CreateCaret         -> canvas_create_caret!
#   MyCanvas::ChangeSize          -> canvas_change_size!
#   MyCanvas::MoveCaret/DoMoveCaret -> canvas_move_caret! / canvas_do_move_caret!
#   MyCanvas::Home/End/FirstLine/LastLine/PrevChar/NextChar/PrevLine/NextLine
#                                 -> canvas_home!/canvas_end!/... helpers
#   wxBEGIN_EVENT_TABLE           -> connect_events() / connect_canvas_events()
#   member fields                 -> CaretState, captured by every handler closure
#
# Asset:
#   ../sample.xpm (32x32, 10 colours) is converted pixel for pixel to
#   `sample.svg`, loaded at its original 32x32 size for SetIcon(wxICON(sample)).
#
# Substitutions / notes, all forced by the shipped surface:
#   1. wxSUNKEN_BORDER has no binding of its own; wxSUNKEN_BORDER is #defined as
#      wxBORDER_SUNKEN (include/wx/defs.h), so KwxFFI.BORDER_SUNKEN() is the
#      exact same style value.
#   2. wxLogStatus(frame, ...) and wxLogStatus(format, ...) have no binding.
#      Every call in the sample targets a frame that owns a two-pane status bar,
#      so set_status_text!(frame, text, 0) is the same observable result.
#   3. MyCanvas::OnScroll uses CallAfter() to read the caret position once the
#      scroll has actually been applied.  The raw wxEvtHandler_CallAfter entry
#      point exists, but it takes a native wxClosure whose callback would have
#      to be a sample-built @cfunction, which the binding contract forbids.  A
#      one-shot wxTimer with an id-filtered EVT_TIMER handler reproduces the
#      deferred update instead.
#   4. The wxPaintDC/wxClientDC wrappers are typed `wxDC`-less in the generated
#      layer (they derive from wxObject), so their wxDC methods are called
#      through KwxFFI.wxDC_* on `dc.ptr`.  The same applies to the menu,
#      caret and number-dialog entry points that have no ergonomic wrapper.

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

using WxWidgets

# Types the module does not export (all defined in the generated wx/*_gen.jl).
import WxWidgets: wxScrolledWindow, wxCaret, wxCaretSuspend, wxPaintDC, wxClientDC
import WxWidgets: wxFont, wxFontInfo, wxColour, wxPoint, wxSize
import WxWidgets: wxMenu, wxMenuBar, wxTimer, wxKeyEvent

# Generated operations used directly by the drawing code.
import WxWidgets: set_scrollbars!, set_background_colour, refresh_rect!
import WxWidgets: get_client_size, get_width, get_height
import WxWidgets: get_position, get_x, get_y
import WxWidgets: get_key_code, alt_down, skip!
import WxWidgets: move!, set_size!, show!, start_once

# ---------------------------------------------------------------- identifiers
#
# enum { Caret_Quit = 1, Caret_About, Caret_SetBlinkTime, Caret_SetFontSize,
#        Caret_Move, Caret_Text = 1000 };

const ID_QUIT           = 1
const ID_ABOUT          = 2
const ID_SET_BLINK_TIME = 3
const ID_SET_FONT_SIZE  = 4
const ID_MOVE           = 5

# The timer that emulates MyCanvas::OnScroll's CallAfter() (see note 3 above).
const ID_SCROLL_TIMER = 5000

# ------------------------------------------------------------- root anchoring
#
# wx_connect! keeps its @cfunction inside the window wrapper it is given; the
# C++ side owns the menu/sizer/window graph.  ROOTS pins every wrapper that must
# outlive the event loop so the GC cannot collect a wrapper together with the
# closures the native handlers point at.

const ROOTS = Any[]

# --------------------------------------------------------------- shared state
#
# The member fields of MyCanvas, plus the frame/canvas/timer handles the
# handlers need.

mutable struct CaretState
    frame::Union{wxFrame, Nothing}
    canvas::Union{wxScrolledWindow, Nothing}
    caret::Union{wxCaret, Nothing}
    font::Union{wxFont, Nothing}
    timer::Union{wxTimer, Nothing}
    text::Vector{UInt32}
    x_margin::Int
    y_margin::Int
    width_char::Int
    height_char::Int
    x_caret::Int
    y_caret::Int
    x_chars::Int
    y_chars::Int
end

CaretState() = CaretState(nothing, nothing, nothing, nothing, nothing,
                          UInt32[], 5, 5, 0, 0, 0, 0, 0, 0)

# ------------------------------------------------------------------- wxString
#
# Every raw KwxFFI string parameter is a wxString*.  wxString owns its native
# pointer through a finalizer, so binding each temporary to a local for the
# length of the ccall is enough on every path; `Base.delete!` releases it early.

"""
    with_wxstring(f, text)

Call `f(ws.ptr)` with a `wxString` holding `text` and free it afterwards.
"""
function with_wxstring(f::Function, text::AbstractString)
    ws = wxString(text)
    try
        return f(ws.ptr)
    finally
        Base.delete!(ws)
    end
end

# ---------------------------------------------------------------------- menus

"""`menu->Append(id, text, help)` — non-checkable item."""
function menu_append!(menu::wxMenu, id::Integer, text::String, help::String = "")
    text_ws = wxString(text)
    help_ws = wxString(help)
    try
        KwxFFI.wxMenu_Append(menu.ptr, Cint(id), text_ws.ptr, help_ws.ptr, Cint(0))
    finally
        Base.delete!(text_ws)
        Base.delete!(help_ws)
    end
    return nothing
end

"""`menu->AppendSeparator()`."""
function menu_append_separator!(menu::wxMenu)
    KwxFFI.wxMenu_AppendSeparator(menu.ptr)
    return nothing
end

"""`menuBar->Append(menu, title)`."""
function menu_bar_append!(menu_bar::wxMenuBar, menu::wxMenu, title::String)
    title_ws = wxString(title)
    try
        KwxFFI.wxMenuBar_Append(menu_bar.ptr, menu.ptr, title_ws.ptr)
    finally
        Base.delete!(title_ws)
    end
    return nothing
end

"""`MyFrame::MyFrame` menu bar."""
function build_menu_bar()
    file_menu = wxMenu("", 0)
    push!(ROOTS, file_menu)

    # menuFile->Append(Caret_SetBlinkTime, "&Blink time...\tCtrl-B");
    menu_append!(file_menu, ID_SET_BLINK_TIME, "&Blink time...\tCtrl-B")
    # menuFile->Append(Caret_SetFontSize, "&Font size...\tCtrl-S");
    menu_append!(file_menu, ID_SET_FONT_SIZE, "&Font size...\tCtrl-S")
    # menuFile->Append(Caret_Move, "&Move caret\tCtrl-C");
    menu_append!(file_menu, ID_MOVE, "&Move caret\tCtrl-C")

    menu_append_separator!(file_menu)

    # menuFile->Append(Caret_About, "&About\tCtrl-A", "Show about dialog");
    menu_append!(file_menu, ID_ABOUT, "&About\tCtrl-A", "Show about dialog")

    menu_append_separator!(file_menu)

    # menuFile->Append(Caret_Quit, "E&xit\tAlt-X", "Quit this program");
    menu_append!(file_menu, ID_QUIT, "E&xit\tAlt-X", "Quit this program")

    menu_bar = wxMenuBar(0)
    push!(ROOTS, menu_bar)
    menu_bar_append!(menu_bar, file_menu, "&File")
    return menu_bar
end

# ------------------------------------------------------------------- wxCaret

function canvas_do_move_caret!(st::CaretState)
    # wxLogStatus("Caret is at (%d, %d)", m_xCaret, m_yCaret);
    log_status(st.frame, "Caret is at ($(st.x_caret), $(st.y_caret))")

    st.caret === nothing && return nothing
    # GetCaret()->Move(m_xMargin + m_xCaret * m_widthChar,
    #                  m_yMargin + m_yCaret * m_heightChar);
    move!(st.caret,
          st.x_margin + st.x_caret * st.width_char,
          st.y_margin + st.y_caret * st.height_char)
    return nothing
end

"""`MyCanvas::MoveCaret(x, y)`."""
function canvas_move_caret!(st::CaretState, x::Integer, y::Integer)
    st.x_caret = Int(x)
    st.y_caret = Int(y)
    canvas_do_move_caret!(st)
    return nothing
end

"""`MyCanvas::CreateCaret` — the window takes ownership of the new caret."""
function canvas_create_caret!(st::CaretState)
    caret = wxCaret(st.canvas, st.width_char, st.height_char)
    # SetCaret() deletes any previous caret; the window owns the new one, so the
    # wrapper must never be freed here.
    KwxFFI.wxWindow_SetCaret(st.canvas.ptr, caret.ptr)
    st.caret = caret

    move!(caret, st.x_margin, st.y_margin)
    show!(caret)
    return nothing
end

# ------------------------------------------------------------- character grid

"""`MyCanvas::CharAt(x, y)` read; 0 outside the current grid."""
function char_at(st::CaretState, x::Integer, y::Integer)
    (x < 0 || y < 0 || x >= st.x_chars || y >= st.y_chars) && return UInt32(0)
    index = x + st.x_chars * y + 1
    return index <= length(st.text) ? st.text[index] : UInt32(0)
end

"""`MyCanvas::CharAt(x, y) = ch`; ignored outside the current grid."""
function set_char_at!(st::CaretState, x::Integer, y::Integer, ch::UInt32)
    (x < 0 || y < 0 || x >= st.x_chars || y >= st.y_chars) && return nothing
    index = x + st.x_chars * y + 1
    index <= length(st.text) && (st.text[index] = ch)
    return nothing
end

# ------------------------------------------------------------ caret movement
#
# Direct translations of the inline methods in the C++ header.

function canvas_home!(st::CaretState)
    st.x_caret = 0
    return nothing
end

function canvas_end!(st::CaretState)
    st.x_caret = st.x_chars - 1
    return nothing
end

function canvas_first_line!(st::CaretState)
    st.y_caret = 0
    return nothing
end

function canvas_last_line!(st::CaretState)
    st.y_caret = st.y_chars - 1
    return nothing
end

# void PrevChar() { if ( !m_xCaret-- ) { End(); PrevLine(); } }
function canvas_prev_char!(st::CaretState)
    st.x_caret -= 1
    if st.x_caret < 0
        canvas_end!(st)
        canvas_prev_line!(st)
    end
    return nothing
end

# void NextChar() { if ( ++m_xCaret == m_xChars ) { Home(); NextLine(); } }
function canvas_next_char!(st::CaretState)
    st.x_caret += 1
    if st.x_caret == st.x_chars
        canvas_home!(st)
        canvas_next_line!(st)
    end
    return nothing
end

# void PrevLine() { if ( !m_yCaret-- ) LastLine(); }
function canvas_prev_line!(st::CaretState)
    st.y_caret -= 1
    if st.y_caret < 0
        canvas_last_line!(st)
    end
    return nothing
end

# void NextLine() { if ( ++m_yCaret == m_yChars ) FirstLine(); }
function canvas_next_line!(st::CaretState)
    st.y_caret += 1
    if st.y_caret == st.y_chars
        canvas_first_line!(st)
    end
    return nothing
end

# ------------------------------------------------------------------- geometry

"""`MyCanvas::ChangeSize`."""
function canvas_change_size!(st::CaretState)
    (st.width_char <= 0 || st.height_char <= 0) && return nothing

    size = get_client_size(st.canvas)
    client_width = 0
    client_height = 0
    try
        client_width = get_width(size)
        client_height = get_height(size)
    finally
        Base.delete!(size)
    end

    st.x_chars = div(client_width - 2 * st.x_margin, st.width_char)
    st.y_chars = div(client_height - 2 * st.y_margin, st.height_char)
    # The C++ only promotes an exact zero; clamp negative values from a
    # degenerate client size so the buffer allocation below stays valid.
    st.x_chars = max(st.x_chars, 1)
    st.y_chars = max(st.y_chars, 1)

    # free(m_text); m_text = calloc(m_xChars * m_yChars, sizeof(wxChar));
    st.text = zeros(UInt32, st.x_chars * st.y_chars)

    # SetScrollbars(m_widthChar, m_heightChar, m_xChars + 10, m_yChars + 10);
    set_scrollbars!(st.canvas, st.width_char, st.height_char,
                    st.x_chars + 10, st.y_chars + 10, 0, 0, false)

    # frame = wxDynamicCast(GetParent(), wxFrame); if (frame && frame->GetStatusBar())
    if st.frame !== nothing && KwxFFI.wxFrame_GetStatusBar(st.frame.ptr) != C_NULL
        set_status_text!(st.frame, "Panel size is ($(st.x_chars), $(st.y_chars))", 1)
    end
    return nothing
end

"""`MyCanvas::SetFontSize(fontSize)`."""
function canvas_set_font_size!(st::CaretState, font_size::Integer)
    info = wxFontInfo(Float64(font_size))
    new_font = nothing
    dc = nothing
    try
        # wxFont(wxFontInfo(fontSize).Family(wxFONTFAMILY_TELETYPE));
        KwxFFI.wxFontInfo_SetFamily(info.ptr, Cint(KwxFFI.FONTFAMILY_TELETYPE()))
        new_font = wxFont(info)

        # wxClientDC dc(this); dc.SetFont(m_font);
        # m_heightChar = dc.GetCharHeight(); m_widthChar = dc.GetCharWidth();
        dc = wxClientDC(st.canvas)
        KwxFFI.wxDC_SetFont(dc.ptr, new_font.ptr)
        st.height_char = Int(KwxFFI.wxDC_GetCharHeight(dc.ptr))
        st.width_char = Int(KwxFFI.wxDC_GetCharWidth(dc.ptr))
    finally
        dc === nothing || Base.delete!(dc)
        Base.delete!(info)
    end

    old_font = st.font
    st.font = new_font
    old_font === nothing || Base.delete!(old_font)

    # wxCaret *caret = GetCaret(); if (caret) { caret->SetSize(...); ChangeSize(); }
    if st.caret !== nothing
        set_size!(st.caret, st.width_char, st.height_char)
        canvas_change_size!(st)
    end
    return nothing
end

# ----------------------------------------------------------------- status log
#
# wxLogStatus(frame, ...) with a status bar writes into pane 0; that is exactly
# what set_status_text!(frame, text, 0) does (note 2 in the header).

function log_status(frame, text::String)
    frame === nothing && return nothing
    set_status_text!(frame, text, 0)
    return nothing
end

# ------------------------------------------------------------------- drawing

"""`wxIsprint(event.GetKeyCode())`."""
function wx_isprint(code::Integer)
    code <= 0 && return false
    code > 0x10ffff && return false
    isvalid(Char, code) || return false
    return isprint(Char(code))
end

# -------------------------------------------------------------- canvas events

"""`MyCanvas::OnPaint`."""
function canvas_on_paint(st::CaretState, event)
    # wxCaretSuspend cs(this);
    suspend = wxCaretSuspend(st.canvas)
    dc = nothing
    try
        dc = wxPaintDC(st.canvas)
        # PrepareDC(dc): wxPaintDC is not a wxDC subtype in the generated layer.
        KwxFFI.wxScrolledWindow_PrepareDC(st.canvas.ptr, dc.ptr)
        KwxFFI.wxDC_Clear(dc.ptr)        # dc.Clear()

        st.font === nothing || KwxFFI.wxDC_SetFont(dc.ptr, st.font.ptr)

        for y in 0:(st.y_chars - 1)
            line = IOBuffer()
            for x in 0:(st.x_chars - 1)
                ch = char_at(st, x, y)
                printable = ch == 0 || !isvalid(Char, ch) ? ' ' : Char(ch)
                print(line, printable)
            end
            text = String(take!(line))
            isempty(text) && continue
            with_wxstring(text) do ptr
                KwxFFI.wxDC_DrawText(dc.ptr, ptr, Cint(st.x_margin),
                                     Cint(st.y_margin + y * st.height_char))
            end
        end
    finally
        dc === nothing || Base.delete!(dc)
        Base.delete!(suspend)
    end
    return nothing
end

"""`MyCanvas::OnSize`."""
function canvas_on_size(st::CaretState, event)
    canvas_change_size!(st)
    skip!(event, true)
    return nothing
end

"""`MyCanvas::OnChar`."""
function canvas_on_char(st::CaretState, event)
    # The event arrives as wxEvent*; its dynamic type for EVT_CHAR is wxKeyEvent.
    key_event = wxKeyEvent(event.ptr)
    code = get_key_code(key_event)

    if code == KwxFFI.K_LEFT()
        canvas_prev_char!(st)
    elseif code == KwxFFI.K_RIGHT()
        canvas_next_char!(st)
    elseif code == KwxFFI.K_UP()
        canvas_prev_line!(st)
    elseif code == KwxFFI.K_DOWN()
        canvas_next_line!(st)
    elseif code == KwxFFI.K_HOME()
        canvas_home!(st)
    elseif code == KwxFFI.K_END()
        canvas_end!(st)
    elseif code == KwxFFI.K_RETURN()
        canvas_home!(st)
        canvas_next_line!(st)
    elseif !alt_down(key_event) && wx_isprint(code)
        set_char_at!(st, st.x_caret, st.y_caret, UInt32(code))

        # RefreshRect(rect, false /* don't erase background */);
        refresh_rect!(st.canvas, false,
                      st.x_margin + st.x_caret * st.width_char,
                      st.y_margin + st.y_caret * st.height_char,
                      st.width_char, st.height_char)

        canvas_next_char!(st)
    else
        skip!(event, true)
    end

    canvas_do_move_caret!(st)
    return nothing
end

"""
`MyCanvas::OnScroll`.

The C++ schedules the position update with `CallAfter()` after the scroll has
been handled.  A one-shot timer started here and handled by
`canvas_on_scroll_timer` reproduces that ordering (see note 3 in the header).
"""
function canvas_on_scroll(st::CaretState, event)
    st.timer === nothing || start_once(st.timer, 1)
    skip!(event, true)
    return nothing
end

"""The deferred half of `MyCanvas::OnScroll` (was the CallAfter() lambda)."""
function canvas_on_scroll_timer(st::CaretState, event)
    (st.caret === nothing || st.width_char <= 0 || st.height_char <= 0) &&
        return nothing

    pos = get_position(st.caret)
    caret_x = 0
    caret_y = 0
    try
        caret_x = get_x(pos)
        caret_y = get_y(pos)
    finally
        Base.delete!(pos)
    end

    st.x_caret = div(caret_x - st.x_margin, st.width_char)
    st.y_caret = div(caret_y - st.y_margin, st.height_char)
    log_status(st.frame, "Caret is at ($(st.x_caret), $(st.y_caret))")
    return nothing
end

# ------------------------------------------------------------------ canvas build

"""`MyCanvas::MyCanvas(parent)`."""
function build_canvas(frame::wxFrame, st::CaretState)
    canvas = wxScrolledWindow(frame, KwxFFI.ID_ANY(),
                              -1, -1, -1, -1,   # wxDefaultPosition/Size
                              KwxFFI.BORDER_SUNKEN())
    st.canvas = canvas
    st.frame = frame
    push!(ROOTS, canvas)

    # SetBackgroundColour(wxSystemSettings::GetColour(wxSYS_COLOUR_WINDOW));
    colour = wxColour()
    try
        KwxFFI.wxSystemSettings_GetColour(Cint(KwxFFI.SYS_COLOUR_WINDOW()), colour.ptr)
        set_background_colour(canvas, colour)
    finally
        Base.delete!(colour)
    end

    canvas_set_font_size!(st, 12)

    st.x_caret = 0
    st.y_caret = 0
    st.x_chars = 0
    st.y_chars = 0
    st.x_margin = 5
    st.y_margin = 5

    canvas_create_caret!(st)
    return canvas
end

"""`wxBEGIN_EVENT_TABLE(MyCanvas, wxScrolledWindow)`."""
function connect_canvas_events(st::CaretState)
    canvas = st.canvas

    wx_connect!(canvas, KwxFFI.EVT_PAINT(), event -> canvas_on_paint(st, event))
    wx_connect!(canvas, KwxFFI.EVT_SIZE(), event -> canvas_on_size(st, event))
    wx_connect!(canvas, KwxFFI.EVT_CHAR(), event -> canvas_on_char(st, event))

    # EVT_SCROLLWIN() covers the whole wxEVT_SCROLLWIN_* range; the binding
    # connects one event type per call, so all eight are registered.
    for event_type in (KwxFFI.EVT_SCROLLWIN_TOP(),
                       KwxFFI.EVT_SCROLLWIN_BOTTOM(),
                       KwxFFI.EVT_SCROLLWIN_LINEUP(),
                       KwxFFI.EVT_SCROLLWIN_LINEDOWN(),
                       KwxFFI.EVT_SCROLLWIN_PAGEUP(),
                       KwxFFI.EVT_SCROLLWIN_PAGEDOWN(),
                       KwxFFI.EVT_SCROLLWIN_THUMBTRACK(),
                       KwxFFI.EVT_SCROLLWIN_THUMBRELEASE())
        wx_connect!(canvas, event_type, event -> canvas_on_scroll(st, event))
    end

    # One-shot timer standing in for CallAfter() (note 3).
    timer = wxTimer(canvas, ID_SCROLL_TIMER)
    st.timer = timer
    push!(ROOTS, timer)
    wx_connect!(canvas, KwxFFI.EVT_TIMER(),
                event -> canvas_on_scroll_timer(st, event); id = ID_SCROLL_TIMER)
    return nothing
end

# ------------------------------------------------------------------ frame events

"""`MyFrame::OnQuit` — Close(true)."""
function frame_on_quit(frame::wxFrame, event)
    close(frame, true)
    return nothing
end

"""`MyFrame::OnAbout` — wxMessageBox(..., wxOK | wxICON_INFORMATION, this)."""
function frame_on_about(frame::wxFrame, event)
    with_wxstring("The caret wxWidgets sample.\n(c) 1999 Vadim Zeitlin") do message
        with_wxstring("About Caret") do caption
            KwxFFI.kwxMessageBox(message, caption,
                                 Cint(KwxFFI.OK() | KwxFFI.ICON_INFORMATION()),
                                 frame.ptr, Cint(-1), Cint(-1))
        end
    end
    return nothing
end

"""`MyFrame::OnCaretMove` — m_canvas->MoveCaret(10, 10)."""
function frame_on_caret_move(st::CaretState, event)
    canvas_move_caret!(st, 10, 10)
    return nothing
end

"""`MyFrame::OnSetBlinkTime`."""
function frame_on_set_blink_time(st::CaretState, event)
    blink_time = with_wxstring("The caret blink time is the time between two blinks") do message
        with_wxstring("Time in milliseconds:") do prompt
            with_wxstring("wxCaret sample") do caption
                KwxFFI.wxGetNumberFromUser(message, prompt, caption,
                                           Clong(KwxFFI.wxCaret_GetBlinkTime()),
                                           Clong(0), Clong(10000),
                                           st.frame.ptr, Cint(-1), Cint(-1))
            end
        end
    end

    if blink_time != -1
        KwxFFI.wxCaret_SetBlinkTime(Cint(blink_time))
        canvas_create_caret!(st)
        # wxLogStatus(this, "Blink time set to %ld milliseconds.", blinkTime);
        log_status(st.frame, "Blink time set to $(blink_time) milliseconds.")
    end
    return nothing
end

"""`MyFrame::OnSetFontSize`."""
function frame_on_set_font_size(st::CaretState, event)
    font_size = with_wxstring("The font size also determines the caret size so\nthis demonstrates resizing the caret.") do message
        with_wxstring("Font size (in points):") do prompt
            with_wxstring("wxCaret sample") do caption
                KwxFFI.wxGetNumberFromUser(message, prompt, caption,
                                           Clong(12), Clong(1), Clong(100),
                                           st.frame.ptr, Cint(-1), Cint(-1))
            end
        end
    end

    if font_size != -1
        canvas_set_font_size!(st, Int(font_size))
    end
    return nothing
end

# ---------------------------------------------------------------- frame icon
#
# SetIcon(wxICON(sample)): `sample.svg` is the pixel-exact conversion of the
# 32x32 XPM the C++ sample compiles in.  SAMPLE_DIR is this folder; assets are
# anchored at load time so the port does not depend on the working directory.

"""
    load_frame_icon(frame)

`SetIcon(wxICON(sample))` — load `sample.svg` at its original 32x32 size and
copy it into a wxIcon for the frame.
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
        @warn "caret.jl: could not load the frame icon" svg = svg_path
        return nothing
    end

    bitmap = KwxFFI.wxBitmapBundle_GetBitmap(bundle, Cint(32), Cint(32))
    icon = KwxFFI.wxIcon_CreateDefault()
    if bitmap != C_NULL && icon != C_NULL
        KwxFFI.wxIcon_CopyFromBitmap(icon, bitmap)
        KwxFFI.wxFrame_SetIcon(frame.ptr, icon)
    end

    # SetIcon() copied the icon, so the three temporaries are ours to release.
    icon == C_NULL || KwxFFI.wxIcon_Delete(icon)
    bitmap == C_NULL || KwxFFI.wxBitmap_Delete(bitmap)
    KwxFFI.wxBitmapBundle_Delete(bundle)
    return nothing
end

# ----------------------------------------------------------------------- run

run_app(app_name = "caret") do
    st = CaretState()
    push!(ROOTS, st)

    # MyFrame *frame = new MyFrame("Caret wxWidgets sample",
    #                              wxPoint(50, 50), wxSize(450, 340));
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "Caret wxWidgets sample",
                    50, 50, 450, 340, KwxFFI.DEFAULT_FRAME_STYLE())
    st.frame = frame
    push!(ROOTS, frame)

    load_frame_icon(frame)

    set_menu_bar!(frame, build_menu_bar())

    build_canvas(frame, st)
    connect_canvas_events(st)

    # CreateStatusBar(2); SetStatusText("Welcome to wxWidgets!");
    create_status_bar(frame, 2, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Welcome to wxWidgets!", 0)

    # wxBEGIN_EVENT_TABLE(MyFrame, wxFrame)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_quit(frame, event);
                id = ID_QUIT)
    wx_connect!(frame, KwxFFI.EVT_MENU(), event -> frame_on_about(frame, event);
                id = ID_ABOUT)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_set_blink_time(st, event); id = ID_SET_BLINK_TIME)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_set_font_size(st, event); id = ID_SET_FONT_SIZE)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_caret_move(st, event); id = ID_MOVE)

    set_top_window(frame)
    show(frame)
end
