const express = require('express');
const router = express.Router();
const { verifyToken, optionalAuth } = require('../middleware/auth');
const { query } = require('../config/database');

// GET /api/data/public - Get public data (no auth required)
router.get('/public', async (req, res) => {
  try {
    // Example: Fetch public data from your PHP database
    const data = await query('SELECT * FROM your_table LIMIT 10');

    res.json({
      message: 'Public data retrieved successfully',
      data: data
    });

  } catch (error) {
    console.error('Get public data error:', error);
    res.status(500).json({ 
      error: 'Failed to fetch data' 
    });
  }
});

// GET /api/data/protected - Get protected data (auth required)
router.get('/protected', verifyToken, async (req, res) => {
  try {
    // Example: Fetch user-specific data
    const data = await query(
      'SELECT * FROM your_table WHERE user_id = ?',
      [req.userId]
    );

    res.json({
      message: 'Protected data retrieved successfully',
      data: data
    });

  } catch (error) {
    console.error('Get protected data error:', error);
    res.status(500).json({ 
      error: 'Failed to fetch data' 
    });
  }
});

// POST /api/data/items - Create new item (auth required)
router.post('/items', verifyToken, async (req, res) => {
  try {
    const { title, description } = req.body;

    if (!title) {
      return res.status(400).json({ 
        error: 'Title is required' 
      });
    }

    const result = await query(
      'INSERT INTO your_table (user_id, title, description, created_at) VALUES (?, ?, ?, NOW())',
      [req.userId, title, description || '']
    );

    res.status(201).json({
      message: 'Item created successfully',
      item: {
        id: result.insertId,
        title,
        description
      }
    });

  } catch (error) {
    console.error('Create item error:', error);
    res.status(500).json({ 
      error: 'Failed to create item' 
    });
  }
});

module.exports = router;
