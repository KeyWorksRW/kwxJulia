# Phase 5 Quick Reference: Event Handling

## Connecting Event Handlers

### Basic Connection

```julia
wx_connect!(window, event_type, handler; id=-1, last_id=id)
```

**Parameters:**
- `window::WxWindow` — Window to connect handler to
- `event_type::Integer` — Event type constant (e.g., `KwxFFI.wxEVT_BUTTON()`)
- `handler::Function` — Function with signature `handler(event::WxEvent)`
- `id::Int = -1` — Window ID filter (-1 = any ID)
- `last_id::Int = id` — Last ID in range (for ID ranges)

### Handler Signature

```julia
function my_handler(event::WxEvent)
    # event.ptr contains the C++ wxEvent* pointer
    # Do NOT store event beyond this function's scope
    println("Event fired!")
end
```

## Event Types

Available event type constants (from Phase 2):

| Constant | Event |
|----------|-------|
| `KwxFFI.wxEVT_BUTTON()` | Button clicked |
| `KwxFFI.wxEVT_CLOSE_WINDOW()` | Window close requested |
| `KwxFFI.wxEVT_MENU()` | Menu item selected |
| `KwxFFI.wxEVT_LEFT_DOWN()` | Left mouse button down |
| `KwxFFI.wxEVT_LEFT_UP()` | Left mouse button up |
| `KwxFFI.wxEVT_PAINT()` | Window needs repainting |
| `KwxFFI.wxEVT_SIZE()` | Window resized |

**Note**: Event constants are accessed via `KwxFFI.wxEVT_*()` function calls (e.g., `KwxFFI.wxEVT_BUTTON()`)

## Examples

### Close Event

```julia
frame = WxFrame(nothing, "My App")

wx_connect!(frame, KwxFFI.wxEVT_CLOSE_WINDOW()) do event
    println("Window is closing!")
    # Cleanup code here
end
```

### Size Event

```julia
wx_connect!(frame, KwxFFI.wxEVT_SIZE()) do event
    size = get_size(frame)
    println("Resized to: $(size[1]) x $(size[2])")
end
```

### Mouse Event

```julia
wx_connect!(frame, KwxFFI.wxEVT_LEFT_DOWN()) do event
    pos = get_position(frame)
    println("Clicked at window position: $pos")
end
```

### Multiple Handlers

```julia
frame = WxFrame(nothing, "Multi-Event")

# First handler
wx_connect!(frame, KwxFFI.wxEVT_SIZE()) do event
    println("Size handler 1")
end

# Second handler (different event)
wx_connect!(frame, KwxFFI.wxEVT_PAINT()) do event
    println("Paint handler")
end

# All closures stored safety
println("Handlers stored: ", length(frame.closures))  # → 2
```

## Convenience Functions

### on_close!

Shorthand for close event:

```julia
on_close!(frame) do event
    println("Goodbye!")
end

# Equivalent to:
wx_connect!(frame, KwxFFI.wxEVT_CLOSE_WINDOW()) do event
    println("Goodbye!")
end
```

## Disconnecting Events

Rarely needed (handlers auto-cleanup with window):

```julia
# Disconnect all handlers of this type
wx_disconnect!(window, KwxFFI.wxEVT_BUTTON())

# Disconnect specific ID
wx_disconnect!(window, KwxFFI.wxEVT_BUTTON(), id=1001)
```

Returns `true` if disconnected, `false` if not found.

## Error Handling

Exceptions in handlers are caught automatically:

```julia
wx_connect!(window, KwxFFI.wxEVT_LEFT_DOWN()) do event
    error("This won't crash the app!")
    # Error logged to stderr, app continues normally
end
```

**Important**: Never let exceptions propagate to C++ — it would crash. The framework catches all errors for you.

## GC Safety (Important!)

Event handlers are **automatically kept alive** by storing function pointers in `window.closures`:

```julia
frame = WxFrame(...)

# This closure won't be garbage collected
wx_connect!(frame, KwxFFI.wxEVT_SIZE()) do event
    println("Safe from GC!")
end

# The function pointer is in frame.closures
# It lives as long as the frame lives
```

**You don't need to do anything** — the framework handles it.

## Complete Example

```julia
using WxWidgets

WxWidgets.run_app() do
    frame = WxFrame(nothing, "Event Demo", size=(600, 400))

    # Create status bar
    create_status_bar(frame)
    set_status_text(frame, "Try resizing or closing!")

    # Close handler
    on_close!(frame) do event
        println("Goodbye!")
    end

    # Size handler
    wx_connect!(frame, KwxFFI.wxEVT_SIZE()) do event
        size = get_size(frame)
        set_status_text(frame, "Size: $(size[1])x$(size[2])")
    end

    # Paint handler
    wx_connect!(frame, KwxFFI.wxEVT_PAINT()) do event
        println("Repaint requested")
    end

    # Show and run
    centre(frame)
    set_top_window(frame)
    show_window(frame)
end
```

## Event Lifecycle

1. **Connection**: `wx_connect!` creates @cfunction and stores in `closures`
2. **Event Fires**: C++ calls the function pointer
3. **Handler Runs**: Your Julia function executes (exceptions caught)
4. **Cleanup**: When window destroyed, C++ cleans up, then Julia GC collects

## Do's and Don'ts

### ✓ Do

- Use `do` syntax for clean event handlers
- Handle exceptions within your handler code
- Connect multiple handlers to same window
- Store local state using closures

### ✗ Don't

- Store the `WxEvent` object — pointer becomes invalid!
- Let exceptions escape handler — would crash app (framework prevents this)
- Manually manage `closures` vector — framework handles it
- Call handler functions directly — they're for C callbacks only

## Advanced: Window ID Filtering

Connect handler for specific window ID:

```julia
# Only handle events from ID 1001
wx_connect!(frame, KwxFFI.wxEVT_BUTTON(), id=1001) do event
    println("Button 1001 clicked!")
end

# Handle range of IDs (1000-1010)
wx_connect!(frame, KwxFFI.wxEVT_BUTTON(), id=1000, last_id=1010) do event
    println("Button in range 1000-1010 clicked!")
end
```

## Debugging

Print closure count to verify handlers are registered:

```julia
frame = WxFrame(...)
wx_connect!(frame, KwxFFI.wxEVT_SIZE()) do event; end
wx_connect!(frame, KwxFFI.wxEVT_CLOSE_WINDOW()) do event; end

println("Active handlers: ", length(frame.closures))  # → 2
```

## Next: Phase 6 (Controls)

With event handling complete, Phase 6 will add controls like buttons:

```julia
button = WxButton(frame, "Click Me!")
wx_connect!(button, KwxFFI.wxEVT_BUTTON()) do event
    println("Button clicked!")
end
```

This combines Phase 4 (widgets), Phase 5 (events), and Phase 6 (controls) into a complete GUI.
