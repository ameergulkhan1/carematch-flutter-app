# Caregiver Registration System - Implementation Summary

## ✅ Completed Files

### 1. Models
- **caregiver_user_model.dart**: Complete caregiver user model with Firestore serialization
  - Fields: uid, email, fullName, phone, DOB, address, professional info
  - Verification status: 'pending', 'approved', 'rejected'
  - Documents map: {type: downloadUrl}

### 2. Services
- **caregiver_service.dart**: Complete Firebase integration
  - registerCaregiver(): Creates Auth user + Firestore document
  - uploadDocument(): Uploads to Firebase Storage at `caregiver_documents/{uid}/{type}/{timestamp}_{filename}`
  - submitDocuments(): Marks documents as submitted, creates verification_request
  - Document validation: PDF/JPG/PNG, max 5MB

### 3. Providers
- **caregiver_provider.dart**: State management with ChangeNotifier
  - Registration, OTP verification, professional info update
  - Document upload with progress tracking
  - Error handling and loading states

### 4. Screens Created
- **caregiver_signup_step1.dart**: Email/password with validation
- **caregiver_signup_step2.dart**: Personal info + address (18+ age check)
- **caregiver_signup_step3.dart**: OTP email verification

## 📋 TODO: Remaining Screens

### Step 4: Professional Information
**File**: `lib/features/caregiver/screens/caregiver_signup_step4.dart`

**Fields**:
- Years of Experience (dropdown: <1, 1-2, 3-5, 5-10, 10+)
- Specializations (multi-select chips):
  * Elderly Care
  * Child Care
  * Disability Care
  * Dementia Care
  * Post-Surgery Care
  * Hospice Care
- Bio (text area, 500 chars max)
- Certifications (multi-select):
  * CNA (Certified Nursing Assistant)
  * HHA (Home Health Aide)
  * CPR/First Aid
  * Medication Management
  * Other

**Implementation**:
```dart
- Progress: 4/5
- Call: caregiverProvider.updateProfessionalInfo()
- Navigate to: '/caregiver-signup-step5'
```

### Step 5: Document Upload
**File**: `lib/features/caregiver/screens/caregiver_signup_step5.dart`

**Required Documents**:
1. **ID Proof** (government-issued):
   - Driver's License / Passport / State ID
   - file_picker for PDF/JPG/PNG

2. **Address Proof**:
   - Utility Bill / Bank Statement / Lease Agreement
   
3. **Certifications** (if applicable):
   - Upload certification documents

4. **Professional References** (2-3):
   - Name, Phone, Relationship fields (not file upload)

5. **Background Check Consent**:
   - Checkbox with legal text
   - Digital signature field

**Document Upload UI**:
```dart
- For each document type:
  * Upload button (file_picker)
  * Preview thumbnail
  * File name + size
  * Delete button
  * Upload progress indicator
  
- Submit button enabled when all required docs uploaded
- Calls: caregiverProvider.uploadDocument() for each
- Final submit: caregiverProvider.submitDocumentsForVerification()
- Navigate to: '/caregiver-pending-dashboard'
```

### Pending Dashboard
**File**: `lib/features/caregiver/screens/caregiver_pending_dashboard.dart`

**UI**:
- Status banner: "Verification Pending"
- Timeline of submitted documents
- Estimated review time (24-48 hours)
- Contact support button
- Refresh verification status button

**States**:
- Pending: Yellow banner, "Under Review"
- Approved: Green banner, navigate to full caregiver dashboard
- Rejected: Red banner, show rejection reason, "Re-submit Documents" button

## 🔥 Firebase Storage Structure

```
caregiver_documents/
├── {userId}/
│   ├── id_proof/
│   │   └── {timestamp}_{filename}.pdf
│   ├── address_proof/
│   │   └── {timestamp}_{filename}.pdf
│   ├── certifications/
│   │   ├── {timestamp}_cna_cert.pdf
│   │   └── {timestamp}_cpr_cert.pdf
│   └── background_check/
│       └── {timestamp}_consent.pdf
```

