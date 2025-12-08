@echo off
echo ========================================
echo CareMatch Security Cleanup Script
echo ========================================
echo.
echo This script will:
echo 1. Remove sensitive files from Git tracking
echo 2. Keep files locally but prevent future commits
echo 3. Update .gitignore to prevent accidental commits
echo.
echo WARNING: This will modify your Git repository!
echo Press Ctrl+C to cancel, or
pause

echo.
echo Step 1: Removing sensitive files from Git tracking...
echo --------------------------------------------------------

git rm --cached lib/firebase_options.dart 2>nul
git rm --cached android/app/google-services.json 2>nul
git rm --cached ios/Runner/GoogleService-Info.plist 2>nul
git rm --cached macos/Runner/GoogleService-Info.plist 2>nul

echo.
echo Step 2: Adding changes to Git...
echo --------------------------------------------------------

git add .gitignore
git add lib/firebase_options.dart.example
git add android/app/google-services.json.example
git add SECURITY_SETUP.md
git add REMOVE_SENSITIVE_FILES.bat

echo.
echo Step 3: Creating commit...
echo --------------------------------------------------------

git commit -m "🔒 Security: Remove sensitive Firebase configuration files

- Added .gitignore rules for all sensitive files
- Created template files (.example) for Firebase configuration
- Added SECURITY_SETUP.md with detailed setup instructions
- Removed firebase_options.dart from tracking
- Removed google-services.json from tracking
- Removed GoogleService-Info.plist from tracking

IMPORTANT: Team members must:
1. Copy .example files and add their own Firebase config
2. Never commit actual Firebase configuration files
3. Follow SECURITY_SETUP.md for proper setup"

echo.
echo ========================================
echo Cleanup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Review the changes: git status
echo 2. Push to GitHub: git push origin main
echo 3. Notify team members to update their local configs
echo 4. Consider regenerating Firebase API keys if already exposed
echo.
echo IMPORTANT: Your local config files are safe and not deleted.
echo They are just removed from Git tracking.
echo.
pause
