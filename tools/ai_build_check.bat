@echo off
echo Running analyzer & build checks...
flutter clean
flutter pub get
flutter analyze
if %errorlevel% neq 0 (
    echo Analyzer failed.
    pause
    exit /b %errorlevel%
)
flutter build windows --debug
echo Build complete.
pause
