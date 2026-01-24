# Julia wxWidgets Binding Implementation Plan

## Project Overview

**Goal**: Create a Julia binding (`kwxJulia`) to the wxWidgets GUI library via the wxFFI C interface.

**Architecture**: Julia → wxFFI (C interface) → wxWidgets (C++)

This binding will enable Julia developers to build native cross-platform desktop GUI applications using wxWidgets, leveraging Julia's built-in `@ccall` macro and `Libdl` module for FFI.

---

## Prerequisites & Dependencies

### Build Requirements
- **Julia 1.9+** (LTS recommended; 1.10+ preferred for improved ccall performance)
- **wxWidgets 3.3.0+** with `wxUSE_UNICODE_UTF8=1` enabled
- **wxFFI library**: Prebuilt `wxffi.dll` (Windows), `libwxffi.so` (Linux), `libwxffi.dylib` (macOS)

### Julia Development Tools
| Tool | Purpose |
|------|---------|
| Julia REPL | Interactive development and testing |
| VS Code + Julia Extension | IDE with language server support |
| Pkg.jl | Package management (built-in) |
| Test.jl | Unit testing framework (stdlib) |
| Documenter.jl | Documentation generation (optional) |

### No External Compilation Required
Unlike C/C++ projects, Julia does not require CMake or a build system for the binding itself. The binding is pure Julia code that calls into the prebuilt wxFFI shared library.

---

## Architecture Design

### Layer Structure

```
┌─────────────────────────────────────────────────┐
│              User Application                    │
│         (Idiomatic Julia GUI code)              │
├─────────────────────────────────────────────────┤
│         High-Level API (src/widgets/)           │
│    wxButton, wxFrame, wxTextCtrl, etc.          │
│    - Julian naming conventions                  │
│    - Automatic resource management              │
│    - Event handling via closures                │
├─────────────────────────────────────────────────┤
│         Core Module (src/core/)                 │
│    - Library loading (Libdl)                    │
│    - Type definitions                           │
│    - String conversion (wxString ↔ String)      │
│    - Constants/enums                            │
├─────────────────────────────────────────────────┤
│         FFI Declarations (src/ffi/)             │
│    - Raw @ccall wrappers                        │
│    - 1:1 mapping to wxFFI functions             │
├─────────────────────────────────────────────────┤
│              wxFFI (wxffi.dll)                  │
│         C interface to wxWidgets                │
└─────────────────────────────────────────────────┘
```

### Package Structure

```
kwxJulia-dev/
├── src/
│   ├── WxWidgets.jl           # Main module entry point
│   ├── core/
│   │   ├── library.jl         # Library loading and initialization
│   │   ├── types.jl           # Julia type definitions for wxFFI types
│   │   ├── strings.jl         # wxString <-> Julia String conversion
│   │   ├── constants.jl       # wxWidgets constants (from defs.cpp)
│   │   └── events.jl          # Event type definitions
│   ├── ffi/
│   │   ├── app.jl             # Application lifecycle FFI
│   │   ├── window.jl          # wxWindow FFI declarations
│   │   ├── frame.jl           # wxFrame FFI declarations
│   │   ├── controls.jl        # Common controls FFI
│   │   └── sizers.jl          # Layout sizers FFI
│   └── widgets/
│       ├── app.jl             # High-level WxApp wrapper
│       ├── window.jl          # High-level Window wrapper
│       ├── frame.jl           # High-level Frame wrapper
│       ├── button.jl          # High-level Button wrapper
│       ├── textctrl.jl        # High-level TextCtrl wrapper
│       └── sizers.jl          # High-level Sizer wrappers
├── test/
│   ├── runtests.jl            # Test runner
│   ├── test_strings.jl        # String conversion tests
│   ├── test_constants.jl      # Constants tests
│   └── test_widgets.jl        # Widget creation tests
├── examples/
│   ├── hello_world.jl         # Minimal example
│   ├── calculator.jl          # Calculator app
│   └── text_editor.jl         # Text editor example
├── deps/
│   └── build.jl               # Dependency checking script
├── Project.toml               # Julia package manifest
└── README.md
```

---

## Implementation Phases

### Phase 1: Foundation (Core Infrastructure)

**Objective**: Establish library loading, type system, and string handling.

**Files to create**:
- `src/WxWidgets.jl` - Main module
- `src/core/library.jl` - Library loading via Libdl
- `src/core/types.jl` - Base type definitions
- `src/core/strings.jl` - wxString conversion utilities
- `Project.toml` - Package configuration

**Key implementation details**:

```julia
# Library loading pattern
const libwxffi = Ref{Ptr{Cvoid}}(C_NULL)

function __init__()
    # Platform-specific library loading
    libname = @static if Sys.iswindows()
        "wxffi.dll"
    elseif Sys.isapple()
        "libwxffi.dylib"
    else
        "libwxffi.so"
    end
    libwxffi[] = Libdl.dlopen(libname)
end
```

