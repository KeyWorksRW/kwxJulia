# calendar.jl — kwxJulia port of wxSamples/src/calendar/calendar.cpp
#
# The wxWidgets calendar sample.  A "Calendar wxWidgets sample" frame whose
# client area is a horizontal splitter: the calendar panel on top and a
# read-only log window below.  A four-page menu bar (File, Calendar, Date
# picker, Time picker) exercises every wxCalendarCtrl style bit, the custom day
# attributes, the date-range restriction and the two picker dialogs.
#
# Run from the repository root:
#   julia samples\calendar\calendar.jl
#
# Mapping of the C++ structure onto this port:
#   MyApp::OnInit        -> the run_app block at the bottom of the file
#   MyFrame              -> build_frame() + the frame_on_* handlers
#   MyPanel              -> build_panel() + the panel_on_* handlers
#   MyDateDialog         -> show_date_dialog()
#   MyTimeDialog         -> show_time_dialog()
#   wxBEGIN_EVENT_TABLE  -> connect_frame_events() / connect_calendar_events()
#   member fields        -> AppState, captured by every handler closure
#
# Assets: the C++ sample sets the frame icon from the compiled-in sample.xpm
# array (../sample.xpm).  It is converted pixel for pixel to `sample.svg` next
# to this file and loaded at its original 32x32 size.
#
# Surface note: `WxWidgets` exports the frame/static-text/text-control/sizer
# ergonomics but not the calendar, picker, splitter, dialog, datetime or icon
# wrapper types.  Those wrappers exist in the module (wx/wx*_gen.jl are included
# into it), so the sample imports them by name.  This is required, not cosmetic:
# `wx_connect!` dispatches on `wxWindow`, so the calendar must be a real wrapper
# handle for its event table to be expressible without a hand-written
# `@cfunction`.  Everything that has a raw `KwxFFI` entry point and does not
# need event binding — sizers through pointers, dates, menus, logging, the icon
# pipeline — goes through `KwxFFI.<name>`.

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

using WxWidgets

import WxWidgets: wxWindow
import WxWidgets: wxPanel, wxSplitterWindow
import WxWidgets: wxCalendarCtrl, wxGenericCalendarCtrl, wxCalendarDateAttr
import WxWidgets: wxDatePickerCtrl, wxTimePickerCtrl, wxDialog
import WxWidgets: wxDateTime, wxDateSpan

# ---------------------------------------------------------------- identifiers
#
# enum { ... } from calendar.cpp.  The three wxID_* aliases keep the stock
# identifiers; the rest are the explicit numeric values the sample assigns.

const Calendar_File_About    = KwxFFI.ID_ABOUT()
const Calendar_File_ClearLog = KwxFFI.ID_CLEAR()
const Calendar_File_Quit     = KwxFFI.ID_EXIT()

const Calendar_Cal_Generic       = 200
const Calendar_Cal_AutoWeekday   = 201
const Calendar_Cal_Sunday        = 202
const Calendar_Cal_Monday        = 203
const Calendar_Cal_Holidays      = 204
const Calendar_Cal_Special       = 205
const Calendar_Cal_Month         = 206
const Calendar_Cal_LimitDates    = 207
const Calendar_Cal_SeqMonth      = 208
const Calendar_Cal_SurroundWeeks = 209
const Calendar_Cal_WeekNumbers   = 210
const Calendar_Cal_SetDate       = 211
const Calendar_Cal_Today         = 212
const Calendar_Cal_BeginDST      = 213
const Calendar_Cal_Resizable     = 214

const Calendar_DatePicker_AskDate       = 300
const Calendar_DatePicker_ShowCentury   = 301
const Calendar_DatePicker_DropDown      = 302
const Calendar_DatePicker_AllowNone     = 303
const Calendar_DatePicker_StartWithNone = 304
# Calendar_DatePicker_Generic (305) and Calendar_TimePicker_Generic (401) are
# guarded by wxUSE_*PICKCTRL_GENERIC, both 0 in this build:
#   build/_deps/wxwidgets-build/lib/vc_x64_lib/mswu/wx/setup.h

const Calendar_TimePicker_AskTime = 400

const Calendar_CalCtrl = 1000

# ------------------------------------------------------------- root anchoring
#
# wx_connect! keeps its @cfunction inside the window wrapper it is given, and the
# C++ side holds plain pointers to the panel, calendar and log control.  ROOTS
# pins the whole object graph for as long as the event loop runs.

const ROOTS = Any[]

# --------------------------------------------------------------- shared state
#
# The member fields of MyFrame and MyPanel that the handlers mutate.

mutable struct AppState
    frame::Union{wxFrame, Nothing}
    menu_bar::Ptr{Cvoid}
    log_window::Union{wxTextCtrl, Nothing}
    panel::Union{wxPanel, Nothing}
    date_label::Union{wxStaticText, Nothing}
    calendar::Union{wxCalendarCtrl, wxGenericCalendarCtrl, Nothing}
    sizer::Ptr{Cvoid}
    using_generic::Bool
    # `static wxDateTime s_dateLast` in MyPanel::OnCalendar
    date_last::Union{wxDateTime, Nothing}
end

AppState() = AppState(nothing, C_NULL, nothing, nothing, nothing, nothing,
                      C_NULL, false, nothing)

cal_ptr(state::AppState) = state.calendar.ptr

# ------------------------------------------------------------------- wxString
#
# String arguments reach KwxFFI as wxString*.  wxString owns its native pointer
# through a finalizer and `Base.delete!` releases it early, so binding each one
# to a local for the duration of the ccall suffices on every path.

"""Read and free a wxString* returned by a getter we do not own."""
function cal_take_wxstring(ptr::Ptr{Cvoid})
    ptr == C_NULL && return ""
    ws = wxString(ptr, false)
    try
        return String(ws)
    finally
        Base.delete!(ws)
    end
end

"""`menu->Append(id, text, help)` — non-checkable."""
function cal_menu_append!(menu::Ptr{Cvoid}, id::Integer, text::String, help::String = "")
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

"""`menu->Append(id, text, help, true)` — checkable item."""
function cal_menu_append_checkable!(menu::Ptr{Cvoid}, id::Integer, text::String,
                                    help::String = "")
    text_ws = wxString(text)
    help_ws = wxString(help)
    try
        KwxFFI.wxMenu_Append(menu, Cint(id), text_ws.ptr, help_ws.ptr, Cint(1))
    finally
        Base.delete!(text_ws)
        Base.delete!(help_ws)
    end
    return nothing
end

"""`menu->AppendRadioItem(id, text)`."""
function cal_menu_append_radio!(menu::Ptr{Cvoid}, id::Integer, text::String,
                                help::String = "")
    text_ws = wxString(text)
    help_ws = wxString(help)
    try
        KwxFFI.wxMenu_AppendRadioItem(menu, Cint(id), text_ws.ptr, help_ws.ptr)
    finally
        Base.delete!(text_ws)
        Base.delete!(help_ws)
    end
    return nothing
end

"""`menuBar->Append(menu, title)`."""
function cal_menu_bar_append!(menu_bar::Ptr{Cvoid}, menu::Ptr{Cvoid}, title::String)
    title_ws = wxString(title)
    try
        KwxFFI.wxMenuBar_Append(menu_bar, menu, title_ws.ptr)
    finally
        Base.delete!(title_ws)
    end
    return nothing
end

# --------------------------------------------------------------------- logging
#
# MyFrame installs `wxLog::SetActiveTarget(new wxLogTextCtrl(m_logWindow))`, so
# every wxLogMessage / wxLogStatus / wxLogWarning of the sample lands in the log
# pane.  The sample never creates a status bar, so wxLogStatus is a no-op in the
# C++ original as well — the calls are reproduced unchanged.

