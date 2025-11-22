const express = require('express');
const router = express.Router();
const db = require('../config/database');

// Get student results by roll number
router.get('/:rollNo', async (req, res) => {
  try {
    const { rollNo } = req.params;

    // Query the 2ndsemresults table
    const [results] = await db.execute(
      `SELECT 
        course_title,
        course_code,
        marks_midterm,
        marks_endterm,
        grade,
        sgpa,
        remarks,
        subject_pdf_path
      FROM 2ndsemresults
      WHERE roll_no = ?
      ORDER BY course_code ASC`,
      [rollNo]
    );

    if (results.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No results found for this student'
      });
    }

    res.json({
      success: true,
      results: results
    });
  } catch (error) {
    console.error('Error fetching results:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch results'
    });
  }
});

module.exports = router;
