# Main module for kwxJulia - Julia bindings for wxWidgets via kwxFFI
module WxWidgets

using Libdl

# ---------------------------------------------------------------- generated FFI
# Raw ccall layer.  Every generated file below references `KwxFFI`, so this
# module must be created first.
include(joinpath(@__DIR__, "..", "wx", "KwxFFI_gen.jl"))
using .KwxFFI

# Generated runtime layer.  Order is fixed by kwxgen:
#   types_gen.jl    - abstract roots, wxEvent and `_wx_wrap`
#   wxstring_gen.jl - wxString lifecycle plus `_wx_take_cstring`/`_wx_take_wxstring`
#   wx_idiomatic_gen.jl - one file per class, all methods on the generated structs
include(joinpath(@__DIR__, "..", "wx", "types_gen.jl"))
include(joinpath(@__DIR__, "..", "wx", "wxstring_gen.jl"))
include(joinpath(@__DIR__, "..", "wx", "wx_idiomatic_gen.jl"))

# ------------------------------------------------------------ app lifecycle
# kwxgen generates every widget type, constructor, accessor, sizer operation and
# event primitive (wx/).  The only hand-written code is the GUI application
# layer in core/kwxapp.jl: kwxApp_* from src/cpp/kwxApp.cpp, run_app/exit_app,
# and the Julia event bridge.  Nothing else belongs in src/.
include("core/kwxapp.jl")

# --- Exports ---
# KwxFFI submodule (for constants, events, and raw FFI access)
export KwxFFI
# Application lifecycle
export run_app, exit_app, set_top_window, set_exit_on_frame_delete
# Julia event bridge over the generated wxClosure / Base.bind surface
export wx_connect!, wx_disconnect!

# Every other exported name (wxFrame, wxButton, set_status_text!, add_window!,
# the sizer types, ...) comes from wx/wx_exports_gen.jl, which is included by
# wx/wx_idiomatic_gen.jl and is the authoritative public surface.

"""
Module initialization - adds kwxFFI DLL directory to the library search path.
Called automatically when the module is first loaded.
"""
function __init__()
    # Add kwxFFI DLL directory to Julia's library search path
    dlldir = joinpath(@__DIR__, "..", "bin", "Release")
    if isdir(dlldir) && !(dlldir in Libdl.DL_LOAD_PATH)
        pushfirst!(Libdl.DL_LOAD_PATH, dlldir)
    end
end

end # module WxWidgets
