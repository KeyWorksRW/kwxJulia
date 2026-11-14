@echo off
rem Load-check the kwxJulia probe lane. probe.wxui generates probe_mainframe.jl and
rem probe_dlg.jl into tests\quick_probe\gen\; probe_main.jl is hand-written.
rem Probe output never goes to tests\quick.
rem
rem   build_probe.cmd        load tests\quick_probe (the probe gate)
rem   build_probe.cmd help   this text
cd /D "%~dp0"
if /I "%~1"=="help" goto :usage
if /I "%~1"=="-h" goto :usage
if /I "%~1"=="/?" goto :usage

where julia >nul 2>&1
if errorlevel 1 (
    echo ERROR: julia not found on PATH.
    exit /b 1
)
if not exist "tests\quick_probe\probe_main.jl" goto :no_main
if not exist "tests\quick_probe\gen\probe_mainframe.jl" goto :no_gen
if not exist "tests\quick_probe\gen\probe_dlg.jl" goto :no_gen

rem probe_main.jl is not loaded: it owns the application bootstrap and would open a
rem window. --project=. resolves `using WxWidgets` from this repository's Project.toml.
julia --startup-file=no --project=. tests\load_check.jl tests\quick_probe\gen\probe_mainframe.jl tests\quick_probe\gen\probe_dlg.jl
if errorlevel 1 (
    echo ERROR: Julia probe load check failed.
    exit /b 1
)
echo Loaded tests\quick_probe
exit /b 0

:usage
echo Usage: build_probe.cmd
echo.
echo   build_probe.cmd        load tests\quick_probe and exit with the load result
echo   build_probe.cmd help   this text
exit /b 0

:no_main
echo ERROR: tests\quick_probe\probe_main.jl does not exist.
exit /b 1

:no_gen
echo ERROR: tests\quick_probe\gen\probe_mainframe.jl does not exist.
echo        Generate it from ..\quick\tests\quick_probe\probe.wxui first.
exit /b 1
