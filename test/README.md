# kwxJulia Tests

This directory contains unit tests for the kwxJulia binding.

## Running Tests

### Run All Tests

```powershell
cd C:\rwCode\wxLanguages\kwxJulia-dev
julia test\runtests.jl
```

### Run Specific Test File

```julia
# From project root
push!(LOAD_PATH, "src")
include("test/test_strings.jl")
```

## Test Files

### test_strings.jl
Tests wxString ↔ Julia String conversion.

**Coverage:**
- Basic ASCII strings
- UTF-8 with Unicode characters
- Empty strings
- Special characters (newlines, tabs)
- Long strings
- Convert function interface

**Critical:** String conversion is the foundation of the FFI - all widget functions use wxString.

### test_constants.jl
Verifies that wxWidgets constants are loaded correctly.

**Coverage:**
- Frame style flags (wxDEFAULT_FRAME_STYLE)
- ID constants (wxID_ANY, wxID_OK, wxID_CANCEL)
- TextCtrl styles (wxTE_MULTILINE, wxTE_READONLY, etc.)
- Layout flags (wxHORIZONTAL, wxVERTICAL, wxEXPAND, etc.)
- Control-specific styles (button, combobox, listbox)

**Note:** Constants are loaded dynamically from kwxFFI's `exp*()` functions at module init.

### test_widgets.jl
Tests widget creation without actually showing windows.

**Coverage:**
- Frame creation
- Control creation (Button, StaticText, TextCtrl, CheckBox, ComboBox, ListBox)
- Sizer creation (BoxSizer, GridSizer)
- Layout management
- Event handler registration
- Parent-child relationships

**Note:** These tests initialize wxWidgets but don't run the event loop, so windows aren't displayed.

## Prerequisites

Before running tests:
1. Build the project: `ninja -C build -f build-Release.ninja`
2. Ensure DLLs exist in `bin/Release/` (or set `KWXJULIA_LIB_PATH`)

## Test Framework

Tests use Julia's built-in `Test.jl` standard library:
- `@testset` groups related tests
- `@test` assertions
- Automatic pass/fail reporting

## Interpreting Results

```
Test Summary:          | Pass  Total  Time
kwxJulia Tests         |   87     87  2.3s
  String Conversion    |   12     12  0.4s
  Constants Loading    |   45     45  0.1s
  Widget Creation      |   30     30  1.8s
```

- **Pass**: Number of passing assertions
- **Total**: Total number of assertions
- **Time**: Execution time

## Common Issues

### "Failed to initialize wxWidgets"
The DLLs aren't found. Set `KWXJULIA_LIB_PATH`:

```powershell
$env:KWXJULIA_LIB_PATH = "C:\rwCode\wxLanguages\kwxJulia-dev\bin\Release"
julia test\runtests.jl
```

### Test hangs
If a test creates a window and calls `run_app`, it will block. Widget creation tests deliberately avoid running the event loop.

### Memory leaks in tests
WxString objects use finalizers for cleanup. If tests create many temporary strings, you may see GC pauses. This is normal - finalizers will be called eventually.

## Adding New Tests

When adding new features:
1. Create tests alongside implementation
2. Use `@testset` for logical grouping
3. Test both success and error cases
4. Avoid showing windows (use initialization tests only)

Example:

```julia
@testset "New Feature" begin
    @testset "Basic Functionality" begin
        # Test code here
        @test result == expected
    end

    @testset "Error Handling" begin
        @test_throws ErrorException invalid_operation()
    end
end
```

## Continuous Integration

These tests are designed to run in automated environments:
- No GUI display required (widgets tested but not shown)
- Fast execution (< 5 seconds total)
- Clear pass/fail output
- No user interaction needed

## Next Steps

- Review tests to understand API usage patterns
- Run tests after making changes
- Add tests for new features
- Use test patterns in your own code