```julia
# wxString type and conversion
struct WxString
    ptr::Ptr{Cvoid}
end

# Create wxString from Julia String
function WxString(s::AbstractString)
    ptr = @ccall libwxffi[].wxString_CreateUTF8(s::Cstring)::Ptr{Cvoid}
    WxString(ptr)
end

# Extract Julia String and cleanup
function Base.String(ws::WxString)
    cstr = @ccall libwxffi[].wxString_GetUTF8(ws.ptr::Ptr{Cvoid})::Cstring
    result = unsafe_string(cstr)
    @ccall libwxffi[].wxString_Delete(ws.ptr::Ptr{Cvoid})::Cvoid
    result
end
```

**Verification**:
- Library loads successfully on target platform
- String round-trip: `String(WxString("test")) == "test"`

---

### Phase 2: Constants and Event Types

**Objective**: Export wxWidgets constants and event type identifiers.

**Files to create**:
- `src/core/constants.jl` - Style flags, IDs, etc.
- `src/core/events.jl` - Event type constants

**Approach**: Call the `exp*()` functions from wxFFI's defs.cpp:

```julia
# Constants loaded at init time
const wxDEFAULT_FRAME_STYLE = Ref{Cint}(0)
const wxTE_MULTILINE = Ref{Cint}(0)

function load_constants!()
    wxDEFAULT_FRAME_STYLE[] = @ccall libwxffi[].expwxDEFAULT_FRAME_STYLE()::Cint
    wxTE_MULTILINE[] = @ccall libwxffi[].expwxTE_MULTILINE()::Cint
    # ... etc
end
```

**Alternative**: Use a generated script to parse `wxffi_glue.h` and auto-generate constant bindings.

---

### Phase 3: Application Lifecycle

**Objective**: Implement wxApp wrapper to start/stop the event loop.

**Files to create**:
- `src/ffi/app.jl` - Raw FFI for ELJApp
- `src/widgets/app.jl` - High-level WxApp

**Key functions to wrap**:
- `ELJApp_InitializeC` - Initialize the application
- `ELJApp_MainLoop` - Run the event loop
- `ELJApp_GetApp` - Get the app instance
- `ELJApp_Dispatch` - Process pending events

```julia
# High-level API
function run_app(init_callback::Function)
    # Create closure for init callback
    closure = create_closure(init_callback)

    # Initialize and run
    @ccall libwxffi[].ELJApp_InitializeC(
        closure::Ptr{Cvoid},
        0::Cint,           # argc
        C_NULL::Ptr{Ptr{Cchar}}  # argv
    )::Cint
end
```

---

### Phase 4: Window and Frame

**Objective**: Implement wxWindow base and wxFrame for top-level windows.

**Files to create**:
- `src/ffi/window.jl` - wxWindow FFI
- `src/ffi/frame.jl` - wxFrame FFI
- `src/widgets/window.jl` - High-level Window
- `src/widgets/frame.jl` - High-level Frame

**Type hierarchy**:

```julia
abstract type WxObject end
abstract type WxEvtHandler <: WxObject end
abstract type WxWindow <: WxEvtHandler end

mutable struct WxFrame <: WxWindow
    ptr::Ptr{Cvoid}
    children::Vector{WxWindow}  # prevent GC of children
end

function WxFrame(parent::Union{WxWindow,Nothing}, title::String;
                 id::Int = -1,
                 pos::Tuple{Int,Int} = (-1, -1),
                 size::Tuple{Int,Int} = (-1, -1),
                 style::Int = wxDEFAULT_FRAME_STYLE[])
    parent_ptr = isnothing(parent) ? C_NULL : parent.ptr
    title_ws = WxString(title)

    ptr = @ccall libwxffi[].wxFrame_Create(
        parent_ptr::Ptr{Cvoid},
        id::Cint,
        title_ws.ptr::Ptr{Cvoid},
        pos[1]::Cint, pos[2]::Cint,
        size[1]::Cint, size[2]::Cint,
        style::Cint
    )::Ptr{Cvoid}

    delete!(title_ws)  # cleanup wxString
    WxFrame(ptr, WxWindow[])
end
```

---

### Phase 5: Event Handling

**Objective**: Implement the closure-based event callback system.

**Key challenge**: Julia callbacks must be wrapped via `@cfunction` to be callable from C.