## 📊 Firestore Collections

### users (existing)
```javascript
{
  uid: string,
  role: 'caregiver',
  email: string,
  fullName: string,
  phoneNumber: string,
  dateOfBirth: timestamp,
  address, city, state, zipCode: string,
  
  // Professional Info
  yearsOfExperience: string,
  specializations: string[],
  bio: string,
  certifications: string[],
  
  // Verification
  verificationStatus: 'pending' | 'approved' | 'rejected',
  isEmailVerified: boolean,
  documentsSubmitted: boolean,
  
  // Documents (URLs)
  documents: {
    id_proof: "https://...",
    address_proof: "https://...",
    certifications: "https://...",
    background_check: "https://..."
  },
  
  rejectionReason: string | null,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### verification_requests (new)
```javascript
{
  caregiverId: string,
  requestedAt: timestamp,
  status: 'pending' | 'approved' | 'rejected',
  reviewedBy: string | null, // admin UID
  reviewedAt: timestamp | null,
  notes: string | null,
  rejectionReason: string | null
}
```

### document_history (subcollection of users)
```javascript
users/{uid}/document_history/{docId}
{
  documentType: string,
  fileName: string,
  fileSize: number,
  downloadUrl: string,
  storagePath: string,
  uploadedAt: timestamp,
  status: 'pending' | 'verified' | 'rejected'
}
```

## 🛣️ Routes to Add

```dart
// In lib/app.dart - add to routes:
'/caregiver-signup-step1': (context) => const CaregiverSignupStep1(),
'/caregiver-signup-step2': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return CaregiverSignupStep2(
    email: args['email'],
    password: args['password'],
  );
},
'/caregiver-signup-step3': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return CaregiverSignupStep3(
    email: args['email'],
    fullName: args['fullName'],
  );
},
'/caregiver-signup-step4': (context) => const CaregiverSignupStep4(),
'/caregiver-signup-step5': (context) => const CaregiverSignupStep5(),
'/caregiver-pending-dashboard': (context) => const CaregiverPendingDashboard(),
```

## 🔐 Firestore Rules Update

```javascript
// Add to firestore.rules
match /verification_requests/{requestId} {
  allow read: if request.auth != null && 
    (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
     resource.data.caregiverId == request.auth.uid);
  allow create: if request.auth != null && 
    request.resource.data.caregiverId == request.auth.uid;
  allow update: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}

// Storage rules for caregiver_documents
service firebase.storage {
  match /b/{bucket}/o {
    match /caregiver_documents/{userId}/{documentType}/{fileName} {
      allow read: if request.auth != null && 
        (request.auth.uid == userId || 
         get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && 
        (request.auth.uid == userId || 
         get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

## 🎯 Implementation Order

1. ✅ Models (caregiver_user_model.dart)
2. ✅ Service (caregiver_service.dart)
3. ✅ Provider (caregiver_provider.dart)
4. ✅ Step 1: Email/Password
5. ✅ Step 2: Personal Info
6. ✅ Step 3: OTP Verification
7. ⏳ Step 4: Professional Info (next)
8. ⏳ Step 5: Document Upload (next)
9. ⏳ Pending Dashboard
10. ⏳ Add routes to app.dart
11. ⏳ Add CaregiverProvider to MultiProvider
12. ⏳ Update Firestore rules
13. ⏳ Test complete flow

## 📝 Next Steps

1. Create Step 4 (Professional Info screen)
2. Create Step 5 (Document Upload screen with file_picker)
3. Create Pending Dashboard
4. Add routes and provider
5. Update Firestore security rules
6. Test registration flow end-to-end
7. Build admin verification UI

## 🔄 Admin Verification Workflow (Future)

- Admin dashboard shows pending verification requests
- View uploaded documents (PDF viewer / image viewer)
- Approve/Reject with notes
- On approval: update verificationStatus to 'approved'
- On rejection: set rejectionReason, allow caregiver to re-submit
- Email notifications for status changes
