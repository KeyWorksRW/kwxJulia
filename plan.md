# Julia wxWidgets Binding Implementation Plan

## Project Overview

**Goal**: Create a Julia binding (`kwxJulia`) to the wxWidgets GUI library via the kwxFFI C interface.

**Architecture**: Julia → kwxJulia helper DLL (kwxApp) → kwxFFI (C interface) → wxWidgets (C++)

This binding will enable Julia developers to build native cross-platform desktop GUI applications using wxWidgets, leveraging Julia's built-in `@ccall` macro and `Libdl` module for FFI.

---

## Prerequisites & Dependencies

### Build Requirements
- **Julia 1.10+** (LTS; improved ccall performance)
- **CMake 3.30+** (FetchContent performance improvements, CMP0168)
- **C/C++ compiler** (MSVC on Windows, GCC/Clang on Linux/macOS)
- **Ninja** build system (Multi-Config generator)
- wxWidgets 3.3.1+ and kwxFFI are fetched automatically via FetchContent

### Julia Development Tools
| Tool | Purpose |
|------|---------|
| Julia REPL | Interactive development and testing |
| VS Code + Julia Extension | IDE with language server support |
| Pkg.jl | Package management (built-in) |
| Test.jl | Unit testing framework (stdlib) |

### Build System

Unlike the original plan which assumed prebuilt libraries, kwxJulia requires a CMake build step to:
1. Fetch kwxFFI and wxWidgets source code via FetchContent
2. Build kwxFFI as a shared library (`kwxffi.dll`)
3. Build a helper shared library (`kwxjulia.dll`) containing kwxApp.cpp + Julia-specific trampolines
4. Both DLLs are placed in `bin/<Config>/` for Julia to load at runtime

The CMakeLists.txt follows the same FetchContent pattern as kwxFortran. See `CMakeLists.txt` in kwxFortran-dev as the template.

---

## Architecture Design

### Layer Structure

```
┌─────────────────────────────────────────────────┐
│              User Application                    │
│         (Idiomatic Julia GUI code)              │
├─────────────────────────────────────────────────┤
│         High-Level API (src/widgets/)           │
│    WxButton, WxFrame, WxTextCtrl, etc.          │
│    - Julian naming conventions                  │
│    - Automatic resource management              │
│    - Event handling via closures                │
├─────────────────────────────────────────────────┤
│         Core Module (src/core/)                 │
│    - Library loading (Libdl)                    │
│    - Type definitions                           │
│    - String conversion (wxString ↔ String)      │
│    - Constants/enums                            │
│    - Event connection helpers                   │
├─────────────────────────────────────────────────┤
│         FFI Declarations (src/ffi/)             │
│    - Raw @ccall wrappers                        │
│    - 1:1 mapping to kwxFFI + kwxJulia functions │
├─────────────────────────────────────────────────┤
│     kwxjulia.dll          │    kwxffi.dll       │
│  (kwxApp lifecycle,       │  (wxWidgets C       │
│   event trampolines)      │   wrapper funcs)    │
├───────────────────────────┴─────────────────────┤
│              wxWidgets (static libs)            │
└─────────────────────────────────────────────────┘
```

### Key Architectural Decision: Two Shared Libraries

Julia loads shared libraries at runtime via `Libdl.dlopen`. Unlike Fortran which can statically link, Julia needs everything in DLLs:

- **`kwxffi.dll`** — All wxWidgets wrapper functions (`wxButton_Create`, `wxFrame_Create`, `wxString_CreateUTF8`, `wxClosure_Create`, etc.)
- **`kwxjulia.dll`** — App lifecycle (`kwxApp_Initialize`, `kwxApp_MainLoop`), event connection helper (`kwxApp_Connect`), and Julia-specific trampolines

Both are built by CMake and placed in `bin/<Config>/`.

### Package Structure

