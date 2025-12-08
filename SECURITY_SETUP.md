# 🔐 Security Setup Guide

## ⚠️ IMPORTANT: Firebase Configuration

This project uses Firebase for backend services. The Firebase configuration files contain sensitive API keys and credentials that **MUST NOT** be committed to version control.

---

## 📋 Required Configuration Files

The following files are **required** but are **NOT included** in the repository for security reasons:

### 1. Firebase Options (Dart)
**File:** `lib/firebase_options.dart`

**Setup:**
```bash
# Copy the template
cp lib/firebase_options.dart.example lib/firebase_options.dart
```

Then edit `lib/firebase_options.dart` and replace all placeholder values with your actual Firebase configuration from the Firebase Console.

### 2. Android Google Services
**File:** `android/app/google-services.json`

**Setup:**
```bash
# Copy the template
cp android/app/google-services.json.example android/app/google-services.json
```

Download your actual `google-services.json` from Firebase Console:
1. Go to Firebase Console → Project Settings
2. Under "Your apps" section, select your Android app
3. Download `google-services.json`
4. Place it in `android/app/`

### 3. iOS Google Services (if using iOS)
**File:** `ios/Runner/GoogleService-Info.plist`

**Setup:**
1. Go to Firebase Console → Project Settings
2. Under "Your apps" section, select your iOS app
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`

---

## 🚀 Quick Start

### Step 1: Install Flutter Dependencies
```bash
flutter pub get
```

### Step 2: Setup Firebase Configuration

#### Option A: Using FlutterFire CLI (Recommended)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This will automatically generate `lib/firebase_options.dart` and download platform-specific config files.

#### Option B: Manual Setup
1. Copy template files as shown above
2. Get your Firebase config from Firebase Console
3. Replace placeholder values in the copied files

### Step 3: Verify Setup
```bash
# Check if all required files exist
flutter doctor

# Try running the app
flutter run
```

---

## 🔒 Security Best Practices

### Files That Should NEVER Be Committed:
- ✅ Already in `.gitignore`:
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `macos/Runner/GoogleService-Info.plist`
  - `.env` files
  - Any files with API keys, secrets, or credentials

### What's Safe to Commit:
- ✅ Template files (`.example` suffix)
- ✅ Documentation
- ✅ Source code
- ✅ Assets (images, fonts)
- ✅ Configuration templates

---

## 🛡️ Firebase Security Rules

Ensure your Firebase Security Rules are properly configured:

### Firestore Rules
See `firestore.rules` - these are safe to commit and should be deployed to Firebase.

### Storage Rules
See `storage.rules` - these are safe to commit and should be deployed to Firebase.

---

## 🔑 API Keys Management

### Environment-Specific Configurations

For different environments (dev, staging, production), use:

```bash
# Development
cp lib/firebase_options.dart.example lib/firebase_options.dev.dart

# Staging
cp lib/firebase_options.dart.example lib/firebase_options.staging.dart

# Production
cp lib/firebase_options.dart.example lib/firebase_options.dart
```

**Note:** All `firebase_options.*.dart` files are gitignored except the template.

---

## 📱 Platform-Specific Setup

### Android
1. **Package Name:** Ensure your `android/app/build.gradle` has the correct `applicationId` matching your Firebase Android app
2. **SHA-1 Certificate:** Add your debug and release SHA-1 fingerprints to Firebase Console for authentication features

```bash
# Get debug SHA-1
cd android
./gradlew signingReport
```

### iOS
1. **Bundle ID:** Ensure your iOS bundle ID matches the one in Firebase Console
2. **Provisioning:** Configure proper provisioning profiles for release builds

---

## ⚙️ Firebase Features Used

This project uses the following Firebase services:
- 🔐 **Authentication** - Email/Password, Phone Auth
- 📊 **Firestore Database** - Real-time data storage
- 📁 **Cloud Storage** - File uploads (documents, images)
- 📧 **Cloud Functions** - Backend logic (if applicable)
- 📬 **Cloud Messaging** - Push notifications

---

## 🔄 Updating Firebase Configuration

If you need to update Firebase configuration:

1. **DO NOT** edit files directly in version control
2. Get new config from Firebase Console
3. Update your local files (that are gitignored)
4. Update the `.example` templates if structure changes
5. Notify team members to update their local configs

---

## 🚨 What to Do If Credentials Are Exposed

If you accidentally commit sensitive credentials:

### 1. Immediately Rotate All Keys
- Go to Firebase Console
- Regenerate API keys
- Update Firebase app configurations

### 2. Remove from Git History
```bash
# Remove file from Git history (USE WITH CAUTION)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch lib/firebase_options.dart" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (only if you're sure!)
git push origin --force --all
```

### 3. Verify Removal
```bash
# Check if file is still in history
git log --all --full-history -- lib/firebase_options.dart
```

### 4. Inform Your Team
- Notify all team members
- Have everyone re-clone the repository
- Update all local configurations

---

## 📞 Support

If you encounter issues with Firebase setup:

1. Check Firebase Console for configuration
2. Verify all files are in correct locations
3. Run `flutter clean` and `flutter pub get`
4. Check Firebase documentation: https://firebase.google.com/docs/flutter/setup

---

## ✅ Setup Checklist

Before running the app, ensure:

- [ ] `lib/firebase_options.dart` exists with real config
- [ ] `android/app/google-services.json` exists (for Android)
- [ ] `ios/Runner/GoogleService-Info.plist` exists (for iOS)
- [ ] Firebase project is created in Firebase Console
- [ ] All required Firebase services are enabled
- [ ] Firestore security rules are deployed
- [ ] Storage security rules are deployed
- [ ] Package name/bundle ID matches Firebase config
- [ ] `.gitignore` includes all sensitive files

---

**Last Updated:** December 8, 2025
