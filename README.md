# kwxJulia

Julia language bindings for [wxWidgets](https://www.wxwidgets.org/) via [kwxFFI](https://github.com/KeyWorksRW/kwxFFI), enabling cross-platform GUI applications that render with native controls on Windows, macOS, and Linux.

The Julia package name is `WxWidgets` — use `using WxWidgets` to load it.

## ⚠️ Warning: Not Production Ready

**Do not use this Julia/wxWidgets interface in production.**

- The kwxFFI ABI interface is **not stable** and can change without warning.
- Very little testing has been done, and won't be until late Q2 of 2026.
- API surface may change as idioms are refined.

## Overview

kwxJulia is generated code plus a small application layer.  `kwxgen` emits the
entire wxWidgets surface into `wx/`; there is no hand-written widget wrapper
layer.

1. **Raw FFI** (`wx/KwxFFI_gen.jl`) — auto-generated `ccall` declarations mapping directly to the kwxFFI C DLL exports. All pointers are `Ptr{Cvoid}`.
2. **Generated runtime** (`wx/types_gen.jl`, `wx/wxstring_gen.jl`, `wx/wx_structs_gen.jl`, `wx/wx_idiomatic_gen.jl`) — the abstract type hierarchy, `wxString` lifecycle, `_wx_wrap`, and the per-class structs with their full constructor and method set. `wx/wx_exports_gen.jl` exports the whole public surface.
3. **Application layer** (`src/core/kwxapp.jl`) — the only hand-written Julia: the GUI lifecycle (`run_app`, `exit_app`, `set_top_window`), backed by `src/cpp/kwxApp.cpp`, and the event bridge that turns a Julia handler into a generated `wxClosure`.

Users work with the generated class API.  The FFI layer (`KwxFFI` submodule) is exported for direct access to constants and event types.

## Quick Example

```julia
push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

run_app(app_name="Hello World") do
    frame = wxFrame(nothing, KwxFFI.ID_ANY(), "Hello World - kwxJulia",
                    -1, -1, 400, 300, KwxFFI.DEFAULT_FRAME_STYLE())

    create_status_bar(frame, 1, 0, KwxFFI.ID_ANY())
    set_status_text!(frame, "Click the button!", 0)

    button = wxButton(frame, KwxFFI.ID_ANY(), "Say Hello", -1, -1, 120, 40, 0)

    wx_connect!(button, KwxFFI.EVT_BUTTON()) do event
        set_status_text!(frame, "Hello from Julia!", 0)
    end

    sizer = wxBoxSizer(KwxFFI.VERTICAL())
    add_window!(sizer, button, 0, KwxFFI.ALL() | KwxFFI.ALIGN_CENTER(), 5, C_NULL)
    set_sizer!(frame, sizer, true)

    set_top_window(frame)
    show(frame)
end
```

More examples are in the [`examples/`](examples/) directory.

## Type Hierarchy

Types mirror the wxWidgets C++ class hierarchy using Julia abstract types:

```
wxObject
├── wxEvtHandler
│   └── wxWindow
│       ├── wxControl (wxButton, wxStaticText, wxTextCtrl, wxCheckBox, wxComboBox, wxListBox)
│       └── wxTopLevelWindow (wxFrame)
└── wxSizer (wxBoxSizer, wxGridSizer, wxFlexGridSizer, wxGridBagSizer, wxWrapSizer)
```

This enables idiomatic multiple dispatch — e.g., `show` and `set_label!` work on any `wxWindow` subtype.

## Naming Conventions

Types use the `wx` lowercase prefix (matching C++ wxWidgets) rather than Julia's conventional `Wx` PascalCase. This makes it straightforward for wxWidgets developers to map between the Julia and C++ APIs.

| Entity             | Convention   | Example                                                |
| ------------------ | ------------ | ------------------------------------------------------ |
| Types              | `wx` prefix  | `wxFrame`, `wxButton`                                  |
| Constructors       | C++ argument order | `wxFrame(parent, id, text, x, y, w, h, style)`  |
| Methods            | `snake_case` | `set_status_text!(frame, "text", 0)`                   |
| Mutating functions | trailing `!` | `set_value!(ctrl, "text")`, `clear!(ctrl)`            |
| Constants / events | Via `KwxFFI` | `KwxFFI.ALL()`, `KwxFFI.ID_ANY()`, `KwxFFI.EVT_BUTTON()` |

## Requirements

- **Julia** 1.10 or later
- **kwxFFI** shared library (`kwxffi.dll` / `libkwxffi.so` / `libkwxffi.dylib`) from [KeyWorksRW/kwxFFI](https://github.com/KeyWorksRW/kwxFFI)

### Building kwxFFI

Building kwxFFI requires:

- A C/C++ toolchain with **C++17** support (MSVC, GCC, or Clang)
- **CMake** 3.20 or later
- **Ninja** build system

Configure and build:

```sh
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
ninja -C build
```

A release build will be placed in `bin/Release/` relative to the kwxJulia package root. This path is added to `Libdl.DL_LOAD_PATH` automatically at module init.

> **Note:** Once GitHub Actions CI is in place, pre-built binaries will be available as release assets — eliminating the need to build kwxFFI from source.

## License

Apache License 2.0 — see [LICENSE](LICENSE) for details.
