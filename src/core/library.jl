# Library loading via Libdl
# kwxFFI.dll contains both wxWidgets wrappers and kwxApp lifecycle functions

using Libdl

# Library handle (loaded at module initialization)
const libwxffi = Ref{Ptr{Cvoid}}(C_NULL)

# Cached function pointers — populated on first use after load_libraries!()
const _ffi_cache = Dict{Symbol, Ptr{Cvoid}}()

"""
    ffi(name::Symbol) -> Ptr{Cvoid}

Return a cached function pointer from kwxFFI.dll.
Usage: `@ccall \$(ffi(:funcName))(args...)::RetType`
"""
function ffi(name::Symbol)::Ptr{Cvoid}
    get!(_ffi_cache, name) do
        Libdl.dlsym(libwxffi[], name)
    end
end

"""
    default_lib_path() -> String

Returns the default library path (bin/Release/ relative to package root).
Can be overridden via KWXJULIA_LIB_PATH environment variable.
"""
function default_lib_path()
    # @__DIR__ is src/core/, so package root is two levels up
    pkg_root = dirname(dirname(dirname(@__FILE__)))
    joinpath(pkg_root, "bin", "Release")
end

"""
    load_libraries!()

Load kwxFFI shared library. Called automatically during module initialization.
Override library path via KWXJULIA_LIB_PATH environment variable.
"""
function load_libraries!()
    libdir = get(ENV, "KWXJULIA_LIB_PATH", default_lib_path())

    @static if Sys.iswindows()
        lib_path = joinpath(libdir, "kwxFFI.dll")
    elseif Sys.isapple()
        lib_path = joinpath(libdir, "libkwxFFI.dylib")
    else
        lib_path = joinpath(libdir, "libkwxFFI.so")
    end

    if !isfile(lib_path)
        error("kwxFFI library not found at: $lib_path\n" *
              "Build the project with: ninja -C build -f build-Release.ninja\n" *
              "Or set KWXJULIA_LIB_PATH environment variable to the library directory.")
    end

    libwxffi[] = Libdl.dlopen(lib_path)
    empty!(_ffi_cache)  # Clear cached symbols on reload
end

"""
    unload_libraries!()

Unload kwxFFI library. Called automatically at program exit in most cases.
"""
function unload_libraries!()
    if libwxffi[] != C_NULL
        empty!(_ffi_cache)
        Libdl.dlclose(libwxffi[])
        libwxffi[] = C_NULL
    end
end
