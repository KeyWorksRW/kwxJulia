# kwxJulia

Julia language bindings for [wxWidgets](https://www.wxwidgets.org/) via [kwxFFI](https://github.com/KeyWorksRW/kwxFFI), enabling cross-platform GUI applications that render with native controls on Windows, macOS, and Linux.

The Julia package name is `WxWidgets` — use `using WxWidgets` to load it.

## ⚠️ Warning: Not Production Ready

**Do not use this Julia/wxWidgets interface in production.**

- The kwxFFI ABI interface is **not stable** and can change without warning.
- Very little testing has been done, and won't be until late Q2 of 2026.
- API surface may change as idioms are refined.

## Overview

kwxJulia provides a two-layer binding architecture:

1. **FFI Layer** (`wx/KwxFFI_gen.jl`) — Auto-generated raw `ccall` declarations mapping directly to the kwxFFI C DLL exports. All pointers are `Ptr{Cvoid}`.
2. **Widget Layer** (`src/widgets/*.jl`) — Idiomatic Julia wrappers with proper types, keyword arguments, multiple dispatch, and automatic string conversion.

Users should work with the widget layer. The FFI layer (`KwxFFI` submodule) is exported for direct access to constants and event types.

## Quick Example

```julia
push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using WxWidgets

run_app(app_name="Hello World") do
    frame = wxFrame(nothing, "Hello World - kwxJulia", size=(400, 300))

    create_status_bar(frame)
    set_status_text(frame, "Click the button!")

    button = wxButton(frame, "Say Hello", size=(120, 40))

    on_click!(button) do event
        set_status_text(frame, "Hello from Julia!")
    end

    sizer = wxBoxSizer(:vertical)
    add!(sizer, button,
         proportion=0,
         flags=KwxFFI.ALL() | KwxFFI.ALIGN_CENTER(),
         border=5)
    set_sizer(frame, sizer)

    set_top_window(frame)
    show_window(frame)
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

This enables idiomatic multiple dispatch — e.g., `show_window` works on any `wxWindow` subtype.

## Naming Conventions

Types use the `wx` lowercase prefix (matching C++ wxWidgets) rather than Julia's conventional `Wx` PascalCase. This makes it straightforward for wxWidgets developers to map between the Julia and C++ APIs.

| Entity             | Convention   | Example                                    |
| ------------------ | ------------ | ------------------------------------------ |
| Types              | `wx` prefix  | `wxFrame`, `wxButton`                      |
| Constructors       | Type name    | `wxFrame(nothing, "title")`                |
| Methods            | `snake_case` | `set_status_text(frame, "text")`           |
| Mutating functions | trailing `!` | `set_value!(ctrl, "text")`, `clear!(ctrl)` |
| Constants / events | Via `KwxFFI` | `KwxFFI.ALL()`, `KwxFFI.ID_ANY()`          |

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
