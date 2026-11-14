# animate.jl — kwxJulia port of wxSamples/src/animate/anitest.cpp
#
# The wxWidgets animation sample: an "Animation Demo" frame with a menu bar
# (File / Animation / Help), a status bar and a wxAnimationCtrl playing the
# bundled throbber animations.  A static box below the control lets you inspect
# the individual frames (spin control, frame count, frame delay and the frame
# bitmap).
#
# Run:
#   julia samples\animate\animate.jl
#
# Mapping of the C++ structure onto this port:
#   MyApp::OnInit              -> the run_app block at the bottom of the file
#   MyFrame::MyFrame           -> build_frame() + build_menu_bar()
#   MyFrame::OnPlay/OnStop/... -> frame_on_play() ... frame_on_quit()
#   MyFrame::UpdateFrameControls / UpdateFrameInfo
#                              -> update_frame_controls() / update_frame_info()
#   MyFrame::RecreateAnimation -> recreate_animation()
#   wxBEGIN_EVENT_TABLE        -> connect_events()
#   member fields              -> AniState, captured by every handler closure
#
# The generated wrapper layer is used for every call; `KwxFFI` only supplies
# constants and event types.
#
# Platform note: the C++ code guards the native/generic switch with
# `#ifdef wxHAS_NATIVE_ANIMATIONCTRL`, which wxWidgets defines for wxGTK only
# (wx/animate.h:218-244).  This tree is built for MSW, so the `ID_USE_GENERIC`
# menu item, `MyFrame::OnUseGeneric` and the native-only branch of
# `RecreateAnimation` are not part of the compiled sample and are not ported.

# ------------------------------------------------------------ asset anchoring
#
# `throbber.gif` / `throbber_2x.gif` are loaded from `data/`, and `sample.svg`
# (converted pixel for pixel from the 32x32 `../sample.xpm` array the C++
# sample compiles in) from the sample folder itself.

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

using WxWidgets

const SAMPLE_DIR = let override = get(ENV, "KWXJULIA_SAMPLE_DIR", "")
    isempty(override) ? String(@__DIR__) : abspath(override)
end

# ---------------------------------------------------------------- identifiers
#
# enum { ID_PLAY = 1, ID_SET_NULL_ANIMATION, ID_SET_INACTIVE_BITMAP,
#        ID_SET_NO_AUTO_RESIZE, ID_SET_BGCOLOR, ID_USE_GENERIC };
#
# ID_USE_GENERIC (6) is only referenced from the wxHAS_NATIVE_ANIMATIONCTRL
# branches and is therefore absent from the MSW build.

const ID_PLAY                = 1
const ID_SET_NULL_ANIMATION  = 2
const ID_SET_INACTIVE_BITMAP = 3
const ID_SET_NO_AUTO_RESIZE  = 4
const ID_SET_BGCOLOR         = 5

# --------------------------------------------------------------- shared state
#
# The member fields of MyFrame that the handlers read or mutate.

mutable struct AniState
    frame::Union{wxFrame, Nothing}
    menu_bar::Union{wxMenuBar, Nothing}
    sizer::Union{wxBoxSizer, Nothing}
    ctrl::Union{wxAnimationCtrl, Nothing}
    frame_box::Union{wxStaticBox, Nothing}
    frame_spin::Union{wxSpinCtrl, Nothing}
    frame_count::Union{wxStaticText, Nothing}
    frame_delay::Union{wxStaticText, Nothing}
    frame_bitmap::Union{wxStaticBitmap, Nothing}
end

AniState() = AniState(nothing, nothing, nothing, nothing, nothing,
                      nothing, nothing, nothing, nothing)

# -------------------------------------------------------------------- helpers

"`wxSizerFlags::GetDefaultBorder()` — the border `.Border()` uses."
ani_default_border() = wxSizer_GetDefaultBorder()

"`wxNullBitmap` as a non-owning handle: no finalizer is attached."
ani_null_bitmap() = wxBitmap(KwxFFI.Null_Bitmap())

"`wxBitmap()` — the default-constructed bitmap behind an empty `wxBitmapBundle()`."
ani_empty_bitmap() = wxBitmap()

