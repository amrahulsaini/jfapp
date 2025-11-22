const jwt = require('jsonwebtoken');
const { query } = require('../config/database');

// Verify session token from user_sessions table
const verifySessionToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  
  if (!authHeader) {
    return res.status(403).json({ 
      error: 'No token provided',
      message: 'Authentication token is required' 
    });
  }

  const token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : authHeader;

  try {
    // Check if it's a valid session token
    const sessions = await query(
      'SELECT * FROM user_sessions WHERE session_token = ? AND is_verified = TRUE AND expires_at > NOW()',
      [token]
    );

    if (sessions.length === 0) {
      return res.status(401).json({ 
        error: 'Unauthorized',
        message: 'Invalid or expired session token' 
      });
    }

    const session = sessions[0];
    req.userEmail = session.email;
    req.userId = session.email; // Use email as userId for compatibility
    req.user = { id: session.email, email: session.email };
    next();
  } catch (error) {
    console.error('Session verification error:', error);
    return res.status(500).json({ 
      error: 'Server error',
      message: 'Error verifying session' 
    });
  }
};

// Verify JWT token middleware (kept for backward compatibility)
const verifyToken = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1] || req.headers['x-access-token'];

  if (!token) {
    return res.status(403).json({ 
      error: 'No token provided',
      message: 'Authentication token is required' 
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id;
    req.userEmail = decoded.email;
    req.user = { id: decoded.id, email: decoded.email };
    next();
  } catch (error) {
    return res.status(401).json({ 
      error: 'Unauthorized',
      message: 'Invalid or expired token' 
    });
  }
};

// Optional token verification (doesn't fail if no token)
const optionalAuth = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1] || req.headers['x-access-token'];

  if (!token) {
    return next();
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id;
    req.userEmail = decoded.email;
  } catch (error) {
    // Token invalid but continue anyway
    console.log('Invalid token in optional auth:', error.message);
  }
  
  next();
};

// Generate JWT token
const generateToken = (userId, email) => {
  return jwt.sign(
    { id: userId, email: email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

module.exports = {
  verifyToken,
  verifySessionToken, // NEW: Session-based auth for payment routes
  authenticateToken: verifySessionToken, // Use session token by default
  optionalAuth,
  generateToken
};