for (jl_name, c_name) in ((:cal_log_message, :LogMessage),
                          (:cal_log_status, :LogStatus),
                          (:cal_log_warning, :LogWarning))
    @eval function $jl_name(text::String)
        ws = wxString(text)
        try
            KwxFFI.$c_name(ws.ptr)
        finally
            Base.delete!(ws)
        end
        return nothing
    end
end

"""`wxMessageBox(message, caption, style, parent)`."""
function cal_message_box(message::String, caption::String, style::Integer, parent)
    message_ws = wxString(message)
    caption_ws = wxString(caption)
    parent_ptr = parent === nothing ? C_NULL : parent.ptr
    try
        KwxFFI.kwxMessageBox(message_ws.ptr, caption_ws.ptr, Cint(style), parent_ptr,
                             Cint(-1), Cint(-1))
    finally
        Base.delete!(message_ws)
        Base.delete!(caption_ws)
    end
    return nothing
end

# ------------------------------------------------------------------ wxDateTime
#
# Every helper that creates a wxDateTime returns a caller-owned object; the
# caller deletes it.  `wxDateTime()` attaches no finalizer, so the explicit
# `Base.delete!` calls below are the only release path.

"""`wxDateTime::Local` — the TZ enum value used by the getters."""
cal_tz_local() = KwxFFI.DateTime_Local()

"""`wxDateTime::Today()`."""
function cal_date_today()
    dt = wxDateTime()
    KwxFFI.wxDateTime_Today(dt.ptr)
    return dt
end

"""`wxDateTime(day, month, year, hour, min, sec)`."""
function cal_date_new(day::Integer, month::Integer, year::Integer;
                      hour::Integer = 0, minute::Integer = 0,
                      second::Integer = 0, millisec::Integer = 0)
    dt = wxDateTime()
    KwxFFI.wxDateTime_Set(dt.ptr, Cint(day), Cint(month), Cint(year),
                          Cint(hour), Cint(minute), Cint(second), Cint(millisec))
    return dt
end

"""`wxDefaultDateTime` — the invalid value."""
cal_date_invalid() = wxDateTime()

cal_date_valid(dt::wxDateTime) = KwxFFI.wxDateTime_IsValid(dt.ptr) != 0

cal_date_year(dt::wxDateTime) =
    Int(KwxFFI.wxDateTime_GetYear(dt.ptr, Cint(cal_tz_local())))
cal_date_month(dt::wxDateTime) =
    Int(KwxFFI.wxDateTime_GetMonth(dt.ptr, Cint(cal_tz_local())))
cal_date_day(dt::wxDateTime) =
    Int(KwxFFI.wxDateTime_GetDay(dt.ptr, Cint(cal_tz_local())))
cal_date_hour(dt::wxDateTime) =
    Int(KwxFFI.wxDateTime_GetHour(dt.ptr, Cint(cal_tz_local())))
cal_date_minute(dt::wxDateTime) =
    Int(KwxFFI.wxDateTime_GetMinute(dt.ptr, Cint(cal_tz_local())))
cal_date_second(dt::wxDateTime) =
    Int(KwxFFI.wxDateTime_GetSecond(dt.ptr, Cint(cal_tz_local())))
cal_date_millisecond(dt::wxDateTime) =
    Int(KwxFFI.wxDateTime_GetMillisecond(dt.ptr, Cint(cal_tz_local())))

# GetWeekOfYear() in the C++ sample is called with the defaults,
# (wxDateTime::Monday_First, wxDateTime::Local).
cal_date_week_of_year(dt::wxDateTime) = Int(KwxFFI.wxDateTime_GetWeekOfYear(
    dt.ptr, Cint(KwxFFI.DateTime_Monday_First()), Cint(cal_tz_local())))

cal_date_iso(dt::wxDateTime) =
    cal_take_wxstring(KwxFFI.wxDateTime_FormatISODate(dt.ptr))
cal_date_iso_time(dt::wxDateTime) =
    cal_take_wxstring(KwxFFI.wxDateTime_FormatISOTime(dt.ptr))

"""`wxDateTime::GetMonthName(month)` with the default (full, formatting) form."""
cal_month_name(month::Integer) = cal_take_wxstring(
    KwxFFI.wxDateTime_GetMonthName(Cint(month), Cint(KwxFFI.DateTime_Name_Full())))

"""`wxDateTime::GetWeekDayName(wd)` with the default (full) form."""
cal_weekday_name(weekday::Integer) = cal_take_wxstring(
    KwxFFI.wxDateTime_GetWeekDayName(Cint(weekday), Cint(KwxFFI.DateTime_Name_Full())))

"""A detached copy of `dt` (`s_dateLast = event.GetDate()`)."""
function cal_date_copy(dt::wxDateTime)
    # wxDateTime::Set() asserts on an invalid date, so an invalid source yields
    # an invalid copy instead (wxDefaultDateTime).
    cal_date_valid(dt) || return cal_date_invalid()
    return cal_date_new(cal_date_day(dt), cal_date_month(dt), cal_date_year(dt);
                        hour = cal_date_hour(dt), minute = cal_date_minute(dt),
                        second = cal_date_second(dt), millisec = cal_date_millisecond(dt))
end

"""`a != b` for two wxDateTime values (`operator!=`)."""
cal_date_differs(a::wxDateTime, b::wxDateTime) =
    KwxFFI.wxDateTime_IsEqualTo(a.ptr, b.ptr) == 0

# ------------------------------------------------------------------ sizer flags
#
# `wxSizerFlags` fluent chains from the C++, expressed as a flag word plus the
# border in pixels (wxSizerFlags::GetDefaultBorder()).

cal_default_border() =
    Int(round(KwxFFI.wxSizerFlags_GetDefaultBorderFractional()))

"""Flag word for `wxSizerFlags()` plus the named fluent calls."""
function cal_flags(; center::Bool = false, expand::Bool = false, border::Bool = false)
    flags = 0
    center && (flags |= KwxFFI.ALIGN_CENTRE())
    expand && (flags |= KwxFFI.EXPAND())
    border && (flags |= KwxFFI.ALL())
    return flags
end

cal_sizer_add_window!(sizer::Ptr{Cvoid}, win::Ptr{Cvoid}, proportion::Integer,
                      flags::Integer, border::Integer) =
    (KwxFFI.wxSizer_AddWindow(sizer, win, Cint(proportion), Cint(flags),
                              Cint(border), C_NULL); nothing)

cal_sizer_add_sizer!(sizer::Ptr{Cvoid}, child::Ptr{Cvoid}, proportion::Integer,
                     flags::Integer, border::Integer) =
    (KwxFFI.wxSizer_AddSizer(sizer, child, Cint(proportion), Cint(flags),
                             Cint(border), C_NULL); nothing)

# --------------------------------------------------------------- calendar help
#
# All calendar operations use the wxCalendarCtrlBase entry points, the interface
# the C++ sample actually holds (`wxCalendarCtrlBase *m_calendar`), so the same
# calls work for wxCalendarCtrl and wxGenericCalendarCtrl.

"""
    cal_create_calendar(parent, date, style, generic)

`MyPanel::DoCreateCalendar`, including the wxHAS_NATIVE_CALENDARCTRL choice.
"""
function cal_create_calendar(parent::wxWindow, date::wxDateTime, style::Integer,
                             generic::Bool)
    if generic
        # new wxGenericCalendarCtrl(this, Calendar_CalCtrl, dt, wxDefaultPosition,
        #                           wxDefaultSize, style);
        return wxGenericCalendarCtrl(parent, Calendar_CalCtrl, date,
                                     -1, -1, -1, -1, style)
    end
    # new wxCalendarCtrl(this, Calendar_CalCtrl, dt, wxDefaultPosition,
    #                    wxDefaultSize, style);
    return wxCalendarCtrl(parent, Calendar_CalCtrl, date, -1, -1, -1, -1, style)