```julia
# Closure wrapper for event callbacks
struct WxClosure
    ptr::Ptr{Cvoid}
    prevent_gc::Any  # prevent garbage collection of Julia callback
end

function create_event_handler(callback::Function)
    # C callback signature: void(void* fun, void* data, void* evt)
    function c_callback(fun::Ptr{Cvoid}, data::Ptr{Cvoid}, evt::Ptr{Cvoid})
        if evt != C_NULL
            callback(WxEvent(evt))
        end
        nothing
    end

    cfun = @cfunction($c_callback, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))

    ptr = @ccall libwxffi[].wxClosure_Create(
        cfun::Ptr{Cvoid},
        C_NULL::Ptr{Cvoid}
    )::Ptr{Cvoid}

    WxClosure(ptr, cfun)  # cfun kept alive by struct
end

# Connect event to handler
function on_event!(window::WxWindow, event_type::Cint, handler::Function)
    closure = create_event_handler(handler)
    push!(window.closures, closure)  # prevent GC

    @ccall libwxffi[].wxEvtHandler_Connect(
        window.ptr::Ptr{Cvoid},
        -1::Cint,              # id
        -1::Cint,              # lastId
        event_type::Cint,
        closure.ptr::Ptr{Cvoid}
    )::Cvoid
end
```

---

### Phase 6: Common Controls

**Objective**: Wrap frequently used controls.

**Priority controls**:
1. `wxButton` - Command button
2. `wxTextCtrl` - Text input/editor
3. `wxStaticText` - Label
4. `wxCheckBox` - Check box
5. `wxComboBox` - Drop-down selection
6. `wxListBox` - List selection

**Example - wxButton**:

```julia
mutable struct WxButton <: WxControl
    ptr::Ptr{Cvoid}
    parent::WxWindow
end

function WxButton(parent::WxWindow, label::String;
                  id::Int = wxID_ANY[],
                  pos::Tuple{Int,Int} = (-1, -1),
                  size::Tuple{Int,Int} = (-1, -1),
                  style::Int = 0)
    label_ws = WxString(label)

    ptr = @ccall libwxffi[].wxButton_Create(
        parent.ptr::Ptr{Cvoid},
        id::Cint,
        label_ws.ptr::Ptr{Cvoid},
        pos[1]::Cint, pos[2]::Cint,
        size[1]::Cint, size[2]::Cint,
        style::Cint
    )::Ptr{Cvoid}

    delete!(label_ws)
    btn = WxButton(ptr, parent)
    push!(parent.children, btn)
    btn
end

# Convenience event binding
function on_click!(button::WxButton, handler::Function)
    on_event!(button, EVT_COMMAND_BUTTON_CLICKED[], handler)
end
```

---

### Phase 7: Layout Sizers

**Objective**: Wrap wxBoxSizer and wxGridSizer for layout management.

```julia
abstract type WxSizer <: WxObject end

mutable struct WxBoxSizer <: WxSizer
    ptr::Ptr{Cvoid}
end

function WxBoxSizer(orientation::Symbol)
    orient = orientation == :horizontal ? wxHORIZONTAL[] : wxVERTICAL[]
    ptr = @ccall libwxffi[].wxBoxSizer_Create(orient::Cint)::Ptr{Cvoid}
    WxBoxSizer(ptr)
end

function add!(sizer::WxSizer, window::WxWindow;
              proportion::Int = 0,
              flags::Int = 0,
              border::Int = 0)
    @ccall libwxffi[].wxSizer_Add(
        sizer.ptr::Ptr{Cvoid},
        window.ptr::Ptr{Cvoid},
        proportion::Cint,
        flags::Cint,
        border::Cint
    )::Ptr{Cvoid}
end
```

---

### Phase 8: Testing & Examples

**Objective**: Comprehensive tests and example applications.

**Test categories**:
1. Unit tests for string conversion
2. Unit tests for constant loading
3. Integration tests for widget creation
4. Event handling tests

**Example applications**:
1. Hello World - minimal frame with button
2. Calculator - demonstrates layout and events
3. Text Editor - demonstrates text control and menus

---

## Type Mapping Reference

| wxFFI C Type | Julia Type |
|--------------|------------|
| `void*` (TClass) | `Ptr{Cvoid}` |
| `int` | `Cint` (Int32) |
| `bool` / `TBool` | `Cint` (0/1) |
| `char*` (TString) | `Cstring` for input, `Ptr{UInt8}` for output |
| `wxString*` | Custom `WxString` wrapper |
| `TPoint(x,y)` | Two `Cint` arguments |
| `TSize(w,h)` | Two `Cint` arguments |
| `TRect(x,y,w,h)` | Four `Cint` arguments |
| `ClosureFun` | `Ptr{Cvoid}` from `@cfunction` |

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| GC collects closures while in use | High | Store references in parent objects; use explicit prevent_gc fields |
| wxString memory leaks | Medium | RAII-like pattern with explicit delete!() calls |
| Platform-specific library paths | Medium | Search common paths; allow WXFFI_PATH environment override |
| Event callback exceptions crash app | High | Wrap callbacks in try-catch; log errors; never throw to C |
| Thread safety | Medium | Document single-threaded requirement; wxWidgets main thread only |

