# Base type definitions for wxWidgets objects

"""
Abstract base type for all wxWidgets objects.
"""
abstract type WxObject end

"""
Abstract base type for event handlers (objects that can receive events).
"""
abstract type WxEvtHandler <: WxObject end

"""
Abstract base type for windows (visual objects that can be displayed).
"""
abstract type WxWindow <: WxEvtHandler end

"""
Abstract base type for controls (interactive UI elements).
"""
abstract type WxControl <: WxWindow end

"""
Abstract base type for top-level windows (frames, dialogs).
"""
abstract type WxTopLevelWindow <: WxWindow end

"""
Abstract base type for sizers (layout managers).
"""
abstract type WxSizer <: WxObject end

"""
Wrapper for wxEvent pointers passed to event handlers.

Event handlers receive this type which wraps the C++ wxEvent* pointer.
The ptr field should not be stored beyond the handler's scope as the
underlying C++ object may be deleted.
"""
struct WxEvent
    ptr::Ptr{Cvoid}
end