end

"""`m_calendar->GetDate()` as a caller-owned wxDateTime."""
function cal_get_date(state::AppState)
    dt = wxDateTime()
    KwxFFI.wxCalendarCtrlBase_GetDate(cal_ptr(state), dt.ptr)
    return dt
end

"""`m_calendar->SetDate(dt)`."""
function cal_set_date(state::AppState, dt::wxDateTime)
    KwxFFI.wxCalendarCtrlBase_SetDate(cal_ptr(state), dt.ptr)
    return nothing
end

"""
    cal_toggle_style(state, on, flag)

`MyPanel::ToggleCalStyle`.  `wxCAL_SEQUENTIAL_MONTH_SELECTION` and
`wxCAL_SHOW_WEEK_NUMBERS` cannot be switched in place: the C++ sample recreates
the control for those two.
"""
function cal_toggle_style(state::AppState, on::Bool, flag::Integer)
    style = Int(KwxFFI.wxWindow_GetWindowStyle(cal_ptr(state)))

    if on
        style |= flag
    else
        style &= ~flag
    end

    if flag == KwxFFI.CAL_SEQUENTIAL_MONTH_SELECTION() ||
       flag == KwxFFI.CAL_SHOW_WEEK_NUMBERS()
        # changing this style requires recreating the control
        cal_recreate_calendar(state, style)
    else
        # just changing the style is enough
        KwxFFI.wxWindow_SetWindowStyle(cal_ptr(state), Clong(style))
        KwxFFI.wxWindow_Refresh(cal_ptr(state), Cint(1))
    end

    return nothing
end

"""
    cal_recreate_calendar(state, style)

`MyPanel::RecreateCalendar`: build a replacement control with the same date,
swap it into the sizer, delete the old one and re-establish its handlers.
"""
function cal_recreate_calendar(state::AppState, style::Integer)
    old_calendar = state.calendar

    dt = cal_get_date(state)
    new_calendar = cal_create_calendar(state.panel, dt, style, state.using_generic)
    Base.delete!(dt)

    # m_sizer->Replace(m_calendar, calendar);   (recursive defaults to false)
    KwxFFI.wxSizer_ReplaceWindow(state.sizer, old_calendar.ptr, new_calendar.ptr, Cint(0))
    # delete m_calendar;
    # Destroy() is the safe equivalent of the sample's `delete`: it detaches the
    # window from its parent and defers native teardown.
    KwxFFI.wxWindow_Destroy(old_calendar.ptr)
    state.calendar = new_calendar

    # The C++ event table is class-based and id-matched, so it keeps working
    # across the recreation; Julia connections live on the wrapper object and
    # must be re-established on the new control.
    connect_calendar_events(state)

    KwxFFI.wxSizer_Layout(state.sizer)
    return nothing
end

"""`MyPanel::ToggleUseGeneric`."""
function cal_toggle_use_generic(state::AppState)
    state.using_generic = !state.using_generic
    # RecreateCalendar(m_calendar->GetWindowStyle());
    style = Int(KwxFFI.wxWindow_GetWindowStyle(cal_ptr(state)))
    cal_recreate_calendar(state, style)
    return nothing
end

"""`MyPanel::HighlightSpecial` — custom day attributes, or reset them."""
function cal_highlight_special(state::AppState, on::Bool)
    if on
        # new wxCalendarDateAttr(wxCAL_BORDER_ROUND, *wxRED)
        attr_red = wxCalendarDateAttr(KwxFFI.CAL_BORDER_ROUND(), KwxFFI.RED())
        # new wxCalendarDateAttr(wxCAL_BORDER_SQUARE, *wxGREEN)
        attr_green = wxCalendarDateAttr(KwxFFI.CAL_BORDER_SQUARE(), KwxFFI.GREEN())
        # new wxCalendarDateAttr(*wxBLUE, *wxLIGHT_GREY)
        # (the C++ call relies on the default wxNullColour / wxNullFont /
        #  wxCAL_BORDER_NONE arguments; passing them explicitly is equivalent)
        attr_header = wxCalendarDateAttr(KwxFFI.BLUE(), KwxFFI.LIGHT_GREY(),
                                        KwxFFI.Null_Colour(), KwxFFI.Null_Font(),
                                        KwxFFI.CAL_BORDER_NONE())

        KwxFFI.wxCalendarCtrlBase_SetAttr(cal_ptr(state), Cint(17), attr_red.ptr)
        KwxFFI.wxCalendarCtrlBase_SetAttr(cal_ptr(state), Cint(29), attr_green.ptr)
        KwxFFI.wxCalendarCtrlBase_SetAttr(cal_ptr(state), Cint(13), attr_header.ptr)

        # SetAttr() takes ownership; keep the wrappers reachable so nothing is
        # collected while the native control still points at the data.
        push!(ROOTS, attr_red, attr_green, attr_header)
    else
        KwxFFI.wxCalendarCtrlBase_ResetAttr(cal_ptr(state), Cint(17))
        KwxFFI.wxCalendarCtrlBase_ResetAttr(cal_ptr(state), Cint(29))
        KwxFFI.wxCalendarCtrlBase_ResetAttr(cal_ptr(state), Cint(13))
    end

    KwxFFI.wxWindow_Refresh(cal_ptr(state), Cint(1))
    return nothing
end

"""
    cal_limit_date_range(state, on)

`MyPanel::LimitDateRange`: restrict the selection to three months around today,
or lift the restriction.  Both branches report through the log exactly like the
C++ code, which keys off the `SetDateRange` return value.
"""
function cal_limit_date_range(state::AppState, on::Bool)
    if on
        diff = wxDateSpan(0, 3)                    # wxDateSpan::Months(3)
        today = cal_date_today()

        lo = wxDateTime()                          # today - diff
        hi = wxDateTime()                          # today + diff
        KwxFFI.wxDateTime_SubtractDate(today.ptr, diff.ptr, lo.ptr)
        KwxFFI.wxDateTime_AddDate(today.ptr, diff.ptr, hi.ptr)

        # if (m_calendar->SetDateRange(today - diff, today + diff))
        if KwxFFI.wxCalendarCtrlBase_SetDateRange(cal_ptr(state), lo.ptr, hi.ptr) != 0
            cal_log_status("Date range limited to 3 months around today.")

            first_valid = wxDateTime()
            last_valid = wxDateTime()
            if KwxFFI.wxCalendarCtrlBase_GetDateRange(cal_ptr(state),
                                                      first_valid.ptr,
                                                      last_valid.ptr) != 0
                cal_log_message("First valid date: " * cal_date_iso(first_valid) *
                                ", last valid date: " * cal_date_iso(last_valid))
            else
                cal_log_warning("Failed to get back the valid dates range.")
            end

            Base.delete!(first_valid)
            Base.delete!(last_valid)
        else
            cal_log_warning("Date range not supported.")
        end

        Base.delete!(lo)
        Base.delete!(hi)
        Base.delete!(today)
        Base.delete!(diff)
    else
        # if (m_calendar->SetDateRange()) — both limits default to
        # wxDefaultDateTime, which removes the restriction.  Per the documented
        # contract ("true if either limit is valid") MSW returns false here, so
        # the C++ sample prints the warning; both branches are reproduced.
        if KwxFFI.wxCalendarCtrlBase_SetDateRange(cal_ptr(state), C_NULL, C_NULL) != 0
            cal_log_status("Date choice is unlimited now.")
        else
            cal_log_warning("Date range not supported.")
        end
    end

    KwxFFI.wxWindow_Refresh(cal_ptr(state), Cint(1))
    return nothing