# ------------------------------------------------------------------ animation

"""
    ani_load_animation(path)

`wxAnimation anim(path)` — `LoadFile()` with `wxANIMATION_TYPE_ANY`.  Returns
`nothing` when the file is missing or not a recognised animation.

The C++ constructor yields an invalid `wxAnimation` on failure, so the file is
loaded into a default-constructed animation instead of using the
`wxAnimation(path, type)` factory, which raises on a failed load.
"""
function ani_load_animation(path::String)
    anim = wxAnimation()
    ok = try
        load_file(anim, path, KwxFFI.ANIMATION_TYPE_ANY())
    catch
        Base.delete!(anim)
        rethrow()
    end

    if !ok || !is_ok(anim)
        Base.delete!(anim)
        return nothing
    end
    return anim
end

# --------------------------------------------------- frame icon (sample.xpm)

"""
    load_frame_icon(frame)

`SetIcon(wxICON(sample))`.  The XPM is converted to `sample.svg` and loaded at
its original 32x32 size, then copied into a wxIcon for the frame.
"""
function load_frame_icon(frame::wxFrame)
    bundle = wxBitmapBundle_FromSVGFile(joinpath(SAMPLE_DIR, "sample.svg"), 32, 32)
    bundle.ptr == C_NULL && return nothing

    try
        if is_ok(bundle)
            bitmap = get_bitmap(bundle, 32, 32)
            try
                if bitmap.ptr != C_NULL
                    icon = wxIcon()
                    try
                        copy_from_bitmap!(icon, bitmap)
                        set_icon!(frame, icon)   # SetIcon() copies the icon
                    finally
                        Base.delete!(icon)
                    end
                end
            finally
                Base.delete!(bitmap)
            end
        end
    finally
        Base.delete!(bundle)
    end
    return nothing
end

# --------------------------------------------------------------- menu bar build

"""`MyFrame::MyFrame` menu bar (wxHAS_NATIVE_ANIMATIONCTRL branch excluded)."""
function build_menu_bar()
    file_menu = wxMenu("", 0)
    play_menu = wxMenu("", 0)
    help_menu = wxMenu("", 0)

    # --- File
    Base.append!(file_menu, KwxFFI.ID_OPEN(), "&Open Animation...\tCtrl+O",
                 "Loads an animation", false)
    Base.append!(file_menu, KwxFFI.ID_EXIT(), "", "", false)

    # --- Animation
    Base.append!(play_menu, ID_PLAY, "Play\tCtrl+P", "Play the animation", false)
    Base.append!(play_menu, KwxFFI.ID_STOP(), "Stop\tCtrl+S",
                 "Stop the animation", false)
    append_separator!(play_menu)
    Base.append!(play_menu, ID_SET_NULL_ANIMATION, "Set null animation",
                 "Sets the empty animation in the control", false)
    append_check_item!(play_menu, ID_SET_INACTIVE_BITMAP, "Set inactive bitmap",
                       "Sets an inactive bitmap for the control")
    append_check_item!(play_menu, ID_SET_NO_AUTO_RESIZE, "Set no autoresize",
                       "Tells the control not to resize automatically")
    Base.append!(play_menu, ID_SET_BGCOLOR, "Set background colour...",
                 "Sets the background colour of the control", false)

    # --- Help
    Base.append!(help_menu, KwxFFI.ID_ABOUT(), "", "", false)

    menu_bar = wxMenuBar(0)
    WxWidgets.append(menu_bar, file_menu, "&File")
    WxWidgets.append(menu_bar, play_menu, "&Animation")
    WxWidgets.append(menu_bar, help_menu, "&Help")

    return menu_bar
end

# -------------------------------------------------------------- frame handlers
#
# One function per MyFrame::On* method.

function frame_on_play(state::AniState, event)
    play(state.ctrl) || LogError("Invalid animation")
    return nothing
end

function frame_on_stop(state::AniState, event)
    stop!(state.ctrl)
    return nothing
end

