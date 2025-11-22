require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');

const app = express();
const PORT = process.env.PORT || 3001;
const path = require('path');

// Middleware
app.use(helmet()); // Security headers
app.use(compression()); // Compress responses
app.use(morgan('combined')); // Logging

// Serve static files from public directory
app.use(express.static(path.join(__dirname, '../public')));

// CORS configuration - Allow localhost for development
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    const allowedOrigins = process.env.ALLOWED_ORIGINS ? 
      process.env.ALLOWED_ORIGINS.split(',') : 
      ['https://jecrcfoundation.live', 'http://localhost:50488', 'http://localhost:3000'];
    
    // Allow localhost in development
    if (origin.includes('localhost') || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(null, true); // Allow all for now
    }
  },
  credentials: true,
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV 
  });
});

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const dataRoutes = require('./routes/data');
const resultsRoutes = require('./routes/results');
const paymentRoutes = require('./routes/payment');
const notificationRoutes = require('./routes/notifications');

// API routes
const API_PREFIX = process.env.API_PREFIX || '/api';
app.use(`${API_PREFIX}/auth`, authRoutes);
app.use(`${API_PREFIX}/users`, userRoutes);
app.use(`${API_PREFIX}/data`, dataRoutes);
app.use(`${API_PREFIX}/results`, resultsRoutes);
app.use(`${API_PREFIX}/payment`, paymentRoutes);
app.use(`${API_PREFIX}/notifications`, notificationRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: '🎉 JF App Backend API - Auto-Deployment Working!',
    version: '2.0.0',
    status: 'Auto-deployed via GitHub Webhooks',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/health',
      api: API_PREFIX,
      auth: {
        login: `${API_PREFIX}/auth/login`,
        register: `${API_PREFIX}/auth/register`
      },
      users: {
        profile: `${API_PREFIX}/users/profile`
      }
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Not Found',
    message: 'The requested endpoint does not exist'
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 API Base URL: http://localhost:${PORT}${API_PREFIX}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, closing server gracefully...');
  process.exit(0);
});