end

# ------------------------------------------------------------------ panel build

"""
    build_panel(parent)

`MyPanel::MyPanel`.  The initial calendar style is `wxCAL_SHOW_HOLIDAYS` and the
sizer orientation follows the screen aspect ratio exactly as the C++ code
computes it.
"""
function build_panel(parent::wxWindow)
    panel = wxPanel(parent, KwxFFI.ID_ANY(), -1, -1, -1, -1, 0)

    # date.Printf("Selected date: %s", wxDateTime::Today().FormatISODate());
    today = cal_date_today()
    date = "Selected date: " * cal_date_iso(today)
    Base.delete!(today)

    date_label = wxStaticText(panel, KwxFFI.ID_ANY(), date, -1, -1, -1, -1, 0)

    # m_calendar = DoCreateCalendar(wxDefaultDateTime, wxCAL_SHOW_HOLIDAYS);
    start = cal_date_invalid()
    calendar = cal_create_calendar(panel, start, KwxFFI.CAL_SHOW_HOLIDAYS(), false)
    Base.delete!(start)

    # bool horizontal = GetMetric(wxSYS_SCREEN_X) > GetMetric(wxSYS_SCREEN_Y);
    screen_x = Int(KwxFFI.wxSystemSettings_GetMetric(Cint(KwxFFI.SYS_SCREEN_X())))
    screen_y = Int(KwxFFI.wxSystemSettings_GetMetric(Cint(KwxFFI.SYS_SCREEN_Y())))
    horizontal = screen_x > screen_y

    sizer = KwxFFI.wxBoxSizer_Create(
        Cint(horizontal ? KwxFFI.HORIZONTAL() : KwxFFI.VERTICAL()))

    # m_sizer->Add(m_date, wxSizerFlags().Center().DoubleBorder());
    cal_sizer_add_window!(sizer, date_label.ptr, 0,
                          cal_flags(center = true, border = true),
                          2 * cal_default_border())
    # m_sizer->Add(m_calendar, wxSizerFlags().Center());
    cal_sizer_add_window!(sizer, calendar.ptr, 0, cal_flags(center = true), 0)

    # SetSizer(m_sizer); m_sizer->SetSizeHints(this);
    KwxFFI.wxWindow_SetSizer(panel.ptr, sizer, Cint(1))
    KwxFFI.wxSizer_SetSizeHints(sizer, panel.ptr)

    return (panel = panel, date_label = date_label, calendar = calendar, sizer = sizer)
end

# -------------------------------------------------------------- menu bar build

"""`MyFrame::MyFrame` menu bar, including the initial `Check()` calls."""
function build_menu_bar()
    empty_title = wxString("")

    file_menu = KwxFFI.wxMenu_Create(empty_title.ptr, Clong(0))
    cal_menu = KwxFFI.wxMenu_Create(empty_title.ptr, Clong(0))
    date_menu = KwxFFI.wxMenu_Create(empty_title.ptr, Clong(0))
    time_menu = KwxFFI.wxMenu_Create(empty_title.ptr, Clong(0))
    Base.delete!(empty_title)

    file_menu == C_NULL && error("Failed to create the File menu")
    cal_menu == C_NULL && error("Failed to create the Calendar menu")
    date_menu == C_NULL && error("Failed to create the Date picker menu")
    time_menu == C_NULL && error("Failed to create the Time picker menu")

    # --- File
    cal_menu_append!(file_menu, Calendar_File_About, "&About\tCtrl-A",
                     "Show about dialog")
    KwxFFI.wxMenu_AppendSeparator(file_menu)
    cal_menu_append!(file_menu, Calendar_File_ClearLog, "&Clear log\tCtrl-L")
    KwxFFI.wxMenu_AppendSeparator(file_menu)
    cal_menu_append!(file_menu, Calendar_File_Quit, "E&xit\tAlt-X", "Quit this program")

    # --- Calendar.  wxHAS_NATIVE_CALENDARCTRL is defined on MSW, so the
    #     "Use generic version" check item belongs to the menu.
    cal_menu_append_checkable!(cal_menu, Calendar_Cal_Generic,
                               "Use &generic version\tCtrl-G",
                               "Toggle between native and generic control")
    KwxFFI.wxMenu_AppendSeparator(cal_menu)

    cal_menu_append_radio!(cal_menu, Calendar_Cal_AutoWeekday,
                           "Automatic &first weekday\tCtrl-V")
    cal_menu_append_radio!(cal_menu, Calendar_Cal_Sunday,
                           "Sunday &first weekday\tCtrl-Z")
    cal_menu_append_radio!(cal_menu, Calendar_Cal_Monday,
                           "Monday &first weekday\tCtrl-F")

    cal_menu_append_checkable!(cal_menu, Calendar_Cal_Holidays, "Show &holidays\tCtrl-H",
                               "Toggle highlighting the holidays")
    cal_menu_append_checkable!(cal_menu, Calendar_Cal_Special,
                               "Highlight &special dates\tCtrl-S",
                               "Test custom highlighting")
    cal_menu_append_checkable!(cal_menu, Calendar_Cal_SurroundWeeks,
                               "Show s&urrounding weeks\tCtrl-W",
                               "Show the neighbouring weeks in the prev/next month")
    cal_menu_append_checkable!(cal_menu, Calendar_Cal_WeekNumbers,
                               "Show &week numbers", "Toggle week numbers")
    KwxFFI.wxMenu_AppendSeparator(cal_menu)

    cal_menu_append_checkable!(cal_menu, Calendar_Cal_SeqMonth,
                               "Toggle month selector st&yle\tCtrl-Y",
                               "Use another style for the calendar controls")
    cal_menu_append_checkable!(cal_menu, Calendar_Cal_Month,
                               "&Month can be changed\tCtrl-M",
                               "Allow changing the month in the calendar")
    cal_menu_append_checkable!(cal_menu, Calendar_Cal_LimitDates,
                               "Toggle date ra&nge\tCtrl-N", "Limit the valid dates")
    KwxFFI.wxMenu_AppendSeparator(cal_menu)

    cal_menu_append!(cal_menu, Calendar_Cal_SetDate, "Call &SetDate(2005-12-24)",
                     "Set date to 2005-12-24.")
    cal_menu_append!(cal_menu, Calendar_Cal_Today, "Call &Today()",
                     "Set to the current date.")
    cal_menu_append!(cal_menu, Calendar_Cal_BeginDST, "Call SetDate(GetBeginDST())")
    KwxFFI.wxMenu_AppendSeparator(cal_menu)

    cal_menu_append_checkable!(cal_menu, Calendar_Cal_Resizable, "Make &resizable\tCtrl-R")

    # --- Date picker
    cal_menu_append_checkable!(date_menu, Calendar_DatePicker_ShowCentury,
                               "Al&ways show century")
    cal_menu_append_checkable!(date_menu, Calendar_DatePicker_DropDown,
                               "Use &drop down control")
    cal_menu_append_checkable!(date_menu, Calendar_DatePicker_AllowNone, "Allow &no date")
    cal_menu_append_checkable!(date_menu, Calendar_DatePicker_StartWithNone,
                               "Start &with no date")
    KwxFFI.wxMenu_AppendSeparator(date_menu)
    cal_menu_append!(date_menu, Calendar_DatePicker_AskDate, "&Choose date...\tCtrl-D",
                     "Show dialog with wxDatePickerCtrl")

    # --- Time picker
    cal_menu_append!(time_menu, Calendar_TimePicker_AskTime, "&Choose time...\tCtrl-T",
                     "Show dialog with wxTimePickerCtrl")

    menu_bar = KwxFFI.wxMenuBar_Create(Cint(0))
    menu_bar == C_NULL && error("Failed to create the menu bar")

    cal_menu_bar_append!(menu_bar, file_menu, "&File")
    cal_menu_bar_append!(menu_bar, cal_menu, "&Calendar")
    cal_menu_bar_append!(menu_bar, date_menu, "&Date picker")
    cal_menu_bar_append!(menu_bar, time_menu, "&Time picker")

    # menuBar->Check(...) — the initial states set explicitly by the C++ ctor.
    KwxFFI.wxMenuBar_Check(menu_bar, Cint(Calendar_Cal_AutoWeekday), Cint(1))
    KwxFFI.wxMenuBar_Check(menu_bar, Cint(Calendar_Cal_Sunday), Cint(0))
    KwxFFI.wxMenuBar_Check(menu_bar, Cint(Calendar_Cal_Monday), Cint(0))
    KwxFFI.wxMenuBar_Check(menu_bar, Cint(Calendar_Cal_Holidays), Cint(1))
    KwxFFI.wxMenuBar_Check(menu_bar, Cint(Calendar_Cal_Month), Cint(1))
    KwxFFI.wxMenuBar_Check(menu_bar, Cint(Calendar_Cal_LimitDates), Cint(0))
    KwxFFI.wxMenuBar_Check(menu_bar, Cint(Calendar_DatePicker_ShowCentury), Cint(1))

    return menu_bar
