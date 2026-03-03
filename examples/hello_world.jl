# Hello World Julia wxWidgets Example
# Demonstrates frame, button, and event handling

# Add parent directory to load path to find WxWidgets module
push!(LOAD_PATH, joinpath(@__DIR__, ".."))

using WxWidgets

# Run the application
run_app(app_name="Hello World") do
    # Create main frame
    frame = wxFrame(nothing, "Hello World - kwxJulia", size=(400, 300))

    # Create status bar
    create_status_bar(frame)
    set_status_text(frame, "Click the button!")

    # Create button
    button = wxButton(frame, "Say Hello", size=(120, 40))

    # Connect button click event
    click_count = Ref(0)
    on_click!(button) do event
        click_count[] += 1
        msg = if click_count[] == 1
            "Hello from Julia! (clicked 1 time)"
        else
            "Hello from Julia! (clicked $(click_count[]) times)"
        end
        set_status_text(frame, msg)
        println(msg)
    end

    # Create a sizer for layout
    sizer = wxBoxSizer(:vertical)
    add!(sizer, button,
         proportion=0,
         flags=KwxFFI.ALL() | KwxFFI.ALIGN_CENTER(),
         border=5)

    set_sizer(frame, sizer)

    # Set as top window and show
    set_top_window(frame)
    show_window(frame)
end
