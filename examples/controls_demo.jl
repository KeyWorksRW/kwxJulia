# Controls Demo - Julia wxWidgets Example
# Demonstrates multiple controls with sizer layout

# Add parent directory to load path to find WxWidgets module
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

using WxWidgets

# Run the application
run_app(app_name="Controls Demo") do
        # Create main frame
        frame = WxFrame(nothing, "Controls Demo - kwxJulia", size=(500, 400))

        # Create status bar
        create_status_bar(frame)
        set_status_text(frame, "Ready")

        # Create controls
        label1 = WxStaticText(frame, "Enter your name:")
        text_input = WxTextCtrl(frame, value="", size=(200, -1))

        label2 = WxStaticText(frame, "Comments:")
        text_multiline = WxTextCtrl(frame,
                                     value="",
                                     size=(200, 100),
                                     style=wxTE_MULTILINE[])

        checkbox = WxCheckBox(frame, "Enable notifications")

        button_submit = WxButton(frame, "Submit")
        button_clear = WxButton(frame, "Clear")

        # Event handlers
        on_click!(button_submit) do event
            name = get_value(text_input)
            comments = get_value(text_multiline)
            notifications = is_checked(checkbox)

            if isempty(name)
                set_status_text(frame, "Please enter your name")
            else
                msg = "Name: $name | Notifications: $(notifications ? "ON" : "OFF")"
                set_status_text(frame, msg)
                println("=== Submit ===")
                println("Name: $name")
                println("Comments: $comments")
                println("Notifications: $(notifications ? "enabled" : "disabled")")
            end
        end

        on_click!(button_clear) do event
            set_value!(text_input, "")
            set_value!(text_multiline, "")
            set_checked!(checkbox, false)
            set_status_text(frame, "Cleared")
        end

        on_checkbox!(checkbox) do event
            status = is_checked(checkbox) ? "enabled" : "disabled"
            set_status_text(frame, "Notifications $status")
        end

        on_text_changed!(text_input) do event
            name = get_value(text_input)
            if !isempty(name)
                set_status_text(frame, "Hello, $name!")
            else
                set_status_text(frame, "Ready")
            end
        end

        # Create layout with sizers
        # Main vertical sizer
        main_sizer = WxBoxSizer(:vertical)

        # Name field
        add!(main_sizer, label1,
             proportion=0,
             flags=wxALL[],
             border=10)
        add!(main_sizer, text_input,
             proportion=0,
             flags=wxALL[] | wxEXPAND[],
             border=10)

        # Comments field
        add!(main_sizer, label2,
             proportion=0,
             flags=wxALL[],
             border=10)
        add!(main_sizer, text_multiline,
             proportion=1,
             flags=wxALL[] | wxEXPAND[],
             border=10)

        # Checkbox
        add!(main_sizer, checkbox,
             proportion=0,
             flags=wxALL[],
             border=10)

        # Buttons in horizontal sizer
        button_sizer = WxBoxSizer(:horizontal)
        add!(button_sizer, button_submit,
             proportion=0,
             flags=wxALL[],
             border=5)
        add!(button_sizer, button_clear,
             proportion=0,
             flags=wxALL[],
             border=5)

        add!(main_sizer, button_sizer,
             proportion=0,
             flags=wxALL[] | wxALIGN_CENTER[],
             border=10)

        # Set the sizer and layout
        set_sizer(frame, main_sizer)

        # Set as top window and show
        set_top_window(frame)
        show_window(frame)
    end