end

menu_checked(state::AppState, id::Integer) =
    KwxFFI.wxMenuBar_IsChecked(state.menu_bar, Cint(id)) != 0

event_checked(event) = KwxFFI.wxCommandEvent_IsChecked(event.ptr) != 0

# -------------------------------------------------------------- frame handlers
#
# One function per MyFrame::On* method.

frame_on_about(state::AppState, event) = cal_message_box(
    "wxCalendarCtrl sample\n(c) 2000--2008 Vadim Zeitlin", "About Calendar",
    KwxFFI.OK() | KwxFFI.ICON_INFORMATION(), state.frame)

function frame_on_clear_log(state::AppState, event)
    clear!(state.log_window)
    return nothing
end

function frame_on_quit(state::AppState, event)
    close(state.frame, true)                 # Close(true)
    return nothing
end

function frame_on_cal_generic(state::AppState, event)
    cal_toggle_use_generic(state)
    return nothing
end

function frame_on_cal_auto_weekday(state::AppState, event)
    cal_toggle_style(state, false, KwxFFI.CAL_SUNDAY_FIRST())
    cal_toggle_style(state, false, KwxFFI.CAL_MONDAY_FIRST())
    return nothing
end

function frame_on_cal_sunday(state::AppState, event)
    cal_toggle_style(state, false, KwxFFI.CAL_MONDAY_FIRST())
    cal_toggle_style(state, event_checked(event), KwxFFI.CAL_SUNDAY_FIRST())
    return nothing
end

function frame_on_cal_monday(state::AppState, event)
    cal_toggle_style(state, false, KwxFFI.CAL_SUNDAY_FIRST())
    cal_toggle_style(state, event_checked(event), KwxFFI.CAL_MONDAY_FIRST())
    return nothing
end

function frame_on_cal_holidays(state::AppState, event)
    KwxFFI.wxCalendarCtrlBase_EnableHolidayDisplay(cal_ptr(state),
                                                   Cint(event_checked(event)))
    return nothing
end

function frame_on_cal_special(state::AppState, event)
    cal_highlight_special(state, menu_checked(state, KwxFFI.wxEvent_GetId(event.ptr)))
    return nothing
end

function frame_on_cal_limit_dates(state::AppState, event)
    cal_limit_date_range(state, menu_checked(state, KwxFFI.wxEvent_GetId(event.ptr)))
    return nothing
end

function frame_on_cal_allow_month(state::AppState, event)
    KwxFFI.wxCalendarCtrlBase_EnableMonthChange(cal_ptr(state),
                                                Cint(event_checked(event)))
    return nothing
end

function frame_on_cal_seq_month(state::AppState, event)
    cal_toggle_style(state, event_checked(event),
                     KwxFFI.CAL_SEQUENTIAL_MONTH_SELECTION())
    return nothing
end

function frame_on_cal_surrounding_weeks(state::AppState, event)
    cal_toggle_style(state, event_checked(event), KwxFFI.CAL_SHOW_SURROUNDING_WEEKS())
    return nothing
end

function frame_on_cal_week_numbers(state::AppState, event)
    cal_toggle_style(state, event_checked(event), KwxFFI.CAL_SHOW_WEEK_NUMBERS())
    return nothing
end

function frame_on_set_date(state::AppState, event)
    # SetDate(wxDateTime(24, wxDateTime::Dec, 2005, 22, 00, 00));
    dt = cal_date_new(24, KwxFFI.DateTime_Dec(), 2005; hour = 22)
    cal_set_date(state, dt)
    Base.delete!(dt)
    return nothing
end

function frame_on_today(state::AppState, event)
    dt = cal_date_today()
    cal_set_date(state, dt)
    Base.delete!(dt)
    return nothing
end

function frame_on_begin_dst(state::AppState, event)
    current = cal_get_date(state)
    year = cal_date_year(current)
    Base.delete!(current)

    # SetDate(wxDateTime::GetBeginDST(m_panel->GetDate().GetYear()));
    dt = wxDateTime()
    KwxFFI.wxDateTime_GetBeginDST(Cint(year), Cint(KwxFFI.DateTime_Country_Default()),
                                  dt.ptr)
    cal_set_date(state, dt)
    Base.delete!(dt)
    return nothing
end

"""
    frame_on_cal_toggle_resizable(state, event)

`MyFrame::OnCalToggleResizable`: retarget the calendar's sizer item between
`proportion 1 + wxEXPAND` and `proportion 0 + wxALIGN_CENTER`.
"""
function frame_on_cal_toggle_resizable(state::AppState, event)
    sizer = state.sizer

    # wxSizerItem* item = sizer->GetItem(m_panel->GetCal());
    item = KwxFFI.wxSizer_GetItemWindow(sizer, cal_ptr(state), Cint(0))

    # The panel sizer always holds the calendar; a miss would mean the control
    # was replaced and not re-added, in which case there is nothing to retune.
    item == C_NULL && return nothing

    if event_checked(event)
        KwxFFI.wxSizerItem_SetProportion(item, Cint(1))
        KwxFFI.wxSizerItem_SetFlag(item, Cint(KwxFFI.EXPAND()))
    else
        KwxFFI.wxSizerItem_SetProportion(item, Cint(0))
        KwxFFI.wxSizerItem_SetFlag(item, Cint(KwxFFI.ALIGN_CENTER()))
    end

    KwxFFI.wxSizer_Layout(sizer)
    return nothing
end

"""
    frame_on_cal_rclick(state, event)

`MyFrame::OnCalRClick`: describe what the right-clicked calendar point is over,
through `HitTest`.
"""
function frame_on_cal_rclick(state::AppState, event)
    pt_x = Int(KwxFFI.wxMouseEvent_GetX(event.ptr))
    pt_y = Int(KwxFFI.wxMouseEvent_GetY(event.ptr))

    msg = "Point ($pt_x, $pt_y) is "

    dt = wxDateTime()
    weekday = Ref{Cint}(0)
    hit = Int(GC.@preserve weekday KwxFFI.wxCalendarCtrlBase_HitTest(
        cal_ptr(state), Cint(pt_x), Cint(pt_y), dt.ptr,
        Base.unsafe_convert(Ptr{Cint}, weekday)))

    if hit == KwxFFI.CAL_HITTEST_NOWHERE()
        msg *= "nowhere"
    elseif hit == KwxFFI.CAL_HITTEST_HEADER()
        msg *= "over " * cal_weekday_name(Int(weekday[]))
    elseif hit == KwxFFI.CAL_HITTEST_DAY()
        msg *= "over " * cal_date_iso(dt)
    elseif hit == KwxFFI.CAL_HITTEST_INCMONTH()
        msg *= "over next month button"
    elseif hit == KwxFFI.CAL_HITTEST_DECMONTH()
        msg *= "over previous month button"
    elseif hit == KwxFFI.CAL_HITTEST_SURROUNDING_WEEK()
        msg *= "over a day from another month"
    else
        # wxFAIL_MSG("unexpected"); wxFALLTHROUGH -> wxCAL_HITTEST_NOWHERE
        msg *= "nowhere"
    end

    Base.delete!(dt)
    cal_log_message(msg)
    return nothing
