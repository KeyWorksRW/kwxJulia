# Base type definitions for wxWidgets objects
#
# NOTE: In a break from Julia conventions, we use the 'wx' prefix (lowercase)
# for type names to match the wxWidgets C++ naming convention. This makes it
# easier for wxWidgets developers to find the corresponding C++ class.

"""
Abstract base type for all wxWidgets objects.
"""
abstract type wxObject end

"""
Abstract base type for event handlers (objects that can receive events).
"""
abstract type wxEvtHandler <: wxObject end

"""
Abstract base type for windows (visual objects that can be displayed).
"""
abstract type wxWindow <: wxEvtHandler end

"""
Abstract base type for controls (interactive UI elements).
"""
abstract type wxControl <: wxWindow end

"""
Abstract base type for top-level windows (frames, dialogs).
"""
abstract type wxTopLevelWindow <: wxWindow end

"""
Abstract base type for sizers (layout managers).
"""
abstract type wxSizer <: wxObject end

"""
Wrapper for wxEvent pointers passed to event handlers.

Event handlers receive this type which wraps the C++ wxEvent* pointer.
The ptr field should not be stored beyond the handler's scope as the
underlying C++ object may be deleted.
"""
struct wxEvent
    ptr::Ptr{Cvoid}
end
