# Hello World Julia wxWidgets Example
# Demonstrates frame, button, and event handling with the generated wx/ API.

push!(LOAD_PATH, joinpath(@__DIR__, ".."))

using WxWidgets

run_app(app_name="Hello World") do
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "Hello World - kwxJulia",
                    -1, -1, 400, 300, KwxFFI.DEFAULT_FRAME_STYLE())

    create_status_bar(frame, 1, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Click the button!", 0)

    button = wxButton(frame, KwxFFI.ID_ANY(), "Say Hello", -1, -1, 120, 40, 0)

    click_count = Ref(0)
    wx_connect!(button, KwxFFI.EVT_BUTTON()) do event
        click_count[] += 1
        msg = if click_count[] == 1
            "Hello from Julia! (clicked 1 time)"
        else
            "Hello from Julia! (clicked $(click_count[]) times)"
        end
        set_status_text!(frame, msg, 0)
        println(msg)
    end

    sizer = wxBoxSizer(KwxFFI.VERTICAL())
    add_window!(sizer, button, 0, KwxFFI.ALL() | KwxFFI.ALIGN_CENTER(), 5, C_NULL)

    set_sizer!(frame, sizer, true)

    set_top_window(frame)
    show(frame)
end