end

"""`MyFrame::OnUpdateUIStartWithNone`: only enabled while "no date" is allowed."""
function frame_on_update_ui_start_with_none(state::AppState, event)
    enabled = menu_checked(state, Calendar_DatePicker_AllowNone)
    KwxFFI.wxUpdateUIEvent_Enable(event.ptr, Cint(enabled))
    return nothing
end

"""`MyFrame::OnUpdateUIGenericOnly`: only enabled while the generic control is used."""
function frame_on_update_ui_generic_only(state::AppState, event)
    KwxFFI.wxUpdateUIEvent_Enable(event.ptr, Cint(state.using_generic))
    return nothing
end

# -------------------------------------------------------------- panel handlers
#
# MyPanel's event table.  All five handlers are connected on the calendar with
# the explicit Calendar_CalCtrl id, exactly like EVT_CALENDAR(id, fn).

"""`MyPanel::OnCalendar`: toggle the mark on the double-clicked day."""
function panel_on_calendar(state::AppState, event)
    dt = wxDateTime()
    KwxFFI.wxCalendarEvent_GetDate(event.ptr, dt.ptr)

    # const bool mark = !s_dateLast.IsValid() || event.GetDate() != s_dateLast;
    mark = true
    if state.date_last !== nothing && cal_date_valid(state.date_last)
        mark = cal_date_differs(dt, state.date_last)
    end

    # s_dateLast = event.GetDate();
    state.date_last === nothing || Base.delete!(state.date_last)
    state.date_last = cal_date_copy(dt)

    # m_calendar->Mark(event.GetDate().GetDay(), mark);
    KwxFFI.wxCalendarCtrlBase_Mark(cal_ptr(state), Cint(cal_date_day(dt)), Cint(mark))

    cal_log_message("Selected (and " * (mark ? "" : "un") * "marked) " *
                    cal_date_iso(state.date_last) * " from calendar.")

    Base.delete!(dt)
    return nothing
end

"""`MyPanel::OnCalendarChange`: update the label and the status bar."""
function panel_on_calendar_change(state::AppState, event)
    dt = wxDateTime()
    KwxFFI.wxCalendarEvent_GetDate(event.ptr, dt.ptr)

    s = "Selected date: " * cal_date_iso(dt)
    set_label!(state.date_label, s)
    cal_log_status(s)

    Base.delete!(dt)
    return nothing
end

"""`MyPanel::OnCalMonthChange`: report the new month and year."""
function panel_on_cal_month_change(state::AppState, event)
    dt = wxDateTime()
    KwxFFI.wxCalendarEvent_GetDate(event.ptr, dt.ptr)

    cal_log_status("Calendar month changed to " * cal_month_name(cal_date_month(dt)) *
                   " " * string(cal_date_year(dt)))

    Base.delete!(dt)
    return nothing
end

"""`MyPanel::OnCalendarWeekDayClick`: report the clicked weekday name."""
function panel_on_calendar_weekday_click(state::AppState, event)
    wd = Int(KwxFFI.wxCalendarEvent_GetWeekDay(event.ptr))
    cal_log_message("Clicked on " * cal_weekday_name(wd))
    return nothing
end

"""`MyPanel::OnCalendarWeekClick`: report the clicked week number."""
function panel_on_calendar_week_click(state::AppState, event)
    dt = wxDateTime()
    KwxFFI.wxCalendarEvent_GetDate(event.ptr, dt.ptr)
    cal_log_message("Clicked on week " * string(cal_date_week_of_year(dt)))
    Base.delete!(dt)
    return nothing
end

# --------------------------------------------------------------- date dialog
#
# MyDateDialog.  wxUSE_DATEPICKCTRL_GENERIC is 0 in this build, so only the
# native wxDatePickerCtrl branch exists.

"""
    show_date_dialog(state)

Builds `MyDateDialog`, runs it modally and returns `(result, date)`.  `date` is
caller-owned.
"""
function show_date_dialog(state::AppState)
    # wxDateTime dt = m_panel->GetCal()->GetDate();
    dt = cal_get_date(state)

    style = KwxFFI.DP_DEFAULT()
    if menu_checked(state, Calendar_DatePicker_ShowCentury)
        style |= KwxFFI.DP_SHOWCENTURY()
    end
    if menu_checked(state, Calendar_DatePicker_DropDown)
        style |= KwxFFI.DP_DROPDOWN()
    end
    if menu_checked(state, Calendar_DatePicker_AllowNone)
        style |= KwxFFI.DP_ALLOWNONE()
        if menu_checked(state, Calendar_DatePicker_StartWithNone)
            Base.delete!(dt)
            dt = cal_date_invalid()               # dt = wxDefaultDateTime;
        end
    end

    dlg = wxDialog(state.frame, KwxFFI.ID_ANY(), "Calendar: Choose a date",
                   -1, -1, -1, -1, KwxFFI.DEFAULT_DIALOG_STYLE())

    # new wxDatePickerCtrl(this, wxID_ANY, dt, wxDefaultPosition, wxDefaultSize,
    #                      dtpStyle);
    date_picker = wxDatePickerCtrl(dlg, KwxFFI.ID_ANY(), dt, -1, -1, -1, -1, style)
    # SetRange(wxDateTime(1, wxDateTime::Jan, 1900), wxDefaultDateTime)
    range_start = cal_date_new(1, KwxFFI.DateTime_Jan(), 1900)
    KwxFFI.wxDatePickerCtrl_SetRange(date_picker.ptr, range_start.ptr, C_NULL)
    Base.delete!(range_start)

    # m_dateText = new wxStaticText(this, wxID_ANY,
    #             dt.IsValid() ? dt.FormatISODate() : wxString());
    label = cal_date_valid(dt) ? cal_date_iso(dt) : ""
    date_text = wxStaticText(dlg, KwxFFI.ID_ANY(), label, -1, -1, -1, -1, 0)

    # EVT_DATE_CHANGED(wxID_ANY, MyDateDialog::OnDateChange)
    on_date_change = function (event)
        changed = wxDateTime()
        KwxFFI.wxDateEvent_GetDate(event.ptr, changed.ptr)
        set_label!(date_text, cal_date_valid(changed) ? cal_date_iso(changed) : "")
        Base.delete!(changed)
        return nothing
    end
    wx_connect!(dlg, KwxFFI.EVT_DATE_CHANGED(), on_date_change)

    # const wxSizerFlags flags = wxSizerFlags().Centre().Border();
    cell_flags = cal_flags(center = true, border = true)
    cell_border = cal_default_border()

    enter_label = wxStaticText(dlg, KwxFFI.ID_ANY(), "Enter &date:", -1, -1, -1, -1, 0)
    iso_label = wxStaticText(dlg, KwxFFI.ID_ANY(), "Date in ISO format:", -1, -1, -1, -1, 0)

    # wxFlexGridSizer* const sizerMain = new wxFlexGridSizer(2);
    # `new wxFlexGridSizer(2)` is (cols = 2, gap = 0): rows are deduced, which is
    # exactly the binding's (rows = 0, cols = 2, vgap, hgap) form.
    sizer_main = KwxFFI.wxFlexGridSizer_Create(Cint(0), Cint(2), Cint(0), Cint(0))
    sizer_main == C_NULL && error("Failed to create the date dialog grid sizer")
    cal_sizer_add_window!(sizer_main, enter_label.ptr, 0, cell_flags, cell_border)
    cal_sizer_add_window!(sizer_main, date_picker.ptr, 0, cell_flags, cell_border)
    cal_sizer_add_window!(sizer_main, iso_label.ptr, 0, cell_flags, cell_border)
    cal_sizer_add_window!(sizer_main, date_text.ptr, 0, cell_flags, cell_border)

    sizer_top = KwxFFI.wxBoxSizer_Create(Cint(KwxFFI.VERTICAL()))
    sizer_top == C_NULL && error("Failed to create the date dialog top sizer")
    cal_sizer_add_sizer!(sizer_top, sizer_main, 0, cell_flags, cell_border)
    # sizerTop->Add(CreateStdDialogButtonSizer(wxOK | wxCANCEL), flags);
    buttons = KwxFFI.wxDialog_CreateStdDialogButtonSizer(
        dlg.ptr, Clong(KwxFFI.OK() | KwxFFI.CANCEL()))
    buttons == C_NULL || cal_sizer_add_sizer!(sizer_top, buttons, 0, cell_flags,
                                              cell_border)

    # SetSizerAndFit(sizerTop);
    KwxFFI.wxWindow_SetSizerAndFit(dlg.ptr, sizer_top, Cint(1))

    result = Int(KwxFFI.wxDialog_ShowModal(dlg.ptr))

    value = wxDateTime()
    KwxFFI.wxDatePickerCtrl_GetValue(date_picker.ptr, value.ptr)

    Base.delete!(dt)
    # The C++ dialog is a stack object, so its destructor destroys the window.
    KwxFFI.wxWindow_Destroy(dlg.ptr)
    return (result = result, date = value)
