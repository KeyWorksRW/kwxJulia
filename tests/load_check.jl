# load_check.jl — the build gate for the generated form files.
#
# Julia is interpreted, so there is no compiler step: the gate is a real load of every
# generated file. `include` parses and evaluates each definition, which rejects exactly
# what the loader rejects. `Meta.parseall` cannot be used for this: it returns an error
# expression for an invalid file instead of raising, so a gate built on it exits 0 for a
# file the loader will not accept (see .private/kwxLedger.md, Phase 6 findings).
#
# Usage (from the repository root):
#   julia --startup-file=no --project=. tests/load_check.jl tests/quick/quick_mainframe.jl ...
#
# The hand-written runners (quick_main.jl / probe_main.jl) are never loaded here: they own
# the application bootstrap and would open a window and enter the event loop.

if isempty(ARGS)
    println(stderr, "usage: julia tests/load_check.jl <file>...")
    exit(2)
end

for path in ARGS
    if !isfile(path)
        println(stderr, "ERROR: $path does not exist")
        exit(1)
    end
    Base.include(Main, abspath(path))
end

println("loaded ", length(ARGS), " file(s)")