function frame_on_set_null_animation(state::AniState, event)
    # m_animationCtrl->SetAnimation(wxNullAnimation);
    anim = wxAnimation()
    try
        set_animation!(state.ctrl, anim)
    finally
        Base.delete!(anim)
    end

    update_frame_controls(state)
    return nothing
end

function frame_on_set_inactive_bitmap(state::AniState, event)
    if is_checked(wxCommandEvent(event.ptr))
        # wxBitmap bmp = wxArtProvider::GetBitmap(wxART_MISSING_IMAGE);
        #
        # wxART_MISSING_IMAGE is the art id "wxART_MISSING_IMAGE"; the default
        # client is wxART_OTHER, whose macro expands to the client id
        # "wxART_OTHER_C" (wx/artprov.h:32-51).  It must end in 'C' —
        # wxArtProvider::GetBitmap asserts exactly that (artprov.cpp:427).
        bmp = wxArtProvider_GetBitmap("wxART_MISSING_IMAGE", "wxART_OTHER_C", -1, -1)
        try
            if bmp.ptr == C_NULL
                set_inactive_bitmap!(state.ctrl, ani_null_bitmap())
            else
                set_inactive_bitmap!(state.ctrl, bmp)
            end
        finally
            bmp.ptr == C_NULL || Base.delete!(bmp)
        end
    else
        set_inactive_bitmap!(state.ctrl, ani_null_bitmap())
    end
    return nothing
end

function frame_on_set_no_auto_resize(state::AniState, event)
    # long style = wxAC_DEFAULT_STYLE | (event.IsChecked() ? wxAC_NO_AUTORESIZE : 0);
    style = KwxFFI.AC_DEFAULT_STYLE()
    if is_checked(wxCommandEvent(event.ptr))
        style |= KwxFFI.AC_NO_AUTORESIZE()
    end

    if style != get_window_style(state.ctrl)
        recreate_animation(state, style)
    end
    return nothing
end

function frame_on_set_bg_color(state::AniState, event)
    # wxColour clr = wxGetColourFromUser(this, m_animationCtrl->GetBackgroundColour(),
    #                                    "Choose the background colour");
    initial = wxColour()
    chosen = wxColour()
    try
        get_background_colour!(state.ctrl, initial)
        wxGetColourFromUserEx(state.frame, initial, "Choose the background colour",
                              chosen)

        if is_ok(chosen)
            set_background_colour(state.ctrl, chosen)
        end
    finally
        Base.delete!(chosen)
        Base.delete!(initial)
    end
    return nothing
end

"""
    recreate_animation(state, style)

`MyFrame::RecreateAnimation`.  The MSW build (no `wxHAS_NATIVE_ANIMATIONCTRL`)
starts the replacement without carrying the current animation over.
"""
function recreate_animation(state::AniState, style::Integer)
    old = state.ctrl

    inactive = wxBitmap()
    bg = wxColour()
    try
        get_inactive_bitmap!(old, inactive)
        get_background_colour!(old, bg)

        # m_animationCtrl = new wxAnimationCtrl(this, wxID_ANY, curr,
        #                                       wxDefaultPosition, wxDefaultSize, style);
        new_ctrl = wxAnimationCtrl(state.frame, KwxFFI.ID_ANY(),
                                   -1, -1, -1, -1, style)
        state.ctrl = new_ctrl

        # GetSizer()->Replace(old, m_animationCtrl);
        replace_window(state.sizer, old, new_ctrl, false)
        # delete old;
        destroy(old)
        # The native object is gone: drop every Julia reference to its wrapper.
        filter!(x -> x !== old, state.frame.children)

        # load old status in new control
        set_inactive_bitmap!(new_ctrl, inactive)
        set_background_colour(new_ctrl, bg)

        # GetSizer()->Layout();
        layout!(state.sizer)

        update_frame_controls(state)
    finally
        Base.delete!(bg)
        Base.delete!(inactive)
    end
    return nothing
end

