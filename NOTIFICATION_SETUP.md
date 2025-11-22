# Push Notification Setup Guide

## Step 1: Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **jffoundation-f1dab**
3. Click ⚙️ (Settings) > **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Download the JSON file
7. Rename it to `firebase-service-account.json`
8. Upload to: `/home/jecrcfoundation.live/work/backend/firebase-service-account.json`

## Step 2: Install Dependencies

```bash
cd /home/jecrcfoundation.live/work/backend
npm install firebase-admin
```

## Step 3: Create FCM Tokens Table

Run the SQL file:
```bash
mysql -u jecrcfoundation_jf -p jecrcfoundation_jf < database-fcm-tokens.sql
```

## Step 4: Restart Backend

```bash
pm2 restart jf-backend
```

## Step 5: Test Notification System

### From Website/Admin Panel:

**Send to All Users:**
```bash
curl -X POST https://jecrcfoundation.live/api/notifications/send-to-all \
  -H "Content-Type: application/json" \
  -d '{
    "title": "📢 Results Published!",
    "body": "All semester results are now available. Check yours now!"
  }'
```

**Send Personalized to All:**
```bash
curl -X POST https://jecrcfoundation.live/api/notifications/send-personalized \
  -H "Content-Type: application/json" \
  -d '{
    "title": "📢 Results Available",
    "body_template": "Hey {student_name}, check all your results now!"
  }'
```

**Send to Specific User:**
```bash
curl -X POST https://jecrcfoundation.live/api/notifications/send-to-user \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@example.com",
    "title": "Payment Received",
    "body": "Your premium plan has been activated!"
  }'
```

## Step 6: Create Admin Notification Page

Create `send-notification.html` on your website:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Send Notifications - JF App Admin</title>
    <style>
        body { font-family: Arial; max-width: 600px; margin: 50px auto; padding: 20px; }
        input, textarea, button { width: 100%; padding: 10px; margin: 10px 0; }
        button { background: #FF6B00; color: white; border: none; cursor: pointer; }
        button:hover { background: #e56100; }
        .result { margin-top: 20px; padding: 15px; background: #f0f0f0; }
    </style>
</head>
<body>
    <h1>📢 Send Push Notifications</h1>
    
    <h3>Send to All Users</h3>
    <input type="text" id="title" placeholder="Notification Title" value="📢 Results Published!">
    <textarea id="body" placeholder="Notification Body" rows="3">All semester results are now available. Check yours now!</textarea>
    <button onclick="sendToAll()">Send to All</button>
    
    <h3>Send Personalized</h3>
    <input type="text" id="pTitle" placeholder="Title" value="📢 Hey there!">
    <textarea id="pBody" placeholder="Body (use {student_name} for name)" rows="3">Hey {student_name}, check all your results now!</textarea>
    <button onclick="sendPersonalized()">Send Personalized to All</button>
    
    <div id="result" class="result" style="display:none;"></div>
    
    <script>
        async function sendToAll() {
            const title = document.getElementById('title').value;
            const body = document.getElementById('body').value;
            
            const response = await fetch('https://jecrcfoundation.live/api/notifications/send-to-all', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ title, body })
            });
            
            const data = await response.json();
            showResult(data);
        }
        
        async function sendPersonalized() {
            const title = document.getElementById('pTitle').value;
            const body_template = document.getElementById('pBody').value;
            
            const response = await fetch('https://jecrcfoundation.live/api/notifications/send-personalized', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ title, body_template })
            });
            
            const data = await response.json();
            showResult(data);
        }
        
        function showResult(data) {
            const resultDiv = document.getElementById('result');
            resultDiv.style.display = 'block';
            resultDiv.innerHTML = `
                <strong>${data.success ? '✅ Success!' : '❌ Failed'}</strong><br>
                ${data.successCount ? `Sent: ${data.successCount}<br>` : ''}
                ${data.failureCount ? `Failed: ${data.failureCount}<br>` : ''}
                ${data.message || ''}
            `;
        }
    </script>
</body>
</html>
```

## Usage Examples:

### 1. Results Published
```json
{
  "title": "📢 Results Published!",
  "body": "Semester 3 results are now available. Check yours now!"
}
```

### 2. Personalized Welcome
```json
{
  "title": "Welcome!",
  "body_template": "Hey {student_name}, thanks for joining JF App!"
}
```

### 3. Payment Reminder
```json
{
  "title": "⚠️ Plan Expiring Soon",
  "body_template": "Hi {student_name}, your premium plan expires in 3 days!"
}
```

## How It Works:

1. **App stores FCM token** when user logs in
2. **Backend saves token** in database with email
3. **You send notification** from website
4. **Firebase delivers** to all user devices
5. **Users see notification** instantly!

## Security Notes:

- Keep `firebase-service-account.json` private (don't commit to Git)
- Add authentication to notification endpoints in production
- Rate limit the notification API to prevent abuse
