# Admin Verification Dashboard

## Overview
The Admin Verification Dashboard is a comprehensive, professional interface for managing caregiver verification requests in the CareMatch platform.

## Features

### 📊 Dashboard Statistics
- **Total Requests**: All verification requests submitted
- **Pending**: Requests awaiting review
- **Approved**: Successfully verified caregivers
- **Rejected**: Denied applications
- **Revision Requested**: Applications needing document updates

### 🔍 Search & Filter
- Real-time search by caregiver ID, email, or name
- Filter chips for quick status filtering:
  - All Requests
  - Pending
  - Approved
  - Rejected
  - Revision Requested

### 📝 Verification Actions

#### 1. Approve Application
- Add welcome message or approval notes
- Automatically updates caregiver status to "approved"
- Sets `isVerified = true`
- Sends notification to caregiver
- Enables booking eligibility

#### 2. Request Document Revision
- Select specific documents that need revision
- Provide detailed feedback on what needs to be corrected
- Caregiver can resubmit documents
- Status changes to "revision_requested"
- Notification sent with revision requirements

#### 3. Reject Application
- Select problematic documents (optional)
- Provide detailed rejection reason (required)
- Permanently rejects the application
- Status changes to "rejected"
- Notification sent with rejection details

## File Structure

```
lib/features/admin/
├── screens/
│   ├── admin_verification_dashboard.dart  # Main dashboard with stats and list
│   └── verification_request_detail.dart   # Detailed view with actions
├── widgets/
│   ├── stat_card.dart                     # Statistics display card
│   ├── verification_request_card.dart     # Request list item
│   ├── status_badge.dart                  # Status indicator
│   ├── document_tile.dart                 # Document list item
│   ├── info_section.dart                  # Section container
│   └── info_row.dart                      # Information row display
└── services/
    └── admin_verification_service.dart    # Backend service

lib/services/
└── admin_verification_service.dart
```

## Service Methods

### `getVerificationRequests({statusFilter})`
Returns a stream of verification requests, optionally filtered by status.

### `getCaregiverDetails(caregiverId)`
Fetches complete caregiver profile information.

### `getDocumentHistory(caregiverId)`
Returns document upload history with timestamps.

### `approveVerification({requestId, caregiverId, adminId, adminNotes})`
Approves a verification request and sends notification.

### `rejectVerification({requestId, caregiverId, adminId, rejectionReason, rejectedDocuments})`
Rejects a verification request with detailed reason.

### `requestRevision({requestId, caregiverId, adminId, revisionNotes, documentsToRevise})`
Requests document revision from caregiver.

### `getVerificationStats()`
Returns statistics for all verification requests.

## Navigation

### Access the Dashboard
```dart
Navigator.pushNamed(context, '/admin-verification-dashboard');
```

### View Request Details
```dart
Navigator.pushNamed(
  context,
  '/admin-verification-detail',
  arguments: {
    'requestId': requestId,
    'caregiverId': caregiverId,
  },
);
```

## Firestore Structure

### Verification Requests Collection
```
verification_requests/{requestId}
├── caregiverId: string
├── status: 'pending' | 'approved' | 'rejected' | 'revision_requested'
├── requestedAt: timestamp
├── reviewedAt: timestamp (optional)
├── reviewedBy: string (admin UID)
├── adminNotes: string (for approvals)
├── rejectionReason: string (for rejections)
├── rejectedDocuments: array (for rejections)
├── revisionNotes: string (for revisions)
└── documentsToRevise: array (for revisions)
```

### Users Collection (Caregiver)
```
users/{caregiverId}
├── role: 'caregiver'
├── verificationStatus: string
├── isVerified: boolean
├── documentsSubmitted: boolean
├── documents: map {documentType: filePath}
├── yearsOfExperience: string
├── specializations: array
├── certifications: array
├── bio: string
└── updatedAt: timestamp
```

### Document History Subcollection
```
users/{caregiverId}/document_history/{documentId}
├── documentType: string
├── fileName: string
├── fileSize: number
├── filePath: string
├── uploadedAt: timestamp
└── status: string
```

### Notifications Collection
```
notifications/{notificationId}
├── userId: string (caregiver UID)
├── type: 'verification_approved' | 'verification_rejected' | 'revision_requested'
├── title: string
├── message: string
├── adminNotes: string (optional)
├── rejectionReason: string (optional)
├── rejectedDocuments: array (optional)
├── revisionNotes: string (optional)
├── documentsToRevise: array (optional)
├── isRead: boolean
└── createdAt: timestamp
```

