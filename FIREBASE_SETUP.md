# Firebase Push Notifications Setup

## Features Added:
1. **My Plans Screen** - View active plans, purchase history, remaining views
2. **Push Notifications** - Get notified on:
   - Plan purchase success
   - Plan expiring soon (7 days before)
   - Plan expired
   - Low views remaining (when < 5 views left)

## Firebase Setup Instructions:

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: `jf-foundation-app`
4. Enable Google Analytics (optional)
5. Create project

### 2. Add Android App
1. In Firebase console, click "Add app" → Android
2. Enter package name: `com.jecrcfoundation.jf_app`
3. Download `google-services.json`
4. Place it in `frontend_temp/android/app/google-services.json`

### 3. Add iOS App (if needed)
1. Click "Add app" → iOS
2. Enter bundle ID: `com.jecrcfoundation.jfApp`
3. Download `GoogleService-Info.plist`
4. Place it in `frontend_temp/ios/Runner/GoogleService-Info.plist`

### 4. Update Firebase Options
Run FlutterFire CLI to generate proper config:
```bash
cd frontend_temp
flutter pub global activate flutterfire_cli
flutterfire configure
```

This will:
- Connect to your Firebase project
- Generate `lib/firebase_options.dart` with actual credentials
- Update Android/iOS configs

### 5. Update Android Gradle Files

**android/build.gradle** - Add at the top:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**android/app/build.gradle** - Add at the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 6. Update AndroidManifest.xml

Add permissions in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

Add inside `<application>` tag:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="jf_app_notifications" />
```

### 7. Enable Cloud Messaging
1. In Firebase Console → Project Settings
2. Go to "Cloud Messaging" tab
3. Copy the Server Key
4. Save it for backend integration

### 8. Backend Integration (Optional)
To send push notifications from backend:

**Install Firebase Admin SDK:**
```bash
cd backend
npm install firebase-admin
```

**Create notification service:**
```javascript
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(require('./firebase-service-account.json'))
});

async function sendNotification(fcmToken, title, body) {
  await admin.messaging().send({
    token: fcmToken,
    notification: { title, body },
    data: { /* custom data */ }
  });
}
```

## Testing Notifications:

### Local Testing (without backend):
The app already sends local notifications on payment success. Test by:
1. Purchase a plan
2. See notification appear

### Remote Testing (with Firebase):
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter title and text
4. Select your app
5. Send test message

## Notification Types:

### 1. Plan Purchase Success
- **Trigger**: After successful payment verification
- **Title**: "🎉 Plan Purchased Successfully!"
- **Body**: "You have purchased [Plan Name]. [X] results available."

### 2. Plan Expiring Soon
- **Trigger**: Backend cron job (7 days before expiry)
- **Title**: "⚠️ Plan Expiring Soon"
- **Body**: "Your [Plan Name] will expire in [X] days. [Y] views remaining."

### 3. Plan Expired
- **Trigger**: Backend cron job (on expiry date)
- **Title**: "❌ Plan Expired"
- **Body**: "Your [Plan Name] has expired. Purchase a new plan to continue."

### 4. Low Views
- **Trigger**: After viewing a result (when < 5 views left)
- **Title**: "⚡ Running Low on Views"
- **Body**: "Only [X] views left in your [Plan Name]. Consider upgrading!"

## Backend Cron Jobs (TODO):

Add to `backend/src/routes/payment.js`:

```javascript
// Check expiring plans daily
const cron = require('node-cron');

cron.schedule('0 9 * * *', async () => {
  // Get plans expiring in 7 days
  const expiringPlans = await query(`
    SELECT p.*, u.fcm_token 
    FROM 2428purchases p
    JOIN user_sessions u ON p.user_email = u.email
    WHERE p.expiry_date BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY)
    AND p.is_active = TRUE
  `);
  
  // Send notifications
  for (const plan of expiringPlans) {
    await sendNotification(plan.fcm_token, 
      '⚠️ Plan Expiring Soon',
      `Your ${plan.plan_name} expires in 7 days`
    );
  }
});
```

## Current Status:
✅ My Plans screen created
✅ Local notifications working
✅ Firebase packages installed
⏳ Firebase project needs setup
⏳ Backend cron jobs pending

## Next Steps:
1. Setup Firebase project
2. Run `flutterfire configure`
3. Test notifications
4. Add FCM token storage in backend
5. Implement cron jobs for expiry notifications
