@echo off
REM OSGA Simulator Launcher for Windows
REM Usage: run_windows.bat [app_name]

echo ===========================
echo     OSGA Simulator
echo ===========================
echo.

REM Check if Love2D is in PATH
where love >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Love2D is not installed or not in PATH
    echo.
    echo Please install Love2D:
    echo   1. Download from: https://love2d.org/
    echo   2. Or use Chocolatey: choco install love2d
    echo   3. Add Love2D to your PATH environment variable
    echo.
    
    REM Try common installation paths
    if exist "C:\Program Files\LOVE\love.exe" (
        echo Found Love2D at default location. Using it...
        set LOVE_PATH="C:\Program Files\LOVE\love.exe"
        goto :found_love
    )
    if exist "C:\Program Files (x86)\LOVE\love.exe" (
        echo Found Love2D at default location. Using it...
        set LOVE_PATH="C:\Program Files (x86)\LOVE\love.exe"
        goto :found_love
    )
    
    pause
    exit /b 1
) else (
    set LOVE_PATH=love
)

:found_love
REM Check if we're in the right directory
if not exist "osga-sim" (
    echo ERROR: osga-sim directory not found
    echo Please run this script from the OSGA root directory
    pause
    exit /b 1
)

REM Launch simulator
if "%~1"=="" (
    echo Launching OSGA Simulator...
    %LOVE_PATH% osga-sim
) else (
    if exist "apps\%1" (
        echo Launching OSGA with app: %1
        %LOVE_PATH% osga-sim apps/%1
    ) else (
        echo ERROR: App not found: %1
        echo.
        echo Available apps:
        for /d %%i in (apps\*) do (
            if exist "%%i\main.lua" echo   %%~ni
        )
        pause
        exit /b 1
    )
)