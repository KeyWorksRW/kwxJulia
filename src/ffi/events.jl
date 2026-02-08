# Raw FFI declarations for event handling functions

"""
    kwxapp_connect(obj::Ptr{Cvoid}, first::Int, last::Int, event_type::Int,
                   callback::Ptr{Cvoid}, user_data::Ptr{Cvoid}) -> Int

Connect an event handler to a window. The callback must be a function pointer
created with @cfunction matching the signature:
    void(void* fun, void* data, void* evt)

Returns 0 on success.

# Arguments
- `obj`: Window/event handler pointer
- `first`: First window ID in range (-1 for any)
- `last`: Last window ID in range (same as first for single ID)
- `event_type`: Event type constant (e.g., wxEVT_BUTTON[])
- `callback`: Function pointer from @cfunction
- `user_data`: Optional user data pointer (can be C_NULL)
"""
function kwxapp_connect(obj::Ptr{Cvoid}, first::Integer, last::Integer, event_type::Integer,
                        callback::Ptr{Cvoid}, user_data::Ptr{Cvoid})
    @ccall $(ffi(:kwxApp_Connect))(
        obj::Ptr{Cvoid},
        first::Cint,
        last::Cint,
        event_type::Cint,
        callback::Ptr{Cvoid},
        user_data::Ptr{Cvoid}
    )::Cint
end

"""
    kwxapp_disconnect(obj::Ptr{Cvoid}, first::Int, last::Int, event_type::Int) -> Int

Disconnect an event handler from a window.

Returns non-zero if the handler was found and disconnected.
"""
function kwxapp_disconnect(obj::Ptr{Cvoid}, first::Integer, last::Integer, event_type::Integer)
    @ccall $(ffi(:kwxApp_Disconnect))(
        obj::Ptr{Cvoid},
        first::Cint,
        last::Cint,
        event_type::Cint
    )::Cint
end
