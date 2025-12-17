# CareMatch Flutter Application

A comprehensive Flutter application connecting clients with professional caregivers.

## Features

- Multi-role system (Client, Caregiver, Admin)
- Real-time booking management
- Secure payment processing
- Reviews & ratings system
- Location-based caregiver search
- Real-time messaging
- Incident reporting
- Document verification

## Tech Stack

- Flutter 3.0+
- Firebase (Auth, Firestore, Storage, Functions)
- Provider (State Management)
- Google Maps Flutter

## Setup

**Note:** This project requires Firebase configuration files and API keys that are not included in this repository for security reasons.

### Required Configuration (Not Included):

1. `google-services.json` (Android)
2. `GoogleService-Info.plist` (iOS)
3. `lib/firebase_options.dart`
4. `firestore.rules` and `firestore.indexes.json`
5. Google Maps API keys
6. Environment variables

### Installation

```bash
flutter pub get
flutter run
```

## Security

⚠️ **Important Security Notes:**
- Firebase configuration files are excluded from version control
- Database rules and indexes are maintained locally only
- API keys and secrets must be configured separately
- All sensitive data is protected by Firestore security rules

## Project Structure

```
lib/
├── features/     # Feature modules
├── services/     # Business logic
├── models/       # Data models
├── core/         # Core utilities
└── shared/       # Shared components
```

## License

Private - All Rights Reserved

## Contact

For access to configuration files and deployment documentation, contact the project administrator.
