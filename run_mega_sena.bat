@echo off
echo Launching Mega Sena Generator with Smart Strategies...
cd /d %~dp0

REM Check if Flutter is in PATH
where flutter >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Flutter found in PATH, using it...
    set FLUTTER_CMD=flutter
) else (
    echo Flutter not found in PATH, trying default location...
    if exist C:\dev\flutter\bin\flutter.bat (
        echo Flutter found at default location...
        set FLUTTER_CMD=C:\dev\flutter\bin\flutter.bat
    ) else (
        echo Flutter not found! Please make sure Flutter is installed and in your PATH.
        echo You can run this app manually with 'flutter run' from the project directory.
        pause
        exit /b 1
    )
)

echo.
echo Getting dependencies...
%FLUTTER_CMD% pub get

echo.
echo Starting Flutter application...
echo.
%FLUTTER_CMD% run

REM If an error occurs, pause to show the message
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Error launching the application!
    pause
)
