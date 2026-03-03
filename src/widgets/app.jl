# High-level wxApp wrapper

"""
    run_app(setup::Function; app_name::String="wxApp")

Initialize wxWidgets, run the setup function (where user creates windows),
then enter the event loop.

# Example
```julia
using WxWidgets

WxWidgets.run_app() do
    frame = wxFrame(nothing, "Hello World", size=(400, 300))
    show(frame)
end
```
"""
function run_app(setup::Function; app_name::String="wxApp")
    # Initialize wxWidgets
    result = kwxapp_initialize()
    result == 0 && error("Failed to initialize wxWidgets")

    # Set application name
    kwxapp_setappname(app_name)

    # Enable image handlers
    kwxapp_initallimagehandlers()

    # User setup (create windows, connect events)
    setup()

    # Enter event loop (blocks until exit)
    exit_code = kwxapp_mainloop()

    return exit_code
end

"""
    exit_app()

Signal the event loop to exit.
"""
function exit_app()
    kwxapp_exit()
end

"""
    set_top_window(window)

Set the top-level window. The event loop exits when this window closes.
"""
function set_top_window(window)
    kwxapp_settopwindow(window.ptr)
end

"""
    set_exit_on_frame_delete(flag::Bool)

Control whether the app exits when the top window is deleted.
Default is true.
"""
function set_exit_on_frame_delete(flag::Bool)
    kwxapp_setexitonframedelete(flag)
end
