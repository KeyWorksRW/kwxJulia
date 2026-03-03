# kwxJulia Examples

This directory contains example applications demonstrating the kwxJulia binding to wxWidgets.

## Prerequisites

Before running the examples, ensure:
1. The project has been built: `ninja -C build -f build-Release.ninja`
2. The shared libraries exist in `bin/Release/` (or `bin/Debug/`)
3. Julia 1.10+ is installed

## Library Path

The `WxWidgets` module automatically adds `bin/Release/` to Julia's DLL search path
in its `__init__()` function. No manual path configuration is needed.

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
- Check that `kwxFFI.dll` exists in `bin/Release/`
- Ensure all dependencies are present

### Window hangs or crashes
- Don't run examples from `key_term` or automated terminals
- Use a separate PowerShell/terminal window
- Or run via VS Code debugger with proper launch configuration

### Library not found
- The module automatically adds `bin/Release/` to the DLL search path
- Verify the DLL was built: `ninja -C build -f build-Release.ninja`

## Running from REPL

You can also run examples from the Julia REPL:

```julia
# Navigate to project directory
cd("C:/rwCode/wxLanguages/kwxJulia-dev")

# Add project root to load path
push!(LOAD_PATH, ".")

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