"""`MyFrame::UpdateFrameControls`."""
function update_frame_controls(state::AniState)
    anim = wxAnimation()
    try
        # const wxAnimation animation = m_animationCtrl->GetAnimation();
        get_animation!(state.ctrl, anim)
        count = is_ok(anim) ? get_frame_count(anim) : 0

        # m_frameBox->Enable(count != 0);
        if count != 0
            enable(state.frame_box, true)
        else
            disable(state.frame_box)
        end

        if count != 0
            set_range!(state.frame_spin, 0, count - 1)
            set_label!(state.frame_count, "(of $(count))")
        else
            set_range!(state.frame_spin, 0, 0)
            set_label!(state.frame_count, "(no frames)")
        end

        set_value!(state.frame_spin, 0)
    finally
        Base.delete!(anim)
    end

    update_frame_info(state)
    return nothing
end

"""`MyFrame::UpdateFrameInfo`."""
function update_frame_info(state::AniState)
    anim = wxAnimation()
    try
        get_animation!(state.ctrl, anim)

        if is_ok(anim) && get_frame_count(anim) != 0
            frame = get_value(state.frame_spin)

            delay = get_delay(anim, frame)
            set_label!(state.frame_delay,
                       delay == -1 ? "Delay: forever" : "Delay: $(delay) ms")

            image = wxImage()
            try
                get_frame!(anim, frame, image)
                if is_ok(image)
                    bitmap = wxBitmap(image, -1)      # wxBitmap(image)
                    try
                        set_bitmap!(state.frame_bitmap, bitmap)
                    finally
                        Base.delete!(bitmap)
                    end
                else
                    LogError("Failed to get animation frame $(frame).")
                    # m_frameBitmap->SetBitmap(wxBitmapBundle());
                    empty = ani_empty_bitmap()
                    try
                        set_bitmap!(state.frame_bitmap, empty)
                    finally
                        Base.delete!(empty)
                    end
                end
            finally
                Base.delete!(image)
            end
        else
            set_label!(state.frame_delay, "Delay: N/A")
            empty = ani_empty_bitmap()
            try
                set_bitmap!(state.frame_bitmap, empty)
            finally
                Base.delete!(empty)
            end
        end
    finally
        Base.delete!(anim)
    end

    layout(state.frame)
    return nothing
end

function frame_on_frame_spin(state::AniState, event)
    update_frame_info(state)
    return nothing
end

function frame_on_quit(state::AniState, event)
    close(state.frame, false)        # Close()
    return nothing
end

function frame_on_about(state::AniState, event)
    info = wxAboutDialogInfo()
    try
        set_name!(info, "wxAnimationCtrl and wxAnimation sample")
        set_description!(info,
                         "This sample program demonstrates the usage of wxAnimationCtrl")
        set_copyright!(info, "(C) 2006 Julian Smart")

        add_developer!(info, "Julian Smart")
        add_developer!(info, "Guillermo Rodriguez Garcia")
        add_developer!(info, "Francesco Montorsi")

        wxAboutBox(info, state.frame)
    finally
        Base.delete!(info)
    end
    return nothing
end

"""`MyFrame::OnOpen` — load an animation from a file chosen by the user."""
function frame_on_open(state::AniState, event)
    # wxFileDialog dialog(this, "Please choose an animation", wxEmptyString,
    #                     wxEmptyString, "*.gif;*.ani;*.webp", wxFD_OPEN);
    dialog = wxFileDialog(state.frame, "Please choose an animation", "", "",
                          "*.gif;*.ani;*.webp", -1, -1,
                          KwxFFI.FD_OPEN(), -1, -1)
    try
        if show_modal(dialog) != KwxFFI.ID_OK()
            return nothing
        end

        filename = get_path(dialog)

        # wxAnimation temp(m_animationCtrl->CreateAnimation());
        temp = wxAnimation()
        try
            create_animation!(state.ctrl, temp)

            if !load_file(temp, filename, KwxFFI.ANIMATION_TYPE_ANY())
                LogError("Sorry, this animation is not a valid format for wxAnimation.")
                return nothing
            end

            set_animation!(state.ctrl, temp)
            play(state.ctrl)

            layout!(state.sizer)

            update_frame_controls(state)
        finally
            Base.delete!(temp)
        end
    finally
        destroy(dialog)
    end
    return nothing
