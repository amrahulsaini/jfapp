const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const { query } = require('../config/database');
const { sendOTPEmail } = require('../services/email');

// Allowed batches
const ALLOWED_BATCHES = ['2024-2028', '2023-2027', '2025-2029'];
const ALLOWED_EMAIL_DOMAIN = '@jecrc.ac.in';

// Generate 6-digit OTP
function generateOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

// Generate session token
function generateSessionToken() {
    return crypto.randomBytes(32).toString('hex');
}

// POST /api/auth/send-otp - Send OTP to email
router.post('/send-otp', async (req, res) => {
    try {
        const { email, batch, deviceInfo, ipAddress } = req.body;

        // Validate input
        if (!email || !batch) {
            return res.status(400).json({
                success: false,
                message: 'Email and batch are required'
            });
        }

        // Validate email domain
        if (!email.toLowerCase().endsWith(ALLOWED_EMAIL_DOMAIN)) {
            return res.status(403).json({
                success: false,
                message: 'Only JECRC college emails (@jecrc.ac.in) are allowed'
            });
        }

        // Validate batch
        if (!ALLOWED_BATCHES.includes(batch)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid batch. Allowed batches: ' + ALLOWED_BATCHES.join(', ')
            });
        }

        // Generate OTP and session token
        const otp = generateOTP();
        const sessionToken = generateSessionToken();
        const expiresAt = new Date(Date.now() + (parseInt(process.env.OTP_EXPIRY_MINUTES || 10) * 60 * 1000));

        // Delete any existing unverified sessions for this email
        await query(
            'DELETE FROM user_sessions WHERE email = ? AND is_verified = FALSE',
            [email]
        );

        // Insert new session
        await query(
            'INSERT INTO user_sessions (email, batch, otp_code, session_token, device_info, ip_address, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [email, batch, otp, sessionToken, deviceInfo || null, ipAddress || null, expiresAt]
        );

        // Send OTP email
        await sendOTPEmail(email, otp);

        res.json({
            success: true,
            message: 'OTP sent successfully',
            data: {
                email,
                expiresIn: parseInt(process.env.OTP_EXPIRY_MINUTES || 10)
            }
        });
    } catch (error) {
        console.error('Send OTP error:', error);
        res.status(500).json({
            success: false,
            message: 'Error sending OTP. Please try again.'
        });
    }
});

// POST /api/auth/verify-otp - Verify OTP and create session
router.post('/verify-otp', async (req, res) => {
    try {
        const { email, otp } = req.body;

        // Validate input
        if (!email || !otp) {
            return res.status(400).json({
                success: false,
                message: 'Email and OTP are required'
            });
        }

        // Find session with matching email and OTP
        const sessions = await query(
            'SELECT * FROM user_sessions WHERE email = ? AND otp_code = ? AND is_verified = FALSE AND expires_at > NOW()',
            [email, otp]
        );

        if (sessions.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Invalid or expired OTP'
            });
        }

        const session = sessions[0];

        // Check if student exists in 2428main table (active batch)
        let studentData = null;
        try {
            const students = await query(
                'SELECT roll_no, enrollment_no, student_name, father_name, mother_name, branch, mobile_no, student_emailid, student_section FROM `2428main` WHERE student_emailid = ?',
                [email]
            );

            if (students.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Student not found in active batch. Please contact jecrc@jecrcfoundation.live'
                });
            }

            studentData = students[0];
        } catch (dbError) {
            console.error('Database query error:', dbError);
            return res.status(500).json({
                success: false,
                message: 'Error verifying student data'
            });
        }

        // Update session: mark as verified and extend expiry to 30 days
        const newExpiresAt = new Date(Date.now() + (parseInt(process.env.SESSION_EXPIRY_DAYS || 30) * 24 * 60 * 60 * 1000));
        
        await query(
            'UPDATE user_sessions SET is_verified = TRUE, verified_at = NOW(), expires_at = ? WHERE id = ?',
            [newExpiresAt, session.id]
        );

        res.json({
            success: true,
            message: 'OTP verified successfully',
            data: {
                sessionToken: session.session_token,
                email: session.email,
                batch: session.batch,
                expiresAt: newExpiresAt,
                student: studentData
            }
        });
    } catch (error) {
        console.error('Verify OTP error:', error);
        res.status(500).json({
            success: false,
            message: 'Error verifying OTP'
        });
    }
});

// GET /api/auth/check-session - Validate session token and get student data
router.get('/check-session', async (req, res) => {
    try {
        const authHeader = req.headers.authorization;
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: 'No session token provided'
            });
        }

        const sessionToken = authHeader.substring(7);

        // Find valid session
        const sessions = await query(
            'SELECT * FROM user_sessions WHERE session_token = ? AND is_verified = TRUE AND expires_at > NOW()',
            [sessionToken]
        );

        if (sessions.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Invalid or expired session'
            });
        }

        const session = sessions[0];

        // Get student data from batch table
        // Extract first 4 digits (e.g., "2024-2028" -> "2428")
        const batchTable = session.batch.substring(2, 4) + session.batch.substring(7, 9);
        const tableName = `${batchTable}main`;
        
        console.log('Checking session for batch:', session.batch, 'table:', tableName, 'email:', session.email);
        
        let studentData = null;
        try {
            const students = await query(
                `SELECT roll_no, enrollment_no, student_name, father_name, mother_name, branch, mobile_no, student_emailid, student_section FROM \`${tableName}\` WHERE student_emailid = ?`,
                [session.email]
            );

            console.log('Students found:', students.length);
            
            if (students.length > 0) {
                studentData = students[0];
            } else {
                console.error('No student found in table', tableName, 'for email', session.email);
            }
        } catch (dbError) {
            console.error('Database query error for table', tableName, ':', dbError);
        }

        res.json({
            success: true,
            message: 'Session is valid',
            data: {
                email: session.email,
                batch: session.batch,
                expiresAt: session.expires_at,
                student: studentData
            }
        });
    } catch (error) {
        console.error('Check session error:', error);
        res.status(500).json({
            success: false,
            message: 'Error checking session'
        });
    }
});

// POST /api/auth/logout - Logout and delete session
router.post('/logout', async (req, res) => {
    try {
        const authHeader = req.headers.authorization;
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: 'No session token provided'
            });
        }

        const sessionToken = authHeader.substring(7);

        // Delete session
        await query(
            'DELETE FROM user_sessions WHERE session_token = ?',
            [sessionToken]
        );

        res.json({
            success: true,
            message: 'Logged out successfully'
        });
    } catch (error) {
        console.error('Logout error:', error);
        res.status(500).json({
            success: false,
            message: 'Error logging out'
        });
    }
});

module.exports = router;
