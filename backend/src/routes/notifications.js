const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const fcmService = require('../services/fcm');

// Save FCM token
router.post('/save-token', authenticateToken, async (req, res) => {
  try {
    const { fcm_token, device_type } = req.body;
    
    if (!fcm_token) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required'
      });
    }
    
    await fcmService.saveFCMToken(req.user.email, fcm_token, device_type);
    
    res.json({
      success: true,
      message: 'FCM token saved successfully'
    });
  } catch (error) {
    console.error('Save FCM token error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to save FCM token'
    });
  }
});

// Send notification to all users (admin only)
router.post('/send-to-all', async (req, res) => {
  try {
    const { title, body, data } = req.body;
    
    if (!title || !body) {
      return res.status(400).json({
        success: false,
        message: 'Title and body are required'
      });
    }
    
    const result = await fcmService.sendNotificationToAll(title, body, data || {});
    
    res.json(result);
  } catch (error) {
    console.error('Send notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send notification'
    });
  }
});

// Send personalized notification to all users
router.post('/send-personalized', async (req, res) => {
  try {
    const { title, body_template } = req.body;
    
    if (!title || !body_template) {
      return res.status(400).json({
        success: false,
        message: 'Title and body_template are required'
      });
    }
    
    // body_template should contain {student_name} placeholder
    // Example: "Hey {student_name}, check all the results now!"
    
    const result = await fcmService.sendPersonalizedNotifications(title, body_template);
    
    res.json(result);
  } catch (error) {
    console.error('Send personalized notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send personalized notifications'
    });
  }
});

// Send notification to specific user
router.post('/send-to-user', async (req, res) => {
  try {
    const { email, title, body, data } = req.body;
    
    if (!email || !title || !body) {
      return res.status(400).json({
        success: false,
        message: 'Email, title, and body are required'
      });
    }
    
    const result = await fcmService.sendNotificationToUser(email, title, body, data || {});
    
    res.json(result);
  } catch (error) {
    console.error('Send notification to user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send notification'
    });
  }
});

module.exports = router;
