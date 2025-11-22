-- Payment System Tables for JF App
-- All table names start with 2428 (batch prefix)

-- Plans table: Available payment plans
CREATE TABLE IF NOT EXISTS `2428plans` (
  `plan_id` INT PRIMARY KEY AUTO_INCREMENT,
  `plan_name` VARCHAR(50) NOT NULL,
  `plan_type` ENUM('basic_3', 'standard_5', 'premium') NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  `views_limit` INT DEFAULT NULL COMMENT 'NULL means unlimited for premium',
  `features` JSON COMMENT 'Additional features for the plan',
  `is_active` BOOLEAN DEFAULT TRUE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_plan_type (plan_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default plans
INSERT INTO `2428plans` (plan_name, plan_type, price, views_limit, features) VALUES
('Basic - 3 Students', 'basic_3', 1.00, 3, '{"can_view_results": true, "can_contact_support": false, "can_request_edits": false}'),
('Standard - 5 Students', 'standard_5', 21.00, 5, '{"can_view_results": true, "can_contact_support": false, "can_request_edits": false}'),
('Premium Access', 'premium', 51.00, NULL, '{"can_view_results": true, "can_contact_support": true, "can_request_edits": true, "unlimited_views": true}');

-- User purchases table: Track user plan purchases
CREATE TABLE IF NOT EXISTS `2428purchases` (
  `purchase_id` INT PRIMARY KEY AUTO_INCREMENT,
  `user_email` VARCHAR(255) NOT NULL,
  `plan_id` INT NOT NULL,
  `transaction_id` VARCHAR(255) NOT NULL,
  `amount_paid` DECIMAL(10,2) NOT NULL,
  `views_remaining` INT DEFAULT NULL COMMENT 'NULL for unlimited premium',
  `purchase_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `expiry_date` TIMESTAMP NULL COMMENT 'NULL means no expiry for premium',
  `is_active` BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (plan_id) REFERENCES `2428plans`(plan_id),
  INDEX idx_user_email (user_email),
  INDEX idx_transaction (transaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Transaction records: All payment transactions
CREATE TABLE IF NOT EXISTS `2428transactions` (
  `transaction_id` INT PRIMARY KEY AUTO_INCREMENT,
  `razorpay_order_id` VARCHAR(255) NOT NULL,
  `razorpay_payment_id` VARCHAR(255) DEFAULT NULL,
  `razorpay_signature` VARCHAR(500) DEFAULT NULL,
  `user_email` VARCHAR(255) NOT NULL,
  `plan_id` INT NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `currency` VARCHAR(10) DEFAULT 'INR',
  `status` ENUM('created', 'pending', 'success', 'failed', 'refunded') DEFAULT 'created',
  `payment_method` VARCHAR(50) DEFAULT NULL,
  `error_message` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_razorpay_order (razorpay_order_id),
  INDEX idx_user_email (user_email),
  INDEX idx_status (status),
  FOREIGN KEY (plan_id) REFERENCES `2428plans`(plan_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Result views tracking: Track which results user has viewed
CREATE TABLE IF NOT EXISTS `2428resultviews` (
  `view_id` INT PRIMARY KEY AUTO_INCREMENT,
  `user_email` VARCHAR(255) NOT NULL,
  `viewed_roll_no` VARCHAR(50) NOT NULL,
  `purchase_id` INT NOT NULL,
  `viewed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (purchase_id) REFERENCES `2428purchases`(purchase_id),
  INDEX idx_user_email (user_email),
  INDEX idx_purchase (purchase_id),
  UNIQUE KEY unique_user_roll (user_email, viewed_roll_no, purchase_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Premium requests: Edit requests and support tickets for premium users
CREATE TABLE IF NOT EXISTS `2428premiumrequests` (
  `request_id` INT PRIMARY KEY AUTO_INCREMENT,
  `user_email` VARCHAR(255) NOT NULL,
  `request_type` ENUM('edit_request', 'support_ticket') NOT NULL,
  `subject` VARCHAR(255) NOT NULL,
  `description` TEXT NOT NULL,
  `status` ENUM('pending', 'in_progress', 'resolved', 'closed') DEFAULT 'pending',
  `admin_response` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_email (user_email),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