end

"""`MyFrame::OnUpdateUI` — play/stop/no-autoresize availability."""
function frame_on_update_ui(state::AniState, event)
    playing = is_playing(state.ctrl)

    # GetMenuBar()->FindItem(id)->Enable(...) — expressed through
    # wxMenuBarBase::Enable(id, enable), which does the FindItem() lookup
    # internally and does not allocate a throw-away wxMenu per call.
    for (id, enabled) in ((KwxFFI.ID_STOP(), playing),
                          (ID_PLAY, !playing),
                          (ID_SET_NO_AUTO_RESIZE, !playing))
        enable_item!(state.menu_bar, id, enabled)
    end
    return nothing
end

# ------------------------------------------------------------------- frame build

"""`MyFrame::MyFrame` — frame, icon, menu bar, status bar, sizers and controls."""
function build_frame(state::AniState)
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "Animation Demo",
                    -1, -1, -1, -1, KwxFFI.DEFAULT_FRAME_STYLE())
    state.frame = frame

    # SetIcon(wxICON(sample));
    load_frame_icon(frame)

    # SetMenuBar(menu_bar);
    state.menu_bar = build_menu_bar()
    set_menu_bar!(frame, state.menu_bar)

    # CreateStatusBar();  — defaults: number = 1, style = wxSTB_DEFAULT_STYLE,
    # winid = 0 (wx/frame.h:113-116).
    create_status_bar(frame, 1, KwxFFI.STB_DEFAULT_STYLE(), 0)

    # use a wxBoxSizer otherwise wxFrame will automatically resize the
    # m_animationCtrl to fill its client area on user resizes
    sz = wxBoxSizer(KwxFFI.VERTICAL())
    state.sizer = sz

    border = ani_default_border()
    centre = KwxFFI.ALIGN_CENTRE()
    centre_vertical = KwxFFI.ALIGN_CENTRE_VERTICAL()
    all = KwxFFI.ALL()

    label = wxStaticText(frame, KwxFFI.ID_ANY(), "wxAnimationCtrl:",
                         -1, -1, -1, -1, 0)
    add_window!(sz, label, 0, centre | all, border, C_NULL)

    # m_animationCtrl = new wxAnimationCtrl(this, wxID_ANY);
    ctrl = wxAnimationCtrl(frame, KwxFFI.ID_ANY(), -1, -1, -1, -1,
                           KwxFFI.AC_DEFAULT_STYLE())
    state.ctrl = ctrl

    # wxAnimationBundle animations;
    animations = wxAnimationBundle()
    try
        for name in ("throbber.gif", "throbber_2x.gif")
            anim = ani_load_animation(joinpath(SAMPLE_DIR, "data", name))
            if anim !== nothing
                # if (anim.IsOk()) animations.Add(anim);
                add!(animations, anim)
                Base.delete!(anim)
            end
        end

        if is_ok(animations)
            set_animation_bundle!(ctrl, animations)
            play(ctrl)
        end
    finally
        Base.delete!(animations)
    end

    # sz->Add(m_animationCtrl, wxSizerFlags().Centre().Border());
    add_window!(sz, ctrl, 0, centre | all, border, C_NULL)

    # --- animation frame inspector
    # wxStaticBoxSizer(wxVERTICAL, this, "Animation frames")
    frame_box = wxStaticBox(frame, KwxFFI.ID_ANY(), "Animation frames",
                            -1, -1, -1, -1, 0)
    state.frame_box = frame_box

    frame_sizer = wxStaticBoxSizer(frame_box, KwxFFI.VERTICAL())

    spin_sizer = wxBoxSizer(KwxFFI.HORIZONTAL())

    spin_label = wxStaticText(frame_box, KwxFFI.ID_ANY(), "&Frame:",
                              -1, -1, -1, -1, 0)
    add_window!(spin_sizer, spin_label, 0,
                centre_vertical | KwxFFI.RIGHT(), border, C_NULL)

    # m_frameSpin = new wxSpinCtrl(m_frameBox, wxID_ANY);
    spin = wxSpinCtrl(frame_box, KwxFFI.ID_ANY(), "", -1, -1, -1, -1,
                      KwxFFI.SP_ARROW_KEYS(), 0, 100, 0)
    state.frame_spin = spin
    add_window!(spin_sizer, spin, 0, centre_vertical, 0, C_NULL)

    frame_count = wxStaticText(frame_box, KwxFFI.ID_ANY(), "", -1, -1, -1, -1, 0)
    state.frame_count = frame_count
    add_window!(spin_sizer, frame_count, 0,
                centre_vertical | KwxFFI.LEFT(), border, C_NULL)

    add_sizer!(frame_sizer, spin_sizer, 0, centre | all, border, C_NULL)

    frame_delay = wxStaticText(frame_box, KwxFFI.ID_ANY(), "", -1, -1, -1, -1, 0)
    state.frame_delay = frame_delay
    add_window!(frame_sizer, frame_delay, 0, centre | all, border, C_NULL)

    # m_frameBitmap = new wxStaticBitmap(m_frameBox, wxID_ANY, wxBitmapBundle());
    empty = ani_empty_bitmap()
    try
        frame_bitmap = wxStaticBitmap(frame_box, KwxFFI.ID_ANY(), empty,
                                      -1, -1, -1, -1, 0)
        state.frame_bitmap = frame_bitmap
    finally
        Base.delete!(empty)
    end
    add_window!(frame_sizer, state.frame_bitmap, 0, centre | all, border, C_NULL)

    add_sizer!(sz, frame_sizer, 0, KwxFFI.EXPAND() | all, border, C_NULL)

    # SetSizer(sz);
    set_sizer!(frame, sz, true)

    update_frame_controls(state)

    # SetSize(FromDIP(wxSize(500, 400)));
    width = from_dip(frame, 500)
    height = from_dip(frame, 400)
    set_size!(frame, -1, -1, width, height, KwxFFI.SIZE_USE_EXISTING())

    return frame
