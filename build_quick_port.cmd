@echo off
rem Check the kwxJulia QuickPort app.
rem
rem Julia is interpreted, so there is no compile step: the build-only path loads the
rem port's form file. `include` parses and evaluates the definitions, which rejects
rem exactly what the loader rejects -- the same gate build_quick.cmd uses.
rem
rem   build_quick_port.cmd        load tests\quick_port (the port lane)
rem   build_quick_port.cmd help   this text
cd /D "%~dp0"
if /I "%~1"=="help" goto :usage
if /I "%~1"=="-h" goto :usage
if /I "%~1"=="/?" goto :usage

where julia >nul 2>&1
if errorlevel 1 (
    echo ERROR: julia not found on PATH.
    exit /b 1
)
if not exist "tests\quick_port\quick_port_main.jl" goto :no_main
if not exist "tests\quick_port\quick_port_forms.jl" goto :no_forms

rem quick_port_main.jl is not loaded: it owns the application bootstrap and would open a
rem window. --project=. resolves `using WxWidgets` from this repository's Project.toml.
julia --startup-file=no --project=. tests\load_check.jl tests\quick_port\quick_port_forms.jl
if errorlevel 1 (
    echo ERROR: Julia load check failed.
    exit /b 1
)
echo Loaded tests\quick_port
exit /b 0

:usage
echo Usage: build_quick_port.cmd
echo.
echo   build_quick_port.cmd        load tests\quick_port and exit with the load result
echo   build_quick_port.cmd help   this text
exit /b 0

:no_main
echo ERROR: tests\quick_port\quick_port_main.jl does not exist.
exit /b 1

:no_forms
echo ERROR: tests\quick_port\quick_port_forms.jl does not exist.
exit /b 1
