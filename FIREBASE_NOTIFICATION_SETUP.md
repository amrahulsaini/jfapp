# Firebase Push Notifications Setup Guide

## Current Status: ❌ NOT WORKING YET

Your notification system is built but needs these 3 steps to work:

---

## Step 1: Download Firebase Service Account Key

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project** (the one you created for the app)
3. Click **⚙️ Settings** (gear icon, top left)
4. Go to **Project Settings**
5. Click **Service Accounts** tab
6. Click **"Generate New Private Key"** button
7. **Download the JSON file** (it will be named like `jf-app-xxxxx-firebase-adminsdk-xxxxx.json`)
8. **Rename it to**: `firebase-service-account.json`

---

## Step 2: Upload Files to Server

### Using cPanel File Manager:

1. **Login to cPanel**: https://jecrcfoundation.live:2083
2. Open **File Manager**
3. Navigate to: `/home/jecrcfoundation.live/jf-app-backend/backend/`
4. **Upload** the `firebase-service-account.json` file
5. Set permissions to **644** (right-click → Change Permissions)

---

## Step 3: Install Firebase Admin SDK

**Option A: Using cPanel Terminal**
```bash
cd /home/jecrcfoundation.live/jf-app-backend/backend
npm install firebase-admin
pm2 restart jf-app-backend
```

**Option B: SSH (if you have access)**
```bash
ssh jecrcfoundation_jf@jecrcfoundation.live
cd jf-app-backend/backend
npm install firebase-admin
pm2 restart jf-app-backend
```

---

## Step 4: Create Database Table

**Using phpMyAdmin or MySQL:**

1. Login to **phpMyAdmin** from cPanel
2. Select database: `jecrcfoundation_jf`
3. Click **SQL** tab
4. Paste this and click **Go**:

```sql
CREATE TABLE IF NOT EXISTS `2428fcm_tokens` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(255) NOT NULL,
  `fcm_token` TEXT NOT NULL,
  `device_type` ENUM('android', 'ios') DEFAULT 'android',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_email_token` (`email`, `fcm_token`(255)),
  INDEX `idx_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## Step 5: Test Notifications

1. **Open your app** on your phone
2. **Login** with your email
3. The app will automatically save your FCM token
4. **Open admin page**: https://jecrcfoundation.live/api/admin/send-notification.html
5. **Send a test notification**:
   - Title: `🎉 Test Notification`
   - Message: `Hey {student_name}, this is a test!`
6. **Click "Send Personalized to All"**
7. You should receive the notification on your phone! 📲

---

## Verification Checklist

✅ **Check if setup is complete:**

1. **File exists**: `/home/jecrcfoundation.live/jf-app-backend/backend/firebase-service-account.json`
2. **Package installed**: Run `npm list firebase-admin` in backend directory
3. **Table exists**: Check phpMyAdmin for `2428fcm_tokens` table
4. **Backend restarted**: Run `pm2 restart jf-app-backend`
5. **Check logs**: Run `pm2 logs jf-app-backend` to see "Firebase Admin initialized successfully"

---

## Troubleshooting

### "Firebase Admin initialization failed"
- **Cause**: Service account file missing or invalid
- **Fix**: Re-download from Firebase Console and upload to server

### "No FCM token found for user"
- **Cause**: User hasn't opened the app and logged in yet
- **Fix**: Ask user to open app and login first

### "Error sending notification"
- **Cause**: Invalid FCM token or Firebase project mismatch
- **Fix**: Make sure Firebase project ID matches between app and backend

### Check Backend Logs:
```bash
pm2 logs jf-app-backend --lines 100
```

---

## Why Notifications Aren't Working Yet:

Currently, when you try to send a notification:

1. ❌ Backend tries to load `firebase-service-account.json` → **File doesn't exist**
2. ❌ Firebase Admin fails to initialize → **Cannot send notifications**
3. ❌ Admin page shows success but nothing happens → **Firebase not configured**

After completing all 5 steps above, notifications will work! ✅

---

## Quick Summary:

```bash
# 1. Download firebase-service-account.json from Firebase Console
# 2. Upload to: /home/jecrcfoundation.live/jf-app-backend/backend/
# 3. Run on server:
cd /home/jecrcfoundation.live/jf-app-backend/backend
npm install firebase-admin
pm2 restart jf-app-backend

# 4. Run SQL in phpMyAdmin (see above)
# 5. Test from admin page!
```

Once done, notifications will be sent to all users who have:
- Downloaded the APK
- Opened the app
- Logged in with their email

The FCM token is automatically saved when they login! 🚀
