# Caregiver Documents Storage

This directory stores uploaded caregiver verification documents locally.

## Structure:
```
uploads/caregiver_documents/
├── {user_id}/
│   ├── id_proof/
│   │   └── {timestamp}_{filename}.{ext}
│   ├── address_proof/
│   │   └── {timestamp}_{filename}.{ext}
│   ├── certifications/
│   │   └── {timestamp}_{filename}.{ext}
│   └── background_check/
│       └── {timestamp}_{filename}.{ext}
```

## File Naming Convention:
- Format: `{milliseconds_timestamp}_{original_filename}`
- Example: `1700000000000_drivers_license.pdf`

## Supported Formats:
- PDF (.pdf)
- Images (.jpg, .jpeg, .png)

## Maximum File Size:
- 5 MB per file

## Security:
- Only authenticated caregivers can upload their own documents
- File paths are stored in Firestore `users` collection
- Admin can view all documents for verification
- Firestore rules enforce access control

## Verification Process:
1. Caregiver uploads documents → Saved to this folder
2. File path stored in Firestore: `users/{uid}/documents/{documentType}`
3. Document history logged in: `users/{uid}/document_history`
4. Verification request created in: `verification_requests`
5. Admin reviews documents and approves/rejects
6. Status updated in: `users/{uid}/verificationStatus`

## Important Notes:
- Add `uploads/` to `.gitignore` to prevent committing sensitive documents
- For production, consider encrypting documents at rest
- Implement regular backups of this directory
- Set up proper file system permissions (read/write for app only)