```
kwxJulia-dev/
├── CMakeLists.txt             # Build system (FetchContent for kwxFFI + wxWidgets)
├── CMakePresets.json          # Ninja Multi-Config preset
├── src/
│   ├── cpp/
│   │   └── kwxApp.cpp         # C++ helper: app lifecycle + event trampolines
│   ├── WxWidgets.jl           # Main module entry point
│   ├── core/
│   │   ├── library.jl         # Library loading via Libdl
│   │   ├── types.jl           # Julia type definitions for wxFFI types
│   │   ├── strings.jl         # wxString <-> Julia String conversion
│   │   ├── constants.jl       # wxWidgets constants (from defs.cpp exp* functions)
│   │   └── events.jl          # Event type constants and connection helpers
│   ├── ffi/
│   │   ├── app.jl             # kwxApp_* FFI declarations
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
│   ├── minimal.jl             # Minimal empty window
│   ├── hello_world.jl         # Frame with button
│   └── controls_demo.jl       # Controls demonstration
├── bin/                       # Built DLLs (kwxffi.dll, kwxjulia.dll)
│   ├── Debug/
│   └── Release/
├── build/                     # CMake build directory
├── Project.toml               # Julia package manifest
└── README.md
```

---

## Implementation Phases

### Phase 0: Build System (CMakeLists.txt + kwxApp.cpp)

**Objective**: Create the CMake build that fetches dependencies and produces the two shared libraries Julia needs.

**Files to create**:
- `CMakeLists.txt` — FetchContent for kwxFFI/wxWidgets, shared library targets
- `CMakePresets.json` — Ninja Multi-Config preset
- `src/cpp/kwxApp.cpp` — Copied and adapted from kwxFFI `examples/CApp/kwxApp.cpp`

**CMakeLists.txt key structure** (modeled on kwxFortran):

```cmake
cmake_minimum_required(VERSION 3.30)
project(kwxJulia LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED True)

include(FetchContent)
set(FETCHCONTENT_QUIET ON)

FetchContent_Declare(kwxFFI
    GIT_REPOSITORY https://github.com/KeyWorksRW/kwxFFI.git
    GIT_TAG origin/main
    GIT_SHALLOW TRUE
    UPDATE_DISCONNECTED FALSE
)
FetchContent_MakeAvailable(kwxFFI)

# Override kwxFFI output to bin/
set_target_properties(kwxFFI PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin/$<CONFIG>"
    LIBRARY_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin/$<CONFIG>"
    RUNTIME_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin/$<CONFIG>"
)

# Julia helper shared library (kwxApp lifecycle + trampolines)
add_library(kwxjulia SHARED src/cpp/kwxApp.cpp)
target_compile_definitions(kwxjulia PRIVATE KWXJULIA_EXPORTS)
target_link_libraries(kwxjulia PRIVATE kwxFFI wxbase wxcore)

# Include wxWidgets headers
set(WX_SRC_DIR ${CMAKE_BINARY_DIR}/_deps/wxwidgets-src)
set(WX_BUILD_DIR ${CMAKE_BINARY_DIR}/_deps/wxwidgets-build)
target_include_directories(kwxjulia PRIVATE ${WX_SRC_DIR}/include)
# Platform-specific setup.h location (Windows/Linux/macOS)

set_target_properties(kwxjulia PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin/$<CONFIG>"
    LIBRARY_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin/$<CONFIG>"
)
```

**kwxApp.cpp adaptation for Julia**:
- Copy from kwxFFI `examples/CApp/kwxApp.cpp`
- Change export macro from `KWXFORTRAN_EXPORTS` → `KWXJULIA_EXPORTS`
- Include `kwxApp_Connect` trampoline for event handling (same pattern as Fortran)
- The trampoline wraps Julia's `@cfunction` pointer + data in a wxClosure, handling the null-event cleanup from `~wxClosure`

**Verification**:
- `cmake --preset ninja-multi` configures successfully
- `ninja -C build -f build-Debug.ninja` builds both DLLs
- `bin/Debug/kwxffi.dll` and `bin/Debug/kwxjulia.dll` exist

---

### Phase 1: Foundation (Core Infrastructure) ✅

**Objective**: Establish library loading, type system, and string handling.

**Files to create**:
- `src/WxWidgets.jl` — Main module
- `src/core/library.jl` — Library loading via Libdl
- `src/core/types.jl` — Base type definitions
- `src/core/strings.jl` — wxString conversion utilities
- `Project.toml` — Package configuration

**Key implementation details**:

