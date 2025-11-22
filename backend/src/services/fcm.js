const admin = require('firebase-admin');
const { query } = require('../config/database');

// Initialize Firebase Admin (add your service account key)
// Download from: Firebase Console > Project Settings > Service Accounts > Generate New Private Key
try {
  const serviceAccount = require('../../firebase-service-account.json');
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  
  console.log('Firebase Admin initialized successfully');
} catch (error) {
  console.error('Firebase Admin initialization failed:', error.message);
}

// Save FCM token
async function saveFCMToken(email, fcmToken, deviceType = 'android') {
  try {
    await query(
      `INSERT INTO 2428fcm_tokens (email, fcm_token, device_type) 
       VALUES (?, ?, ?) 
       ON DUPLICATE KEY UPDATE 
       fcm_token = VALUES(fcm_token), 
       device_type = VALUES(device_type),
       updated_at = CURRENT_TIMESTAMP`,
      [email, fcmToken, deviceType]
    );
    return { success: true };
  } catch (error) {
    console.error('Error saving FCM token:', error);
    throw error;
  }
}

// Send notification to specific user
async function sendNotificationToUser(email, title, body, data = {}) {
  try {
    const tokens = await query(
      'SELECT fcm_token FROM 2428fcm_tokens WHERE email = ?',
      [email]
    );
    
    if (tokens.length === 0) {
      return { success: false, message: 'No FCM token found for user' };
    }
    
    const fcmTokens = tokens.map(t => t.fcm_token);
    
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: data,
      tokens: fcmTokens,
    };
    
    const response = await admin.messaging().sendEachForMulticast(message);
    
    // Remove invalid tokens
    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          invalidTokens.push(fcmTokens[idx]);
        }
      });
      
      if (invalidTokens.length > 0) {
        await query(
          `DELETE FROM 2428fcm_tokens WHERE fcm_token IN (${invalidTokens.map(() => '?').join(',')})`,
          invalidTokens
        );
      }
    }
    
    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
}

// Send notification to all users
async function sendNotificationToAll(title, body, data = {}) {
  try {
    const tokens = await query('SELECT DISTINCT fcm_token FROM 2428fcm_tokens');
    
    if (tokens.length === 0) {
      return { success: false, message: 'No FCM tokens found' };
    }
    
    const fcmTokens = tokens.map(t => t.fcm_token);
    
    // Firebase limits batch size to 500
    const batchSize = 500;
    let totalSuccess = 0;
    let totalFailure = 0;
    
    for (let i = 0; i < fcmTokens.length; i += batchSize) {
      const batch = fcmTokens.slice(i, i + batchSize);
      
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: data,
        tokens: batch,
      };
      
      const response = await admin.messaging().sendEachForMulticast(message);
      totalSuccess += response.successCount;
      totalFailure += response.failureCount;
      
      // Remove invalid tokens
      if (response.failureCount > 0) {
        const invalidTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            invalidTokens.push(batch[idx]);
          }
        });
        
        if (invalidTokens.length > 0) {
          await query(
            `DELETE FROM 2428fcm_tokens WHERE fcm_token IN (${invalidTokens.map(() => '?').join(',')})`,
            invalidTokens
          );
        }
      }
    }
    
    return {
      success: true,
      totalSent: fcmTokens.length,
      successCount: totalSuccess,
      failureCount: totalFailure,
    };
  } catch (error) {
    console.error('Error sending notification to all:', error);
    throw error;
  }
}

// Send personalized notifications to all users
async function sendPersonalizedNotifications(title, bodyTemplate) {
  try {
    // Get all users with tokens and their names
    const users = await query(`
      SELECT DISTINCT ft.email, ft.fcm_token, u.student_name 
      FROM 2428fcm_tokens ft
      LEFT JOIN user_sessions u ON ft.email = u.email
    `);
    
    if (users.length === 0) {
      return { success: false, message: 'No users found' };
    }
    
    let successCount = 0;
    let failureCount = 0;
    
    // Send individual notifications
    for (const user of users) {
      const studentName = user.student_name || 'Student';
      const body = bodyTemplate.replace('{student_name}', studentName);
      
      try {
        await admin.messaging().send({
          notification: {
            title: title,
            body: body,
          },
          token: user.fcm_token,
        });
        successCount++;
      } catch (error) {
        failureCount++;
        // Remove invalid token
        if (error.code === 'messaging/invalid-registration-token' || 
            error.code === 'messaging/registration-token-not-registered') {
          await query('DELETE FROM 2428fcm_tokens WHERE fcm_token = ?', [user.fcm_token]);
        }
      }
    }
    
    return {
      success: true,
      totalUsers: users.length,
      successCount,
      failureCount,
    };
  } catch (error) {
    console.error('Error sending personalized notifications:', error);
    throw error;
  }
}

module.exports = {
  saveFCMToken,
  sendNotificationToUser,
  sendNotificationToAll,
  sendPersonalizedNotifications,
};
