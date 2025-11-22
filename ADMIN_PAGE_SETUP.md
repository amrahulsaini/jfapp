# Admin Notification Page Setup

## Step 1: Upload the Page

Upload `send-notification.html` to your server:

```bash
# Upload to your website
scp send-notification.html user@jecrcfoundation.live:/home/jecrcfoundation.live/public_html/admin/
```

## Step 2: Access the Page

Open in browser:
**https://jecrcfoundation.live/admin/send-notification.html**

## Step 3: Test Notifications

Since your users already have the app installed:

1. **Open the admin page** in your browser
2. **Type a message**:
   - Title: `📢 Welcome to JF App!`
   - Message: `Hey {student_name}, thanks for downloading the app!`
3. **Click "Send Personalized to All"**
4. **All users will receive the notification instantly!**

## Important Notes:

### Users MUST Open App First
❌ **Problem**: If users just downloaded the APK but haven't opened it yet, they won't receive notifications.

✅ **Solution**: Users need to:
1. Open the app
2. Login with their email
3. The app will automatically save their FCM token
4. Then they'll start receiving notifications

### Test Notification Ideas:

**Welcome Message:**
```
Title: 🎉 Welcome!
Message: Hey {student_name}, thanks for joining JF App! Check your results anytime.
```

**Results Alert:**
```
Title: 📢 Results Published!
Message: Hey {student_name}, your semester results are now available!
```

**Update Reminder:**
```
Title: 🔔 Important Update
Message: {student_name}, please update the app to get new features!
```

## Security Recommendation:

Add password protection to the admin page:

```html
<!-- Add at the top of send-notification.html -->
<script>
const ADMIN_PASSWORD = 'your_secure_password_here';
const enteredPassword = prompt('Enter admin password:');
if (enteredPassword !== ADMIN_PASSWORD) {
    alert('Access denied!');
    window.location.href = '/';
}
</script>
```

## Usage:

1. Open: `https://jecrcfoundation.live/admin/send-notification.html`
2. Fill in title and message
3. Use `{student_name}` for personalization
4. Click send
5. All logged-in users receive notification instantly!

The page is now live and ready to use! 🚀
