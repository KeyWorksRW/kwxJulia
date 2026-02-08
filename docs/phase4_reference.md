# Phase 4 Quick Reference

## Creating a Frame

```julia
using WxWidgets

# Basic frame
frame = WxFrame(nothing, "My App")

# Frame with custom size and position
frame = WxFrame(nothing, "My App",
                size=(800, 600),
                pos=(100, 100))

# Frame with custom style
frame = WxFrame(nothing, "My App",
                style=wxDEFAULT_FRAME_STYLE[])
```

## Window Operations

```julia
# Show/hide
show_window(frame)         # Show the frame
show_window(frame, false)  # Hide the frame
hide(frame)                # Hide (shorthand)

# Position and size
set_size(frame, x, y, width, height)
(width, height) = get_size(frame)
set_position(frame, x, y)
(x, y) = get_position(frame)

# Label (title bar text)
set_label(frame, "New Title")
title = get_label(frame)

# Center on screen
centre(frame)              # British spelling
center(frame)              # American spelling

# Enable/disable
enable(frame)
enable(frame, false)       # Disable
if is_enabled(frame)
    # ...
end

# Check visibility
if is_shown(frame)
    # ...
end

# Focus
set_focus(frame)

# Layout
layout(frame)              # Recalculate sizer layout
refresh(frame)             # Force redraw
update(frame)              # Process pending paints

# Close
close(frame)               # Request close (can be cancelled by event handler)
close(frame, true)         # Force close
destroy!(frame)            # Immediate destruction (use with caution)
```

## Status Bar

```julia
# Create status bar
create_status_bar(frame, 1)           # Single field
create_status_bar(frame, 3)           # Three fields

# Set status text
set_status_text(frame, "Ready", 0)    # Field 0
set_status_text(frame, "Line 1", 1)   # Field 1

# Push/pop status text (temporary messages)
push_status_text(frame, "Processing...")
# ... do work ...
pop_status_text(frame)                # Restore previous text
```

## Complete Example

```julia
using WxWidgets

WxWidgets.run_app(app_name="MyApp") do
    # Create frame
    frame = WxFrame(nothing, "Hello World",
                    size=(600, 400))

    # Add status bar
    create_status_bar(frame, 1)
    set_status_text(frame, "Welcome!")

    # Center and show
    centre(frame)
    set_top_window(frame)
    show_window(frame)

    println("Application running. Close window to exit.")
end
```

## Type Hierarchy

```julia
abstract type WxObject end
abstract type WxEvtHandler <: WxObject end
abstract type WxWindow <: WxEvtHandler end
abstract type WxControl <: WxWindow end           # For Phase 6
abstract type WxTopLevelWindow <: WxWindow end

mutable struct WxFrame <: WxTopLevelWindow
    ptr::Ptr{Cvoid}
    children::Vector{Any}
    closures::Vector{Any}
end
```

## GC Safety

The `children` and `closures` vectors prevent premature garbage collection:

- `children` — Add child widgets here after creation (Phase 6)
- `closures` — Add event handler closures here (Phase 5)

```julia
# Example (Phase 6):
button = WxButton(frame, "Click me")
push!(frame.children, button)  # Keep button alive
```

## Error Handling

```julia
# Frame creation returns ptr=C_NULL on failure
frame = WxFrame(nothing, "Title")
if frame.ptr == C_NULL
    error("Failed to create frame")
end
```

## Window Lifecycle

```julia
# 1. Create
frame = WxFrame(nothing, "App")

# 2. Configure
create_status_bar(frame)
centre(frame)

# 3. Show
set_top_window(frame)
show_window(frame)

# 4. Event loop runs (in run_app)

# 5. User closes window → app exits
```

## Next: Phase 5 (Event Handling)

To connect event handlers:

```julia
# Coming in Phase 5
wx_connect!(frame, wxEVT_CLOSE_WINDOW[]) do event
    println("Window is closing!")
end
```
