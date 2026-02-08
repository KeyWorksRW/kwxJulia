#!/usr/bin/env julia

# Simple library loading test

using Libdl

println("Current directory: ", pwd())
println("Testing library path...")

pkg_root = dirname(dirname(@__DIR__))
libdir = joinpath(pkg_root, "bin", "Release")
lib_path = joinpath(libdir, "kwxFFI.dll")

println("Library path: ", lib_path)
println("Library exists: ", isfile(lib_path))

if isfile(lib_path)
    println("\nAttempting to load library...")
    try
        lib = Libdl.dlopen(lib_path)
        println("✓ Library loaded successfully!")
        println("  Handle: ", lib)

        # Try calling a simple function
        println("\nTesting function calls...")
        result = ccall((:expwxID_ANY, lib), Cint, ())
        println("  expwxID_ANY() = ", result)

        Libdl.dlclose(lib)
    catch e
        println("✗ Failed to load library:")
        showerror(stdout, e, catch_backtrace())
        println()
    end
else
    println("✗ Library file not found!")
end
