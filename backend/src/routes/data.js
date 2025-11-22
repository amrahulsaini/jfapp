const express = require('express');
const router = express.Router();
const { verifyToken, optionalAuth } = require('../middleware/auth');
const { query } = require('../config/database');

// GET /api/data/students - Get all students from 2428main table
router.get('/students', async (req, res) => {
  try {
    console.log('Fetching all students from 2428main table...');
    const students = await query(
      'SELECT roll_no, enrollment_no, student_name, father_name, mother_name, branch, mobile_no, student_emailid, student_section FROM `2428main` ORDER BY roll_no ASC'
    );
    
    console.log(`Successfully fetched ${students.length} students`);
    res.json({
      success: true,
      message: 'Students retrieved successfully',
      data: students
    });

  } catch (error) {
    console.error('Get students error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch students data' 
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
