# 🔐 Complete Firestore Security Rules & Indexes Setup

## ✅ What's Included

This setup provides **full permissions** for:
- ✅ **Admin**: Full access to everything
- ✅ **Caretaker**: Full access to their own data + read others
- ✅ **Public Users**: Search caretakers + Create bookings (no login required)

---

## 📋 Step 1: Deploy Firestore Rules

### Method 1: Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **`flowing-bazaar-468814-g0`**
3. Click **Firestore Database** (left sidebar)
4. Click **Rules** tab
5. **Copy all content** from `firestore_rules_COMPLETE.rules`
6. **Paste** into the editor
7. Click **Publish**

### Method 2: Firebase CLI

```bash
# Make sure you're in the project directory
cd c:\Users\hp\Desktop\carematch_app\carematch_app

# Copy the rules to the correct location
copy firestore_rules_COMPLETE.rules firestore.rules

# Deploy
firebase deploy --only firestore:rules
```

---

## 🔍 Step 2: Create Required Firestore Indexes

### Composite Indexes Needed:

Go to Firebase Console → Firestore Database → Indexes → **Composite** → Click "Add Index"

#### Index 1: Bookings by Caretaker & Status & Date
```
Collection ID: bookings
Fields:
  - caretakerId (Ascending)
  - status (Ascending)
  - bookingDate (Descending)
```

#### Index 2: Bookings by User & Status
```
Collection ID: bookings
Fields:
  - userId (Ascending)
  - status (Ascending)
  - createdAt (Descending)
```

#### Index 3: Reviews by Caretaker & Rating
```
Collection ID: reviews
Fields:
  - caretakerId (Ascending)
  - rating (Descending)
  - createdAt (Descending)
```

#### Index 4: Caretaker Profiles Search
```
Collection ID: caretaker_profiles
Fields:
  - isVerified (Ascending)
  - rating (Descending)
```

#### Index 5: Notifications by User & Read Status
```
Collection ID: notifications
Fields:
  - userId (Ascending)
  - isRead (Ascending)
  - createdAt (Descending)
```

#### Index 6: Chat Messages
```
Collection ID: chats/{chatId}/messages
Fields:
  - timestamp (Ascending)
```

#### Index 7: Audit Logs by User & Category
```
Collection ID: audit_logs
Fields:
  - userId (Ascending)
  - category (Ascending)
  - timestamp (Descending)
```

---

## 🎯 Step 3: Enable Required Firebase Features

### 1. Enable Google Sign-In

1. Firebase Console → **Authentication**
2. Click **Sign-in method** tab
3. Enable **Google** provider
4. Add support email
5. Click **Save**

### 2. Enable Email/Password Authentication

1. Same screen as above
2. Enable **Email/Password** provider
3. Click **Save**

### 3. Set Up Storage Rules

