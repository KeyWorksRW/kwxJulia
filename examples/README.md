# kwxJulia Examples

This directory contains example applications demonstrating the kwxJulia binding to wxWidgets.

## Prerequisites

Before running the examples, ensure:
1. The project has been built: `ninja -C build -f build-Release.ninja`
2. The shared libraries exist in `bin/Release/` (or `bin/Debug/`)
3. Julia 1.10+ is installed

## Setting Library Path

By default, examples load libraries from `bin/Release/`. To use a different location:

```powershell
$env:KWXJULIA_LIB_PATH = "C:\path\to\bin\Release"
julia examples\minimal.jl
```

## Examples

### minimal.jl
The simplest possible kwxJulia application - an empty window with a status bar.

```powershell
julia examples\minimal.jl
```

Demonstrates:
- Basic app lifecycle with `run_app`
- Creating a frame (top-level window)
- Setting up a status bar
- Window display

### hello_world.jl
Classic "Hello World" with a button and event handling.

```powershell
julia examples\hello_world.jl
```

Demonstrates:
- Button creation
- Event handler connection with closures
- Sizer-based layout
- Status bar updates
- State management with Julia Refs

### controls_demo.jl
Comprehensive demonstration of multiple controls and layout.

```powershell
julia examples\controls_demo.jl
```

Demonstrates:
- Multiple control types (Button, TextCtrl, CheckBox, StaticText)
- Multi-line text input
- Complex sizer layouts (vertical and horizontal)
- Event handlers on various controls
- Form-style UI with submit/clear actions

## Troubleshooting

### "Failed to initialize wxWidgets"
- Check that `kwxffi.dll` and `kwxjulia.dll` exist in the library path
- Verify the DLLs were built for the correct architecture (x64)
- Ensure all dependencies are present

### Window hangs or crashes
- Don't run examples from `key_term` or automated terminals
- Use a separate PowerShell/terminal window
- Or run via VS Code debugger with proper launch configuration

### Library not found
- Set `KWXJULIA_LIB_PATH` environment variable
- Or copy DLLs to a location in your system PATH
- Check that you're pointing to the correct build config (Debug vs Release)

## Running from REPL

You can also run examples from the Julia REPL:

```julia
# Navigate to project directory
cd("C:/rwCode/wxLanguages/kwxJulia-dev")

# Add src to load path
push!(LOAD_PATH, "src")

# Run example
include("examples/minimal.jl")
```

## Modifying Examples

All examples use `push!(LOAD_PATH, ...)` to find the `WxWidgets` module. When creating your own applications, you can either:
1. Use the same pattern for development
2. Install kwxJulia as a proper Julia package (via `Pkg.develop()`)
3. Set `JULIA_LOAD_PATH` environment variable

## Next Steps

After exploring these examples:
- Review `src/widgets/` for available high-level APIs
- Check `test/` for unit tests demonstrating specific features
- Refer to wxWidgets documentation for control capabilities
- Create your own GUI applications!
