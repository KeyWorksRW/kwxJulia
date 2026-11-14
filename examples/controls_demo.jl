# Controls Demo - Julia wxWidgets Example
# Demonstrates multiple controls with sizer layout using the generated wx/ API.

push!(LOAD_PATH, joinpath(@__DIR__, ".."))

using WxWidgets

run_app(app_name="Controls Demo") do
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "Controls Demo - kwxJulia",
                    -1, -1, 500, 400, KwxFFI.DEFAULT_FRAME_STYLE())

    create_status_bar(frame, 1, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Ready", 0)

    label1 = wxStaticText(frame, KwxFFI.ID_ANY(), "Enter your name:",
                          -1, -1, -1, -1, 0)
    text_input = wxTextCtrl(frame, KwxFFI.ID_ANY(), "", -1, -1, 200, -1, 0)

    label2 = wxStaticText(frame, KwxFFI.ID_ANY(), "Comments:", -1, -1, -1, -1, 0)
    text_multiline = wxTextCtrl(frame, KwxFFI.ID_ANY(), "", -1, -1, 200, 100,
                                KwxFFI.TE_MULTILINE())

    checkbox = wxCheckBox(frame, KwxFFI.ID_ANY(), "Enable notifications",
                          -1, -1, -1, -1, 0)

    button_submit = wxButton(frame, KwxFFI.ID_ANY(), "Submit", -1, -1, -1, -1, 0)
    button_clear = wxButton(frame, KwxFFI.ID_ANY(), "Clear", -1, -1, -1, -1, 0)

    wx_connect!(button_submit, KwxFFI.EVT_BUTTON()) do event
        name = get_value(text_input)
        comments = get_value(text_multiline)
        notifications = get_value(checkbox)

        if isempty(name)
            set_status_text!(frame, "Please enter your name", 0)
        else
            msg = "Name: $name | Notifications: $(notifications ? "ON" : "OFF")"
            set_status_text!(frame, msg, 0)
            println("=== Submit ===")
            println("Name: $name")
            println("Comments: $comments")
            println("Notifications: $(notifications ? "enabled" : "disabled")")
        end
    end

    wx_connect!(button_clear, KwxFFI.EVT_BUTTON()) do event
        set_value!(text_input, "")
        set_value!(text_multiline, "")
        set_value!(checkbox, false)
        set_status_text!(frame, "Cleared", 0)
    end

    wx_connect!(checkbox, KwxFFI.EVT_CHECKBOX()) do event
        status = get_value(checkbox) ? "enabled" : "disabled"
        set_status_text!(frame, "Notifications $status", 0)
    end

    wx_connect!(text_input, KwxFFI.EVT_TEXT()) do event
        name = get_value(text_input)
        if !isempty(name)
            set_status_text!(frame, "Hello, $name!", 0)
        else
            set_status_text!(frame, "Ready", 0)
        end
    end

    main_sizer = wxBoxSizer(KwxFFI.VERTICAL())

    add_window!(main_sizer, label1, 0, KwxFFI.ALL(), 10, C_NULL)
    add_window!(main_sizer, text_input, 0, KwxFFI.ALL() | KwxFFI.EXPAND(), 10, C_NULL)

    add_window!(main_sizer, label2, 0, KwxFFI.ALL(), 10, C_NULL)
    add_window!(main_sizer, text_multiline, 1, KwxFFI.ALL() | KwxFFI.EXPAND(), 10, C_NULL)

    add_window!(main_sizer, checkbox, 0, KwxFFI.ALL(), 10, C_NULL)

    button_sizer = wxBoxSizer(KwxFFI.HORIZONTAL())
    add_window!(button_sizer, button_submit, 0, KwxFFI.ALL(), 5, C_NULL)
    add_window!(button_sizer, button_clear, 0, KwxFFI.ALL(), 5, C_NULL)

    add_sizer!(main_sizer, button_sizer, 0, KwxFFI.ALL() | KwxFFI.ALIGN_CENTER(), 10, C_NULL)

    set_sizer!(frame, main_sizer, true)

    set_top_window(frame)
    show(frame)
end