```julia
# Library loading — two DLLs
const libwxffi = Ref{Ptr{Cvoid}}(C_NULL)
const libkwxjulia = Ref{Ptr{Cvoid}}(C_NULL)

function __init__()
    # Default search: bin/Release/ next to the package, or KWXJULIA_LIB_PATH env
    libdir = get(ENV, "KWXJULIA_LIB_PATH", default_lib_path())

    @static if Sys.iswindows()
        libwxffi[] = Libdl.dlopen(joinpath(libdir, "kwxffi.dll"))
        libkwxjulia[] = Libdl.dlopen(joinpath(libdir, "kwxjulia.dll"))
    elseif Sys.isapple()
        libwxffi[] = Libdl.dlopen(joinpath(libdir, "libkwxffi.dylib"))
        libkwxjulia[] = Libdl.dlopen(joinpath(libdir, "libkwxjulia.dylib"))
    else
        libwxffi[] = Libdl.dlopen(joinpath(libdir, "libkwxffi.so"))
        libkwxjulia[] = Libdl.dlopen(joinpath(libdir, "libkwxjulia.so"))
    end

    load_constants!()
end
```

```julia
# wxString creation using kwxFFI's wxString_CreateUTF8
struct WxString
    ptr::Ptr{Cvoid}
end

function WxString(s::AbstractString)
    ptr = @ccall libwxffi[].wxString_CreateUTF8(s::Cstring)::Ptr{Cvoid}
    WxString(ptr)
end

# Extract content — wxString_GetUtf8 returns wxCharBuffer*
# Then get the C string from the buffer, copy it, and free the buffer
function Base.String(ws::WxString)
    buf = @ccall libwxffi[].wxString_GetUtf8(ws.ptr::Ptr{Cvoid})::Ptr{Cvoid}
    # wxCharBuffer contains the utf8 data — need to extract and free
    # Use wxString_GetString as a simpler alternative if buffer approach is complex
    # (This needs investigation against actual kwxFFI API)
    cstr = unsafe_string(Ptr{UInt8}(buf))
    result = String(cstr)
    result
end

function delete!(ws::WxString)
    @ccall libwxffi[].wxString_Delete(ws.ptr::Ptr{Cvoid})::Cvoid
end
```

**⚠️ Note**: The exact `wxString_GetUtf8` return type (`wxCharBuffer*`) needs investigation. The Fortran binding handles this differently. May need a helper function in kwxApp.cpp that returns a `char*` from a `wxString*`:

```cpp
// In kwxApp.cpp — helper to simplify string extraction for Julia
KWXAPP_API const char* kwxApp_WxStringToUTF8(wxString* s)
{
    // Returns internal buffer — caller must copy before deleting the wxString
    return s->utf8_str();
}
```

**Verification**:
- Library loads successfully on Windows
- String round-trip: `String(WxString("test")) == "test"`

---

### Phase 2: Constants and Event Types ✅

**Objective**: Export wxWidgets constants and event type identifiers.

**Files to create**:
- `src/core/constants.jl` — Style flags, IDs, etc.
- `src/core/events.jl` — Event type constants

**Approach**: Call the `exp*()` functions from kwxFFI's `defs.cpp`:

```julia
# Constants loaded at init time via Ref{Cint}
const wxDEFAULT_FRAME_STYLE = Ref{Cint}(0)
const wxTE_MULTILINE = Ref{Cint}(0)
const wxID_ANY = Ref{Cint}(0)

function load_constants!()
    wxDEFAULT_FRAME_STYLE[] = @ccall libwxffi[].expwxDEFAULT_FRAME_STYLE()::Cint
    wxTE_MULTILINE[] = @ccall libwxffi[].expwxTE_MULTILINE()::Cint
    wxID_ANY[] = @ccall libwxffi[].expwxID_ANY()::Cint
    # ... hundreds more ...
end
```

**Generation strategy**: Parse `wxffi_glue.h` for all `exp*()` function declarations and auto-generate `constants.jl` and `events.jl`. This is a mechanical task well-suited for subagent delegation.

**⚠️ Subagent candidate**: This phase is ideal for GPT-4.1 — bounded, mechanical, no runtime testing needed. Input: the `wxffi_glue.h` header. Output: two Julia files.

---

### Phase 3: Application Lifecycle ✅

**Objective**: Implement WxApp wrapper using the kwxApp C interface.

**Files to create**:
- `src/ffi/app.jl` — Raw FFI for kwxApp_* functions
- `src/widgets/app.jl` — High-level WxApp

**Key functions to wrap** (from `kwxApp.h`):