---

## Verification Strategy

### Phase Verification
After each phase, verify:
1. Code compiles without errors (`using WxWidgets`)
2. All tests pass (`] test WxWidgets`)
3. Example code runs without crashing

### Final Verification
1. Build and run all examples on Windows/Linux/macOS
2. Memory leak testing with extended runs
3. Documentation generation succeeds

---

## Timeline Estimate

| Phase | Estimated Agent-Hours |
|-------|----------------------|
| Phase 1: Foundation | 1-2 |
| Phase 2: Constants | 0.5 |
| Phase 3: App Lifecycle | 1 |
| Phase 4: Window/Frame | 1-2 |
| Phase 5: Events | 2 |
| Phase 6: Controls | 2-3 |
| Phase 7: Sizers | 1 |
| Phase 8: Testing | 2 |
| **Total** | **10-14** |

---

## Next Steps

1. **Review this plan** and provide feedback
2. Begin Phase 1 implementation
3. Iteratively implement remaining phases

---

## GitHub.com Coding Agent Assignment Analysis

The GitHub.com coding agent (using Opus 4.5) operates without Serena's symbolic tools or `key_*` tools, but can effectively handle self-contained Julia file creation tasks where:
- The requirements are clearly specified
- No runtime testing or wxFFI library access is needed
- The work is primarily code generation from documented patterns

### Suitable for GitHub Agent

| Phase | Rationale |
|-------|-----------|
| **Phase 2: Constants** | ✅ **Ideal candidate.** Mechanical task: parse `wxffi_glue.h` for `exp*()` functions and generate Julia constant definitions. No runtime dependencies. Clear input/output. Can be done by reading the header file and generating `constants.jl` and `events.jl`. |
| **Phase 7: Layout Sizers** | ✅ **Good candidate.** After Phases 1-5 establish patterns, sizer wrappers are straightforward FFI calls. Provide the established patterns and wxFFI function signatures; agent generates `sizers.jl`. |

### Requires Local Agent (with Serena + key_* tools)

| Phase | Rationale |
|-------|-----------|
| **Phase 1: Foundation** | ❌ Establishes core patterns that all other phases depend on. Needs interactive testing with actual library loading. Must work before anything else can proceed. |
| **Phase 3: App Lifecycle** | ❌ Requires understanding wxFFI's ELJApp internals and testing the event loop. Closure creation patterns are subtle and need verification. |
| **Phase 4: Window/Frame** | ❌ First use of the type hierarchy. Design decisions here affect all widget implementations. |
| **Phase 5: Event Handling** | ❌ **Most complex phase.** GC safety, `@cfunction` usage, and closure lifetime are tricky. Requires careful iteration and testing. |
| **Phase 6: Common Controls** | ⚠️ **Partially suitable.** Once Phase 5 patterns are established, individual control wrappers (Button, TextCtrl, etc.) could be farmed out. However, the first few controls should be done locally to establish patterns. |
| **Phase 8: Testing & Examples** | ❌ Requires running Julia with the actual wxFFI library to verify behavior. |

### Recommended Workflow

1. **Local**: Complete Phases 1, 3, 4, 5 to establish all core patterns
2. **GitHub Issue**: Assign Phase 2 (constants generation) — can run in parallel with Phase 1
3. **Local**: Complete first 2-3 controls in Phase 6 to establish widget patterns
4. **GitHub Issue**: Assign remaining Phase 6 controls (StaticText, CheckBox, ComboBox, ListBox)
5. **GitHub Issue**: Assign Phase 7 (sizers) once Phase 4/6 patterns are clear
6. **Local**: Phase 8 testing and integration

### Issue Template for Phase 2 (Constants)

```markdown
## Task: Generate Julia constants from wxFFI headers

Parse `external/wxFFI/include/wxffi_glue.h` and generate:
- `src/core/constants.jl` - All `expwx*()` style/ID constants
- `src/core/events.jl` - All `expEVT_*()` event type constants

### Pattern to follow:
```julia
# In constants.jl
const wxDEFAULT_FRAME_STYLE = Ref{Cint}(0)

function load_constants!()
    wxDEFAULT_FRAME_STYLE[] = @ccall libwxffi[].expwxDEFAULT_FRAME_STYLE()::Cint
end
```

### Requirements:
1. Extract all function names matching `exp[A-Z].*\(\)` from wxffi_glue.h
2. Generate Ref{Cint} constants with appropriate Julia names
3. Generate load_constants!() function that populates all values
4. Separate style constants from event constants into two files
```

---

*Plan created: January 23, 2026*
