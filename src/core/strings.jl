# wxString <-> Julia String conversion utilities

"""
    WxString

Wrapper for wxString* pointer. Used for passing strings to wxWidgets functions.
Automatically converted to/from Julia String.
"""
mutable struct WxString
    ptr::Ptr{Cvoid}

    function WxString(s::AbstractString)
        ptr = @ccall $(ffi(:wxString_CreateUTF8))(s::Cstring)::Ptr{Cvoid}
        obj = new(ptr)
        finalizer(delete!, obj)
        return obj
    end

    # Constructor from existing pointer (no finalizer)
    function WxString(ptr::Ptr{Cvoid}, own::Bool)
        obj = new(ptr)
        if own
            finalizer(delete!, obj)
        end
        return obj
    end
end

"""
    delete!(ws::WxString)

Explicitly delete a wxString object. Called automatically by finalizer.
"""
function delete!(ws::WxString)
    if ws.ptr != C_NULL
        @ccall $(ffi(:wxString_Delete))(ws.ptr::Ptr{Cvoid})::Cvoid
        ws.ptr = C_NULL
    end
end

"""
    Base.String(ws::WxString) -> String

Convert wxString to Julia String via wxCharBuffer.
"""
function Base.String(ws::WxString)
    if ws.ptr == C_NULL
        return ""
    end

    # wxString_GetUtf8 returns wxCharBuffer* (heap-allocated)
    cb = @ccall $(ffi(:wxString_GetUtf8))(ws.ptr::Ptr{Cvoid})::Ptr{Cvoid}
    if cb == C_NULL
        return ""
    end

    # wxCharBuffer_DataUtf8 returns pointer to internal UTF-8 data
    cstr = @ccall $(ffi(:wxCharBuffer_DataUtf8))(cb::Ptr{Cvoid})::Cstring
    result = unsafe_string(cstr)

    # Free the wxCharBuffer
    @ccall $(ffi(:wxCharBuffer_Delete))(cb::Ptr{Cvoid})::Cvoid

    return result
end

"""
    Base.convert(::Type{WxString}, s::AbstractString) -> WxString

Convert Julia String to WxString.
"""
Base.convert(::Type{WxString}, s::AbstractString) = WxString(s)

"""
    Base.convert(::Type{String}, ws::WxString) -> String

Convert WxString to Julia String.
"""
Base.convert(::Type{String}, ws::WxString) = String(ws)
