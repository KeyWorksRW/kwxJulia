# wxString <-> Julia String conversion utilities

"""
    wxString

Wrapper for wxString* pointer. Used for passing strings to wxWidgets functions.
Automatically converted to/from Julia String.
"""
mutable struct wxString
    ptr::Ptr{Cvoid}

    function wxString(s::AbstractString)
        ptr = GC.@preserve s KwxFFI.wxString_CreateUTF8(Base.unsafe_convert(Cstring, s))
        obj = new(ptr)
        finalizer(delete!, obj)
        return obj
    end

    # Constructor from existing pointer (no finalizer)
    function wxString(ptr::Ptr{Cvoid}, own::Bool)
        obj = new(ptr)
        if own
            finalizer(delete!, obj)
        end
        return obj
    end
end

"""
    delete!(ws::wxString)

Explicitly delete a wxString object. Called automatically by finalizer.
"""
function delete!(ws::wxString)
    if ws.ptr != C_NULL
        KwxFFI.wxString_Delete(ws.ptr)
        ws.ptr = C_NULL
    end
end

"""
    Base.String(ws::wxString) -> String

Convert wxString to Julia String via kwxUtf8Buffer.
"""
function Base.String(ws::wxString)
    if ws.ptr == C_NULL
        return ""
    end

    buf = KwxFFI.kwxUtf8Buffer_Create(ws.ptr)
    if buf == C_NULL
        return ""
    end

    cstr = KwxFFI.kwxUtf8Buffer_Data(buf)
    result = unsafe_string(cstr)
    KwxFFI.kwxUtf8Buffer_Delete(buf)

    return result
end

"""
    Base.convert(::Type{wxString}, s::AbstractString) -> wxString

Convert Julia String to wxString.
"""
Base.convert(::Type{wxString}, s::AbstractString) = wxString(s)

"""
    Base.convert(::Type{String}, ws::wxString) -> String

Convert wxString to Julia String.
"""
Base.convert(::Type{String}, ws::wxString) = String(ws)

"""
    _wx_get_string(ws_ptr::Ptr{Cvoid}) -> String

Internal helper: convert a wxString pointer returned by a KwxFFI function to a
Julia String, then delete the wxString.
"""
function _wx_get_string(ws_ptr::Ptr{Cvoid})
    if ws_ptr == C_NULL
        return ""
    end
    result = String(wxString(ws_ptr, false))
    KwxFFI.wxString_Delete(ws_ptr)
    result
end