end

# --------------------------------------------------------------- time dialog
#
# MyTimeDialog.  wxUSE_TIMEPICKCTRL_GENERIC is 0 in this build.

"""
    show_time_dialog(state)

Builds `MyTimeDialog`, runs it modally and returns `(result, time)`.  `time` is
caller-owned.
"""
function show_time_dialog(state::AppState)
    dlg = wxDialog(state.frame, KwxFFI.ID_ANY(), "Calendar: Choose time",
                   -1, -1, -1, -1, KwxFFI.DEFAULT_DIALOG_STYLE())

    # m_timePicker = new wxTimePickerCtrl(this, wxID_ANY);
    time_picker = wxTimePickerCtrl(dlg, KwxFFI.ID_ANY(), nothing, -1, -1, -1, -1, 0)

    # m_timeText = new wxStaticText(this, wxID_ANY, GetTime().FormatISOTime());
    initial = wxDateTime()
    KwxFFI.wxTimePickerCtrl_GetValue(time_picker.ptr, initial.ptr)
    time_text = wxStaticText(dlg, KwxFFI.ID_ANY(), cal_date_iso_time(initial),
                             -1, -1, -1, -1, 0)
    Base.delete!(initial)

    # EVT_TIME_CHANGED(wxID_ANY, MyTimeDialog::OnTimeChange)
    on_time_change = function (event)
        changed = wxDateTime()
        KwxFFI.wxDateEvent_GetDate(event.ptr, changed.ptr)
        set_label!(time_text, cal_date_iso_time(changed))
        Base.delete!(changed)
        return nothing
    end
    wx_connect!(dlg, KwxFFI.EVT_TIME_CHANGED(), on_time_change)

    cell_flags = cal_flags(center = true, border = true)
    cell_border = cal_default_border()

    enter_label = wxStaticText(dlg, KwxFFI.ID_ANY(), "Enter &time:", -1, -1, -1, -1, 0)
    iso_label = wxStaticText(dlg, KwxFFI.ID_ANY(), "Time in ISO format:", -1, -1, -1, -1, 0)

    sizer_main = KwxFFI.wxFlexGridSizer_Create(Cint(0), Cint(2), Cint(0), Cint(0))
    sizer_main == C_NULL && error("Failed to create the time dialog grid sizer")
    cal_sizer_add_window!(sizer_main, enter_label.ptr, 0, cell_flags, cell_border)
    cal_sizer_add_window!(sizer_main, time_picker.ptr, 0, cell_flags, cell_border)
    cal_sizer_add_window!(sizer_main, iso_label.ptr, 0, cell_flags, cell_border)
    cal_sizer_add_window!(sizer_main, time_text.ptr, 0, cell_flags, cell_border)

    sizer_top = KwxFFI.wxBoxSizer_Create(Cint(KwxFFI.VERTICAL()))
    sizer_top == C_NULL && error("Failed to create the time dialog top sizer")
    cal_sizer_add_sizer!(sizer_top, sizer_main, 0, cell_flags, cell_border)
    buttons = KwxFFI.wxDialog_CreateStdDialogButtonSizer(
        dlg.ptr, Clong(KwxFFI.OK() | KwxFFI.CANCEL()))
    buttons == C_NULL || cal_sizer_add_sizer!(sizer_top, buttons, 0, cell_flags,
                                              cell_border)

    KwxFFI.wxWindow_SetSizerAndFit(dlg.ptr, sizer_top, Cint(1))

    result = Int(KwxFFI.wxDialog_ShowModal(dlg.ptr))

    value = wxDateTime()
    KwxFFI.wxTimePickerCtrl_GetValue(time_picker.ptr, value.ptr)

    KwxFFI.wxWindow_Destroy(dlg.ptr)
    return (result = result, time = value)
end

"""`MyFrame::OnAskDate`: build the dialog, then apply the chosen date."""
function frame_on_ask_date(state::AppState, event)
    outcome = show_date_dialog(state)

    if outcome.result != KwxFFI.ID_OK()
        Base.delete!(outcome.date)
        return nothing
    end

    dt = outcome.date
    if cal_date_valid(dt)
        today = cal_date_today()

        if cal_date_day(dt) == cal_date_day(today) &&
           cal_date_month(dt) == cal_date_month(today)
            # wxMessageBox("Happy birthday!", "Calendar Sample");
            cal_message_box("Happy birthday!", "Calendar Sample",
                            KwxFFI.OK() | KwxFFI.CENTRE(), nothing)
        end

        cal_set_date(state, dt)
        cal_log_status("Changed the date to your input")

        Base.delete!(today)
    else
        cal_log_status("No date entered")
    end

    Base.delete!(dt)
    return nothing
end

"""`MyFrame::OnAskTime`: build the time dialog and report the chosen time."""
function frame_on_ask_time(state::AppState, event)
    outcome = show_time_dialog(state)

    if outcome.result != KwxFFI.ID_OK()
        Base.delete!(outcome.time)
        return nothing
    end

    cal_log_message("You entered " * cal_date_iso_time(outcome.time))
    Base.delete!(outcome.time)
    return nothing
end

# --------------------------------------------------------------- event wiring
#
# The two wxBEGIN_EVENT_TABLE blocks, translated into wx_connect! calls.  The
# GTK-only EVT_UPDATE_UI entries for AutoWeekday/Sunday/Monday/Holidays are not
# ported: this tree targets MSW.