Go to Firebase Console → **Storage** → **Rules**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Profile images
    match /profiles/{userId}/{fileName} {
      allow read: if true; // Public read
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Verification documents (admin & owner only)
    match /verifications/{caretakerId}/{fileName} {
      allow read: if request.auth != null && 
                     (request.auth.uid == caretakerId || 
                      exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null && request.auth.uid == caretakerId;
    }
    
    // Care plan documents
    match /care_plans/{caretakerId}/{fileName} {
      allow read: if request.auth != null && request.auth.uid == caretakerId;
      allow write: if request.auth != null && request.auth.uid == caretakerId;
    }
    
    // Default deny
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 🚀 Step 4: Test All Permissions

### Test as Public User (No Login):
- ✅ Search caretakers → Should work
- ✅ View caretaker profiles → Should work
- ✅ Create booking → Should work
- ✅ Leave review → Should work
- ❌ View other users' data → Should fail

### Test as Caretaker:
- ✅ Read all caretaker profiles → Should work
- ✅ Update own profile → Should work
- ✅ Read own bookings → Should work
- ✅ Update booking status → Should work
- ✅ Read own notifications → Should work
- ❌ Update other caretakers' profiles → Should fail
- ❌ Delete users → Should fail

### Test as Admin:
- ✅ Read all collections → Should work
- ✅ Update any document → Should work
- ✅ Delete any document → Should work
- ✅ Approve verifications → Should work
- ✅ View audit logs → Should work

---

## 📊 Permission Summary

| Collection | Public | Caretaker | Admin |
|-----------|--------|-----------|-------|
| **users** | ❌ No access | ✅ Read all, Update own | ✅ Full access |
| **caretaker_profiles** | ✅ Read all | ✅ Read all, Update own | ✅ Full access |
| **bookings** | ✅ Create only | ✅ Read/Update own | ✅ Full access |
| **reviews** | ✅ Read/Create | ✅ Read all | ✅ Full access |
| **notifications** | ❌ No access | ✅ Read/Update own | ✅ Full access |
| **verifications** | ❌ No access | ✅ Create/Read own | ✅ Full access |
| **chats** | ❌ No access | ✅ Read/Write own | ✅ Full access |
| **care_plans** | ❌ No access | ✅ Read/Write own | ✅ Full access |
| **earnings** | ❌ No access | ✅ Read own | ✅ Full access |
| **payments** | ✅ Create only | ✅ Read own | ✅ Full access |
| **availability** | ✅ Read all | ✅ Update own | ✅ Full access |
| **services** | ✅ Read all | ✅ Read all | ✅ Full access |
| **audit_logs** | ❌ No access | ❌ No access | ✅ Full access |

---

## 🔗 Important Links

### Firebase Console Links:
1. **Project Overview**: https://console.firebase.google.com/project/flowing-bazaar-468814-g0/overview
2. **Firestore Rules**: https://console.firebase.google.com/project/flowing-bazaar-468814-g0/firestore/rules
3. **Firestore Indexes**: https://console.firebase.google.com/project/flowing-bazaar-468814-g0/firestore/indexes
4. **Authentication**: https://console.firebase.google.com/project/flowing-bazaar-468814-g0/authentication/users
5. **Storage Rules**: https://console.firebase.google.com/project/flowing-bazaar-468814-g0/storage/rules
6. **Database (Firestore)**: https://console.firebase.google.com/project/flowing-bazaar-468814-g0/firestore/databases/-default-/data

### Admin Credentials:
- **Email**: admin@carematch.com
- **Password**: Admin123!

---

## ⚠️ Important Notes

### Security Best Practices:
1. ✅ **Public read** enabled for search (caretaker_profiles)
2. ✅ **Guest booking** enabled (anyone can create booking)
3. ✅ **Role-based access** for admin/caretaker
4. ✅ **Owner-only updates** for personal data
5. ✅ **Admin approval** required for verifications

### Deployment Checklist:
- [ ] Deploy Firestore rules
- [ ] Create all composite indexes
- [ ] Enable Google Sign-In
- [ ] Enable Email/Password auth
- [ ] Deploy Storage rules
- [ ] Test public search
- [ ] Test booking creation
- [ ] Test caretaker dashboard
- [ ] Test admin panel

---

## 🧪 Quick Test Commands

### Test in Browser Console (Chrome DevTools):

```javascript
// Test public read (should work)
firebase.firestore().collection('caretaker_profiles').get()
  .then(snapshot => console.log('✅ Public read works:', snapshot.size))
  .catch(error => console.error('❌ Public read failed:', error));

// Test booking creation (should work without login)
firebase.firestore().collection('bookings').add({
  caretakerId: 'test123',
  serviceType: 'Elderly Care',
  status: 'pending',
  createdAt: new Date()
})
  .then(() => console.log('✅ Guest booking works'))
  .catch(error => console.error('❌ Guest booking failed:', error));
```

---

## 📞 Support

If you encounter permission errors:

1. Check browser console for specific error
2. Verify rules are deployed in Firebase Console
3. Check if indexes are created
4. Ensure user has correct role in Firestore
5. Clear browser cache and try again

---

## ✅ Deployment Status

After deploying, mark these as complete:

- [ ] Firestore rules deployed
- [ ] All 7 indexes created
- [ ] Google Sign-In enabled
- [ ] Storage rules deployed
- [ ] Tested public search ✅
- [ ] Tested guest booking ✅
- [ ] Tested caretaker features ✅
- [ ] Tested admin features ✅

---

Ready to deploy! 🚀

**Next Step**: Copy `firestore_rules_COMPLETE.rules` content to Firebase Console → Firestore → Rules → Publish
