@echo off
echo.
echo ========================================
echo   CareMatch App - Cleanup for Sharing
echo ========================================
echo.
echo This will delete build files to reduce project size
echo from ~200MB to ~15MB for easy sharing.
echo.
echo Files to be deleted:
echo   - build/
echo   - .dart_tool/
echo   - windows/
echo   - linux/
echo   - macos/
echo   - web/ (optional)
echo.
pause

echo.
echo Cleaning build folder...
if exist build (
    rmdir /s /q build
    echo [OK] Deleted build/
) else (
    echo [SKIP] build/ not found
)

echo.
echo Cleaning .dart_tool folder...
if exist .dart_tool (
    rmdir /s /q .dart_tool
    echo [OK] Deleted .dart_tool/
) else (
    echo [SKIP] .dart_tool/ not found
)

echo.
echo Cleaning windows folder...
if exist windows (
    rmdir /s /q windows
    echo [OK] Deleted windows/
) else (
    echo [SKIP] windows/ not found
)

echo.
echo Cleaning linux folder...
if exist linux (
    rmdir /s /q linux
    echo [OK] Deleted linux/
) else (
    echo [SKIP] linux/ not found
)

echo.
echo Cleaning macos folder...
if exist macos (
    rmdir /s /q macos
    echo [OK] Deleted macos/
) else (
    echo [SKIP] macos/ not found
)

echo.
echo Do you want to delete web/ folder too? (Y/N)
set /p choice=Your choice: 
if /i "%choice%"=="Y" (
    if exist web (
        rmdir /s /q web
        echo [OK] Deleted web/
    ) else (
        echo [SKIP] web/ not found
    )
) else (
    echo [SKIP] Keeping web/ folder
)

echo.
echo ========================================
echo   Cleanup Complete!
echo ========================================
echo.
echo Your project is now ready to share!
echo.
echo Next steps:
echo   1. Right-click on 'carematch_app' folder
echo   2. Select "Send to" -^> "Compressed (zipped) folder"
echo   3. Share the ZIP file with your friend
echo.
echo See SHARING_CHECKLIST.md for full instructions.
echo.
pause