| C Function | Purpose |
|-----------|---------|
| `kwxApp_Initialize(argc, argv)` | Initialize wxWidgets — call once before any wx functions |
| `kwxApp_MainLoop()` | Run event loop — blocks until exit |
| `kwxApp_ExitMainLoop()` | Signal event loop to exit |
| `kwxApp_Shutdown()` | Optional cleanup |
| `kwxApp_SetAppName(name)` | Set app name (const char*) |
| `kwxApp_SetTopWindow(window)` | Set top-level window |
| `kwxApp_SetExitOnFrameDelete(flag)` | Control exit behavior |
| `kwxApp_InitAllImageHandlers()` | Enable PNG, JPEG, etc. |

```julia
# FFI declarations — these call into kwxjulia.dll (not kwxffi.dll)
function kwxapp_initialize()
    @ccall libkwxjulia[].kwxApp_Initialize(0::Cint, C_NULL::Ptr{Ptr{Cchar}})::Cint
end

function kwxapp_mainloop()
    @ccall libkwxjulia[].kwxApp_MainLoop()::Cint
end

function kwxapp_exit()
    @ccall libkwxjulia[].kwxApp_ExitMainLoop()::Cvoid
end

# High-level API
function run_app(setup::Function)
    result = kwxapp_initialize()
    result == 0 && error("Failed to initialize wxWidgets")

    setup()  # User creates windows, connects events

    kwxapp_mainloop()
end
```

**Note**: Unlike the old plan which referenced `ELJApp_InitializeC` (wxHaskell-era API), this uses the modern `kwxApp_*` C interface from `kwxApp.h`.

**Verification**:
- `kwxApp_Initialize` returns non-zero (success)
- `kwxApp_MainLoop` doesn't crash with an empty app (exits immediately if no top window)

---

### Phase 4: Window and Frame ✅

**Objective**: Implement wxWindow base and wxFrame for top-level windows.

**Files to create**:
- `src/ffi/window.jl` — wxWindow FFI
- `src/ffi/frame.jl` — wxFrame FFI
- `src/widgets/window.jl` — High-level Window
- `src/widgets/frame.jl` — High-level Frame

**Type hierarchy**:

```julia
abstract type WxObject end
abstract type WxEvtHandler <: WxObject end
abstract type WxWindow <: WxEvtHandler end
abstract type WxControl <: WxWindow end

mutable struct WxFrame <: WxWindow
    ptr::Ptr{Cvoid}
    children::Vector{Any}    # prevent GC of child widgets
    closures::Vector{Any}    # prevent GC of event closures
end

function WxFrame(parent::Union{WxWindow,Nothing}, title::String;
                 id::Int = wxID_ANY[],
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

    delete!(title_ws)
    WxFrame(ptr, Any[], Any[])
end
```

**Verification**:
- Create a frame, set it as top window, main loop runs and shows window

---

### Phase 5: Event Handling ✅

**Objective**: Implement event connection using `kwxApp_Connect` from the helper DLL.

**Key insight**: The `kwxApp_Connect` function (in `kwxApp.cpp`) handles the complexity of wrapping a foreign function pointer + user data in a wxClosure with proper cleanup. Julia does NOT need to call `wxClosure_Create` directly — the trampoline in `kwxApp.cpp` does this.

```julia
# Julia @cfunction for event callbacks must match ClosureFun signature:
#   void(void* fun, void* data, void* evt)

function wx_connect!(window::WxWindow, event_type::Integer, handler::Function;
                     id::Int = -1, last_id::Int = id)
    # Create a C-callable wrapper around the Julia closure
    function c_handler(fun::Ptr{Cvoid}, data::Ptr{Cvoid}, evt::Ptr{Cvoid})::Cvoid
        try
            if evt != C_NULL
                handler(WxEvent(evt))
            end
        catch e
            @error "Exception in event handler" exception=(e, catch_backtrace())
        end
        nothing
    end

    cfun = @cfunction($c_handler, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}))

    # kwxApp_Connect wraps cfun+data in a trampoline closure that handles
    # the null-event cleanup from ~wxClosure
    @ccall libkwxjulia[].kwxApp_Connect(
        window.ptr::Ptr{Cvoid},
        id::Cint,
        last_id::Cint,
        event_type::Cint,
        cfun::Ptr{Cvoid},
        C_NULL::Ptr{Cvoid}    # user_data (unused — Julia closure captures state)
    )::Cint

    # Prevent GC of the @cfunction
    push!(window.closures, cfun)
end
```

