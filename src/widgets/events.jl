# High-level event handling functions

"""
    wx_connect!(window::WxWindow, event_type::Integer, handler::Function;
                id::Int = -1, last_id::Int = id)

Connect an event handler to a window.

The handler function receives a WxEvent object when the event fires.
The handler should have the signature: `handler(event::WxEvent)`.

# Arguments
- `window`: The window to connect the handler to
- `event_type`: Event type constant (e.g., `wxEVT_BUTTON[]`, `wxEVT_CLOSE_WINDOW[]`)
- `handler`: Julia function to call when event occurs
- `id`: Window ID to filter events (-1 for any ID)
- `last_id`: Last ID in range (defaults to `id` for single ID)

# Example
```julia
frame = WxFrame(nothing, "My App")
wx_connect!(frame, wxEVT_CLOSE_WINDOW[]) do event
    println("Frame is closing!")
end
```

# Important Notes
- The function pointer is stored in `window.closures` to prevent garbage collection
- Exceptions in the handler are caught and logged to prevent crashes
- Do not store the WxEvent object beyond the handler's scope
"""
function wx_connect!(window::WxWindow, event_type::Integer, handler::Function;
                     id::Integer = -1, last_id::Integer = id)
    # Create a C-callable wrapper around the Julia closure
    # The ClosureFun signature is: void(void* fun, void* data, void* evt)
    function c_handler(fun::Ptr{Cvoid}, data::Ptr{Cvoid}, evt::Ptr{Cvoid})::Cvoid
        try
            # evt == C_NULL signals cleanup (called from ~wxClosure destructor)
            # In this case, do nothing - Julia's GC will handle cleanup
            if evt != C_NULL
                # Wrap the event pointer and call the user's handler
                handler(WxEvent(evt))
            end
        catch e
            # Never let Julia exceptions propagate to C++ - that would crash
            @error "Exception in event handler" exception=(e, catch_backtrace())
        end
        nothing
    end

    # Create a C function pointer from the wrapper
    # The $ interpolation creates a runtime closure that captures the handler
    cfun = @cfunction($c_handler, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))

    # Call kwxApp_Connect which wraps cfun in a wxClosure/wxCallback pair
    # This handles the C++ side of lifetime management
    result = kwxapp_connect(
        window.ptr,
        id,
        last_id,
        event_type,
        Base.unsafe_convert(Ptr{Cvoid}, cfun),  # Convert CFunction to Ptr{Cvoid}
        C_NULL  # user_data (unused - Julia closure captures state)
    )

    if result != 0
        @warn "kwxApp_Connect returned non-zero: $result"
    end

    # CRITICAL: Store the function pointer to prevent GC
    # Julia's GC doesn't know C++ holds a reference to it
    push!(window.closures, cfun)

    nothing
end

"""
    wx_disconnect!(window::WxWindow, event_type::Integer;
                   id::Int = -1, last_id::Int = id) -> Bool

Disconnect an event handler from a window.

Returns `true` if a handler was found and disconnected, `false` otherwise.

# Note
This disconnects the event handler but does NOT remove the function pointer
from `window.closures`. The closure will be GC'd when the window is destroyed.
"""
function wx_disconnect!(window::WxWindow, event_type::Integer;
                        id::Integer = -1, last_id::Integer = id)
    result = kwxapp_disconnect(window.ptr, id, last_id, event_type)
    result != 0
end

"""
    on_close!(window::WxWindow, handler::Function)

Convenience function to connect a close event handler.

Equivalent to: `wx_connect!(window, wxEVT_CLOSE_WINDOW[], handler)`
"""
function on_close!(window::WxWindow, handler::Function)
    wx_connect!(window, wxEVT_CLOSE_WINDOW[], handler)
end