## Security Rules

Ensure these Firestore rules are deployed:

```javascript
// Verification Requests
match /verification_requests/{requestId} {
  allow read: if isAdmin() || (isAuthenticated() && request.auth.uid == resource.data.caregiverId);
  allow create: if isAuthenticated() && request.auth.uid == request.resource.data.caregiverId;
  allow update: if isAdmin();
  allow delete: if isAdmin();
}

// Notifications
match /notifications/{notificationId} {
  allow read: if isAuthenticated() && request.auth.uid == resource.data.userId;
  allow create: if isAdmin() || isAuthenticated();
  allow update: if isAuthenticated() && request.auth.uid == resource.data.userId;
  allow delete: if isAuthenticated() && request.auth.uid == resource.data.userId;
}
```

## UI Components

### StatCard
- Displays statistics with icon, value, and label
- Color-coded for different metrics
- Optional tap functionality

### VerificationRequestCard
- Shows request summary in list
- Status badge with icon
- Timestamp with relative formatting
- Tap to view details

### StatusBadge
- Color-coded status indicator
- Border and background styling
- Auto-formats status text

### DocumentTile
- Displays document information
- File type icon (PDF/Image)
- Tap to view (not implemented - metadata only)
- Optional selection state

### InfoSection
- Consistent section layout
- Header with icon and title
- Divider and content area

### InfoRow
- Two-column layout
- Label and value display
- Consistent spacing

## Testing Checklist

- [ ] Access admin dashboard via navigation
- [ ] View statistics updating in real-time
- [ ] Search for specific caregivers
- [ ] Filter by status (all, pending, approved, rejected, revision)
- [ ] Click request card to view details
- [ ] Review caregiver profile information
- [ ] View uploaded documents (metadata)
- [ ] Approve request with notes
- [ ] Verify notification sent to caregiver
- [ ] Request document revision with specific docs
- [ ] Verify revision notification sent
- [ ] Reject application with reason
- [ ] Verify rejection notification sent
- [ ] Check Firestore data updates correctly
- [ ] Verify caregiver status changes reflect immediately

## Workflow Stages

### Stage 1: Registration
1. Caregiver completes 5-step signup
2. Documents uploaded (metadata stored)
3. Verification request created
4. Status: **Pending**

### Stage 2: Admin Review
1. Admin accesses dashboard
2. Views pending requests
3. Opens request details
4. Reviews profile and documents

### Stage 3: Decision
**Option A - Approve:**
- Add approval notes
- Status → Approved
- Notification sent
- Caregiver can receive bookings

**Option B - Request Revision:**
- Select documents to revise
- Add revision notes
- Status → Revision Requested
- Caregiver can resubmit

**Option C - Reject:**
- Select problematic docs
- Add rejection reason
- Status → Rejected
- Application denied

### Stage 4: Notification
- Caregiver receives notification
- View details in notifications section
- Take appropriate action

## Production Considerations

1. **Document Viewing**: Implement actual file viewing/download
2. **Email Notifications**: Configure EmailJS for email alerts
3. **Admin Authentication**: Add admin role verification
4. **Audit Logging**: Log all admin actions
5. **Analytics**: Track approval rates and timelines
6. **Batch Actions**: Allow bulk approve/reject
7. **Comments**: Add admin-caregiver messaging
8. **File Storage**: Implement backend for actual file uploads

## Screenshots & Design

### Dashboard Layout
- Clean, modern Material Design
- Color-coded statistics cards
- Searchable, filterable list
- Pull-to-refresh functionality

### Detail Screen
- Professional profile header
- Organized information sections
- Clear action buttons
- Timeline of document uploads

### Color Scheme
- **Primary**: Blue (#1976D2)
- **Success**: Green (Approvals)
- **Error**: Red (Rejections)
- **Warning**: Orange (Pending)
- **Info**: Blue (Revisions)

## Support

For issues or enhancements, refer to:
- `lib/services/admin_verification_service.dart` - Backend logic
- `lib/features/admin/screens/` - UI screens
- `lib/features/admin/widgets/` - Reusable components
- Firestore rules in `firestore.rules`