**Important GC safety**:
- `@cfunction($handler, ...)` with the `$` interpolation creates a runtime closure — this **must** be kept alive
- Store the `cfun` reference in `window.closures` to prevent GC
- The try-catch in the C callback prevents Julia exceptions from propagating into C (which would crash)

**Verification**:
- Connect a button click handler, click the button, handler fires
- Close the window — no crash during cleanup

---

### Phase 6: Common Controls ✅

**Objective**: Wrap frequently used controls.

**Priority controls**:
1. `wxButton` — Command button
2. `wxStaticText` — Label
3. `wxTextCtrl` — Text input/editor
4. `wxCheckBox` — Check box
5. `wxComboBox` — Drop-down selection
6. `wxListBox` — List selection

**Example — wxButton**:

```julia
mutable struct WxButton <: WxControl
    ptr::Ptr{Cvoid}
    closures::Vector{Any}    # prevent GC of event closures
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
    btn = WxButton(ptr, Any[])
    push!(parent.children, btn)
    btn
end

# Convenience: on_click! uses the button-clicked event type
function on_click!(button::WxButton, handler::Function)
    wx_connect!(button, KwxFFI.wxEVT_BUTTON(), handler)
end
```

**⚠️ Subagent candidate**: After Phase 5 establishes the event pattern and Phase 6 creates the first 2-3 controls locally, remaining controls can be delegated to GPT-4.1 or Raptor (provide the established pattern + wxffi_glue.h signatures).

---

### Phase 7: Layout Sizers ✅

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
              proportion::Int = 0, flags::Int = 0, border::Int = 0)
    @ccall libwxffi[].wxSizer_Add(
        sizer.ptr::Ptr{Cvoid},
        window.ptr::Ptr{Cvoid},
        proportion::Cint,
        flags::Cint,
        border::Cint
    )::Ptr{Cvoid}
end

function set_sizer!(window::WxWindow, sizer::WxSizer; delete_old::Bool = true)
    @ccall libwxffi[].wxWindow_SetSizer(
        window.ptr::Ptr{Cvoid},
        sizer.ptr::Ptr{Cvoid},
        delete_old::Cint
    )::Cvoid
end
```

**⚠️ Subagent candidate**: Sizer wrappers are straightforward FFI calls — good for GPT-4.1 after patterns are established.

---

### Phase 8: Testing & Examples ✅

**Objective**: Tests and example applications that mirror kwxFortran's examples.

**Example applications** (matching kwxFortran):
1. `minimal.jl` — Empty window demonstrating basic app lifecycle
2. `hello_world.jl` — Frame with button and event handling
3. `controls_demo.jl` — Multiple controls with sizer layout

**Minimal example**:

```julia
using WxWidgets

function main()
    run_app() do
        frame = WxFrame(nothing, "Minimal Julia wxWidgets";
                        size=(400, 300))

        wx_set_app_name("Minimal Julia App")
        wx_set_top_window(frame)

        wx_frame_create_status_bar(frame)
        wx_frame_set_status_text(frame, "Welcome to kwxJulia!")

        show!(frame)
    end
end

