const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const { query } = require('../config/database');

// GET /api/users/profile - Get current user profile (protected)
router.get('/profile', verifyToken, async (req, res) => {
  try {
    const users = await query(
      'SELECT id, email, name, created_at FROM users WHERE id = ?',
      [req.userId]
    );

    if (users.length === 0) {
      return res.status(404).json({ 
        error: 'User not found' 
      });
    }

    res.json({
      user: users[0]
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ 
      error: 'Failed to fetch profile' 
    });
  }
});

// PUT /api/users/profile - Update user profile (protected)
router.put('/profile', verifyToken, async (req, res) => {
  try {
    const { name } = req.body;

    if (!name || name.trim() === '') {
      return res.status(400).json({ 
        error: 'Name is required' 
      });
    }

    await query(
      'UPDATE users SET name = ? WHERE id = ?',
      [name.trim(), req.userId]
    );

    res.json({
      message: 'Profile updated successfully',
      user: {
        id: req.userId,
        name: name.trim()
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ 
      error: 'Failed to update profile' 
    });
  }
});

module.exports = router;