"""Connect the five MyPanel calendar events plus the calendar's own Bind()."""
function connect_calendar_events(state::AppState)
    calendar = state.calendar

    # EVT_CALENDAR(Calendar_CalCtrl, MyPanel::OnCalendar)
    #   == wxEVT_CALENDAR_DOUBLECLICKED
    wx_connect!(calendar, KwxFFI.EVT_CALENDAR_DOUBLECLICKED(),
                event -> panel_on_calendar(state, event);
                id = Calendar_CalCtrl)
    # EVT_CALENDAR_PAGE_CHANGED
    wx_connect!(calendar, KwxFFI.EVT_CALENDAR_PAGE_CHANGED(),
                event -> panel_on_cal_month_change(state, event);
                id = Calendar_CalCtrl)
    # EVT_CALENDAR_SEL_CHANGED
    wx_connect!(calendar, KwxFFI.EVT_CALENDAR_SEL_CHANGED(),
                event -> panel_on_calendar_change(state, event);
                id = Calendar_CalCtrl)
    # EVT_CALENDAR_WEEKDAY_CLICKED
    wx_connect!(calendar, KwxFFI.EVT_CALENDAR_WEEKDAY_CLICKED(),
                event -> panel_on_calendar_weekday_click(state, event);
                id = Calendar_CalCtrl)
    # EVT_CALENDAR_WEEK_CLICKED
    wx_connect!(calendar, KwxFFI.EVT_CALENDAR_WEEK_CLICKED(),
                event -> panel_on_calendar_week_click(state, event);
                id = Calendar_CalCtrl)

    # calendar->Bind(wxEVT_RIGHT_DOWN, &MyFrame::OnCalRClick,
    #                (MyFrame *)wxGetTopLevelParent(this));
    wx_connect!(calendar, KwxFFI.EVT_RIGHT_DOWN(),
                event -> frame_on_cal_rclick(state, event))

    return nothing
end

"""Connect the MyFrame menu and update-UI handlers."""
function connect_frame_events(state::AppState)
    frame = state.frame

    # --- File
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_about(state, event); id = Calendar_File_About)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_clear_log(state, event); id = Calendar_File_ClearLog)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_quit(state, event); id = Calendar_File_Quit)

    # --- Date picker
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_ask_date(state, event);
                id = Calendar_DatePicker_AskDate)
    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_update_ui_start_with_none(state, event);
                id = Calendar_DatePicker_StartWithNone)

    # --- Time picker
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_ask_time(state, event);
                id = Calendar_TimePicker_AskTime)

    # --- Calendar (wxHAS_NATIVE_CALENDARCTRL on MSW)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_generic(state, event); id = Calendar_Cal_Generic)

    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_auto_weekday(state, event);
                id = Calendar_Cal_AutoWeekday)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_sunday(state, event); id = Calendar_Cal_Sunday)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_monday(state, event); id = Calendar_Cal_Monday)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_holidays(state, event); id = Calendar_Cal_Holidays)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_special(state, event); id = Calendar_Cal_Special)

    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_allow_month(state, event); id = Calendar_Cal_Month)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_limit_dates(state, event);
                id = Calendar_Cal_LimitDates)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_seq_month(state, event); id = Calendar_Cal_SeqMonth)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_surrounding_weeks(state, event);
                id = Calendar_Cal_SurroundWeeks)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_week_numbers(state, event);
                id = Calendar_Cal_WeekNumbers)

    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_set_date(state, event); id = Calendar_Cal_SetDate)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_today(state, event); id = Calendar_Cal_Today)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_begin_dst(state, event); id = Calendar_Cal_BeginDST)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_cal_toggle_resizable(state, event);
                id = Calendar_Cal_Resizable)

    # EVT_UPDATE_UI(Calendar_Cal_SeqMonth / Special / SurroundWeeks,
    #               OnUpdateUIGenericOnly)
    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_update_ui_generic_only(state, event);
                id = Calendar_Cal_SeqMonth)
    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_update_ui_generic_only(state, event);
                id = Calendar_Cal_Special)
    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_update_ui_generic_only(state, event);
                id = Calendar_Cal_SurroundWeeks)

    return nothing
end

# ----------------------------------------------------------------- frame build

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

"""`MyFrame::MyFrame` — frame, icon, menu bar, splitter, panel and log window."""
function build_frame(state::AppState, title::String, dip_size::Tuple{Int, Int})
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), title, -1, -1, -1, -1,
                    KwxFFI.DEFAULT_FRAME_STYLE())
    state.frame = frame
    push!(ROOTS, frame)

    # frame->SetSize(frame->FromDIP(wxSize(460, 340)));
    # `SetSize(const wxSize&)` forwards to DoSetSize(wxDefaultCoord, wxDefaultCoord,
    # w, h, wxSIZE_USE_EXISTING), i.e. keep the position and only apply the size.
    width = KwxFFI.wxWindow_FromDIP(frame.ptr, Cint(dip_size[1]))
    height = KwxFFI.wxWindow_FromDIP(frame.ptr, Cint(dip_size[2]))
    KwxFFI.wxWindow_SetSize(frame.ptr, Cint(-1), Cint(-1), Cint(width), Cint(height),
                            Cint(KwxFFI.SIZE_USE_EXISTING()))

    # SetIcon(wxICON(sample));
    load_frame_icon(frame)

    # wxMenuBar *menuBar = new wxMenuBar; ... SetMenuBar(menuBar);
    menu_bar = build_menu_bar()
    state.menu_bar = menu_bar
    set_menu_bar!(frame, wxMenuBar(menu_bar))

    # new wxSplitterWindow(this, wxID_ANY, wxDefaultPosition, wxDefaultSize,
    #                      wxSP_NOBORDER);
    splitter = wxSplitterWindow(frame, KwxFFI.ID_ANY(), -1, -1, -1, -1,
                                KwxFFI.SP_NOBORDER())

    parts = build_panel(splitter)
    state.panel = parts.panel
    state.date_label = parts.date_label
    state.calendar = parts.calendar
    state.sizer = parts.sizer
    state.using_generic = false            # wxHAS_NATIVE_CALENDARCTRL on MSW

    # m_logWindow = new wxTextCtrl(splitter, wxID_ANY, wxEmptyString,
    #                              wxDefaultPosition, wxDefaultSize,
    #                              wxTE_READONLY | wxTE_MULTILINE);
    log_window = wxTextCtrl(splitter, KwxFFI.ID_ANY(), "", -1, -1, -1, -1,
                            KwxFFI.TE_READONLY() | KwxFFI.TE_MULTILINE())
    state.log_window = log_window
    push!(ROOTS, log_window)

    # splitter->SplitHorizontally(m_panel, m_logWindow);
    KwxFFI.wxSplitterWindow_SplitHorizontally(splitter.ptr, parts.panel.ptr,
                                              log_window.ptr, Cint(0))
    # splitter->SetMinimumPaneSize(20);
    KwxFFI.wxSplitterWindow_SetMinimumPaneSize(splitter.ptr, Cint(20))

    # wxLog::SetActiveTarget(new wxLogTextCtrl(m_logWindow));
    log_target = KwxFFI.wxLogTextCtrl_Create(log_window.ptr)
    if log_target != C_NULL
        KwxFFI.wxLog_SetActiveTarget(log_target)
        push!(ROOTS, log_target)
    end

    return frame
end

# ------------------------------------------------------------------------ main

run_app(app_name = "Calendar") do
    # if ( !wxApp::OnInit() ) return false;
    # #if wxUSE_INTL -> wxUILocale::UseDefault();  (wxUSE_INTL is 1 here)
    KwxFFI.wxUILocale_UseDefault()

    state = AppState()

    # MyFrame* frame = new MyFrame("Calendar wxWidgets sample");
    # frame->SetSize(frame->FromDIP(wxSize(460, 340)));
    frame = build_frame(state, "Calendar wxWidgets sample", (460, 340))

    connect_frame_events(state)
    connect_calendar_events(state)

    # frame->Show(true);
    set_top_window(frame)
    show(frame)
end
