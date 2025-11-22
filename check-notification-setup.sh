#!/bin/bash

echo "=== Checking JF App Backend Notification Setup ==="
echo ""

echo "1. Checking if notification routes exist:"
if [ -f "/home/jecrcfoundation.live/jf-app-backend/backend/src/routes/notifications.js" ]; then
    echo "   ✅ notifications.js exists"
else
    echo "   ❌ notifications.js NOT FOUND"
fi

echo ""
echo "2. Checking if FCM service exists:"
if [ -f "/home/jecrcfoundation.live/jf-app-backend/backend/src/services/fcm.js" ]; then
    echo "   ✅ fcm.js exists"
else
    echo "   ❌ fcm.js NOT FOUND"
fi

echo ""
echo "3. Checking if Firebase service account exists:"
if [ -f "/home/jecrcfoundation.live/jf-app-backend/backend/firebase-service-account.json" ]; then
    echo "   ✅ firebase-service-account.json exists"
else
    echo "   ❌ firebase-service-account.json NOT FOUND"
fi

echo ""
echo "4. Checking if firebase-admin is installed:"
cd /home/jecrcfoundation.live/jf-app-backend/backend
if npm list firebase-admin > /dev/null 2>&1; then
    echo "   ✅ firebase-admin is installed"
    npm list firebase-admin | grep firebase-admin
else
    echo "   ❌ firebase-admin NOT INSTALLED"
fi

echo ""
echo "5. Checking if FCM tokens table exists:"
mysql -u jecrcfoundation_jf -p"$DB_PASSWORD" jecrcfoundation_jf -e "SHOW TABLES LIKE '2428fcm_tokens';" 2>/dev/null | grep -q 2428fcm_tokens
if [ $? -eq 0 ]; then
    echo "   ✅ 2428fcm_tokens table exists"
    mysql -u jecrcfoundation_jf -p"$DB_PASSWORD" jecrcfoundation_jf -e "SELECT COUNT(*) as token_count FROM 2428fcm_tokens;" 2>/dev/null
else
    echo "   ❌ 2428fcm_tokens table NOT FOUND"
fi

echo ""
echo "6. Checking PM2 logs for Firebase initialization:"
pm2 logs jf-app-backend --lines 50 --nostream 2>/dev/null | grep -i "firebase" | tail -5

echo ""
echo "=== Check Complete ==="