main()
```

**Test categories**:
1. String conversion round-trips
2. Constants loaded correctly (non-zero values)
3. Widget creation doesn't crash
4. Event handler fires on simulated events

---

## Type Mapping Reference

| kwxFFI C Type | Julia Type | Notes |
|---------------|------------|-------|
| `void*` (TClass) | `Ptr{Cvoid}` | Opaque pointer to wxWidgets object |
| `int` | `Cint` (Int32) | |
| `bool` / `TBool` | `Cint` (0/1) | kwxFFI uses int for booleans |
| `const char*` | `Cstring` | For input strings (kwxApp functions) |
| `wxString*` | Custom `WxString` wrapper | For kwxFFI widget functions |
| `TPoint(x,y)` | Two `Cint` arguments | Decomposed in FFI signatures |
| `TSize(w,h)` | Two `Cint` arguments | Decomposed in FFI signatures |
| `TRect(x,y,w,h)` | Four `Cint` arguments | Decomposed in FFI signatures |
| `ClosureFun` | `Ptr{Cvoid}` from `@cfunction` | `void(void*, void*, void*)` |

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| GC collects `@cfunction` while C holds reference | **High** | Store in `closures::Vector{Any}` on parent widget; prevent GC |
| wxString memory leaks | Medium | Explicit `delete!(ws)` after extracting content; document pattern |
| `@cfunction` exception crashes app | **High** | Wrap all C callbacks in `try-catch`; log errors; never throw to C |
| Thread safety | Medium | Document single-threaded requirement; wxWidgets main thread only |
| Library path discovery | Medium | `KWXJULIA_LIB_PATH` env override; default search relative to package |
| CMake FetchContent slow first build | Low | Document ~10 min first build; subsequent builds use cache |
| wxString_GetUtf8 returns wxCharBuffer* | Medium | Add helper in kwxApp.cpp if needed; test in Phase 1 |

---

## Verification Strategy

### Phase Verification
After each phase:
1. DLLs build cleanly: `ninja -C build -f build-Debug.ninja`
2. Julia code loads without errors: `using WxWidgets`
3. Phase-specific tests pass

### Final Verification
1. All examples run on Windows (primary platform)
2. Memory: run examples in a loop, check no steady growth
3. Event handlers fire correctly and don't crash on cleanup

---

## Timeline Estimate

| Phase | Estimated Agent-Hours | Subagent? |
|-------|----------------------|-----------|
| Phase 0: Build System ✅ | 0.5-1 | No — establishes build infrastructure |
| Phase 1: Foundation ✅ | 1-2 | No — core patterns, needs runtime testing |
| Phase 2: Constants ✅ | 0.5 | **Yes** — GPT-4.1 can generate from header |
| Phase 3: App Lifecycle ✅ | 1 | No — needs runtime testing |
| Phase 4: Window/Frame ✅ | 1-2 | No — establishes widget patterns |
| Phase 5: Events ✅ | 1-2 | No — GC safety is subtle |
| Phase 6: Controls ✅ | 1-2 | **Partial** — establish pattern locally, then delegate remaining |
| Phase 7: Sizers ✅ | 0.5-1 | **Yes** — mechanical FFI wrapping |
| Phase 8: Testing ✅ | 1-2 | No — needs runtime verification |
| **Total** | **8-13** | |

---

## Subagent Delegation Strategy

### Tasks Suitable for Subagents (GPT-4.1 or Raptor)

| Task | Agent | Input | Output |
|------|-------|-------|--------|
| Phase 2: Generate constants | GPT-4.1 | `wxffi_glue.h`, pattern template | `constants.jl`, `events.jl` |
| Phase 6: Remaining controls | GPT-4.1 | Established pattern + glue.h signatures | Individual control .jl files |
| Phase 7: Sizer wrappers | GPT-4.1 | Established pattern + glue.h signatures | `sizers.jl` |

### Tasks Requiring Local Agent
- Phases 0, 1, 3, 4, 5 — establish patterns, need build/runtime testing
- Phase 8 — requires running Julia with actual DLLs
- First 2-3 controls in Phase 6 — establish the widget wrapper pattern

---

## Project Status

**ALL PHASES COMPLETE** ✅

The kwxJulia binding implementation is complete. All 9 phases (0-8) have been successfully implemented.

### Completed
- ✅ Phase 0: Build System (CMakeLists.txt + kwxApp.cpp)
- ✅ Phase 1: Foundation (Core infrastructure)
- ✅ Phase 2: Constants and Event Types
- ✅ Phase 3: Application Lifecycle
- ✅ Phase 4: Window and Frame
- ✅ Phase 5: Event Handling
- ✅ Phase 6: Common Controls
- ✅ Phase 7: Layout Sizers
- ✅ Phase 8: Testing & Examples

### Next Steps for Users

1. **Build the project**: `ninja -C build -f build-Release.ninja`
2. **Run examples**: `julia examples\minimal.jl`
3. **Run tests**: `julia test\runtests.jl`
4. **Review documentation**: See `examples/README.md` and `test/README.md`
5. **Create your own GUI apps**: Use examples as templates

See `PHASE8_COMPLETE.md` for detailed Phase 8 implementation summary.

---

*Plan completed: February 8, 2026*
*Plan updated: February 7, 2026*
*Previous version: January 23, 2026*