end

# ---------------------------------------------------------------- event wiring

"""Connect the MyFrame event-table entries and the spin control's Bind()."""
function connect_events(state::AniState)
    frame = state.frame

    # --- EVT_MENU(...)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_play(state, event); id = ID_PLAY)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_set_null_animation(state, event);
                id = ID_SET_NULL_ANIMATION)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_set_inactive_bitmap(state, event);
                id = ID_SET_INACTIVE_BITMAP)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_set_no_auto_resize(state, event);
                id = ID_SET_NO_AUTO_RESIZE)
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_set_bg_color(state, event); id = ID_SET_BGCOLOR)

    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_stop(state, event); id = KwxFFI.ID_STOP())
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_about(state, event); id = KwxFFI.ID_ABOUT())
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_quit(state, event); id = KwxFFI.ID_EXIT())
    wx_connect!(frame, KwxFFI.EVT_MENU(),
                event -> frame_on_open(state, event); id = KwxFFI.ID_OPEN())

    # EVT_SIZE(MyFrame::OnSize) — in the C++ sample MyFrame declares no OnSize,
    # so the entry binds the inherited wxTopLevelWindowBase::OnSize, which is
    # `Layout()`.
    wx_connect!(frame, KwxFFI.EVT_SIZE(),
                event -> (layout(state.frame); nothing))

    # EVT_UPDATE_UI(wxID_ANY, MyFrame::OnUpdateUI)
    wx_connect!(frame, KwxFFI.EVT_UPDATE_UI(),
                event -> frame_on_update_ui(state, event))

    # m_frameSpin->Bind(wxEVT_SPINCTRL, &MyFrame::OnFrameSpin, this);
    wx_connect!(state.frame_spin, KwxFFI.EVT_SPINCTRL(),
                event -> frame_on_frame_spin(state, event))

    return nothing
end

# ------------------------------------------------------------------------ main

run_app(app_name = "Animation Demo") do
    state = AniState()

    # MyFrame* frame = new MyFrame(nullptr, wxID_ANY, "Animation Demo");
    frame = build_frame(state)

    connect_events(state)

    # frame->Show(true);
    set_top_window(frame)
    show(frame)
end
