-- JF Foundation App Database Schema
-- Database: jecr_app
-- User: jecr_app
-- Password: app

-- Create database (if not exists)
CREATE DATABASE IF NOT EXISTS jecr_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE jecr_app;

-- Table: user_sessions
-- Stores active user sessions with email, batch, and 30-day expiry
CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    batch VARCHAR(20) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    device_info TEXT,
    ip_address VARCHAR(45),
    is_verified BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP NULL,
    INDEX idx_email (email),
    INDEX idx_session_token (session_token),
    INDEX idx_otp (email, otp_code),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Cleanup expired sessions
CREATE EVENT IF NOT EXISTS cleanup_expired_sessions
ON SCHEDULE EVERY 1 DAY
DO
DELETE FROM user_sessions WHERE expires_at < NOW();

-- Show tables
SHOW TABLES;

-- Display structure
DESCRIBE user_sessions;

-- Success message
SELECT 'Database schema created successfully!' AS message;
