# 🔐 Create Admin User in Firebase

## Admin Credentials:
- **Email:** `admin@carematch.com`
- **Password:** `Admin123!`

---

## Method 1: Firebase Console (Easiest - Do This Now!)

### Step 1: Create Admin in Firebase Authentication

1. **Open Firebase Console:**
   https://console.firebase.google.com/project/flowing-bazaar-468814-g0/authentication/users

2. **Click "Add user"**

3. **Enter:**
   - Email: `admin@carematch.com`
   - Password: `Admin123!`

4. **Click "Add user"**

5. **Copy the UID** that Firebase generates (you'll need it in next step)
   - Example: `abc123xyz456` (will be longer)

---

### Step 2: Create Admin Document in Firestore

1. **Open Firestore:**
   https://console.firebase.google.com/project/flowing-bazaar-468814-g0/firestore/databases/-default-/data

2. **Go to `users` collection** (or create it if it doesn't exist)

3. **Click "Add document"**

4. **Document ID:** Use the **UID from Step 1** (the one Firebase Auth generated)

5. **Add these fields:**

```
uid: "THE_UID_FROM_STEP_1"  (string)
id: "THE_UID_FROM_STEP_1"  (string)
email: "admin@carematch.com"  (string)
firstName: "System"  (string)
lastName: "Administrator"  (string)
role: "admin"  (string) ⚠️ IMPORTANT: lowercase "admin"
status: "active"  (string)
createdAt: "2025-11-12T00:00:00.000Z"  (string)
updatedAt: "2025-11-12T00:00:00.000Z"  (string)
phone: null  (null)
profileImage: null  (null)
```

6. **Click "Save"**

---

## ✅ Test Admin Login

1. Go to your app
2. Click "Admin Login"
3. Enter:
   - Email: `admin@carematch.com`
   - Password: `Admin123!`
4. Click "Sign In"

**You should see:**
- ✅ Login successful
- ✅ Admin dashboard loads
- ✅ All 3 caretakers showing
- ✅ No permission errors

---

## 🚨 Important Notes:

### The `role` field MUST be lowercase:
- ✅ Correct: `"admin"`
- ❌ Wrong: `"Admin"` or `"ADMIN"`

### Use the SAME UID in both places:
- Firebase Auth UID = Firestore document ID = `uid` field value

---

## Method 2: Quick Script (Alternative)

If you want, I can create a Flutter admin setup screen that creates the admin user automatically. Let me know!

---

## 🎯 Summary

**Just create the admin user in Firebase Console with these exact values:**

1. **Authentication:** `admin@carematch.com` / `Admin123!`
2. **Firestore users collection:** Document with `role: "admin"`
3. **Login with:** `admin@carematch.com` / `Admin123!`

Done! 🚀
