@echo off
rem Check the kwxJulia quick test app.
rem
rem Julia is interpreted, so there is no compile step: the build-only path loads every
rem generated form file. `include` parses and evaluates the definitions, which rejects
rem exactly what the loader rejects. Meta.parseall cannot be the gate -- it returns an
rem error expression for an invalid file instead of raising, so it exits 0 for a file
rem the loader refuses (see .private/kwxLedger.md, Phase 6 findings).
rem
rem   build_quick.cmd        load tests\quick (the verification gate)
rem   build_quick.cmd help   this text
cd /D "%~dp0"
if /I "%~1"=="help" goto :usage
if /I "%~1"=="-h" goto :usage
if /I "%~1"=="/?" goto :usage

where julia >nul 2>&1
if errorlevel 1 (
    echo ERROR: julia not found on PATH.
    exit /b 1
)
if not exist "tests\quick\quick_main.jl" goto :no_main
if not exist "tests\quick\quick_mainframe.jl" goto :no_gen

rem quick_main.jl is not loaded: it owns the application bootstrap and would open a
rem window. --project=. resolves `using WxWidgets` from this repository's Project.toml.
julia --startup-file=no --project=. tests\load_check.jl tests\quick\quick_mainframe.jl tests\quick\quick_dlg.jl
if errorlevel 1 (
    echo ERROR: Julia load check failed.
    exit /b 1
)
echo Loaded tests\quick
exit /b 0

:usage
echo Usage: build_quick.cmd
echo.
echo   build_quick.cmd        load tests\quick and exit with the load result
echo   build_quick.cmd help   this text
exit /b 0

:no_main
echo ERROR: tests\quick\quick_main.jl does not exist.
exit /b 1

:no_gen
echo ERROR: tests\quick\quick_mainframe.jl does not exist.
echo        Generate it from quick.wxui first.
exit /b 1
