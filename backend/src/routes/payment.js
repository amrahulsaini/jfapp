const express = require('express');
const router = express.Router();
const Razorpay = require('razorpay');
const crypto = require('crypto');
const { query } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

// Initialize Razorpay
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET
});

// Get all available plans
router.get('/plans', authenticateToken, async (req, res) => {
  try {
    const plans = await query(
      'SELECT plan_id, plan_name, plan_type, price, views_limit, features FROM `2428plans` WHERE is_active = TRUE ORDER BY price ASC'
    );
    
    res.json({
      success: true,
      plans: plans.map(plan => ({
        ...plan,
        features: typeof plan.features === 'string' ? JSON.parse(plan.features) : plan.features
      }))
    });
  } catch (error) {
    console.error('Error fetching plans:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch plans' });
  }
});

// Get user's active purchases
router.get('/my-purchases', authenticateToken, async (req, res) => {
  try {
    const { email } = req.user;
    
    const purchases = await query(
      `SELECT p.*, pl.plan_name, pl.plan_type, pl.features 
       FROM \`2428purchases\` p
       JOIN \`2428plans\` pl ON p.plan_id = pl.plan_id
       WHERE p.user_email = ? AND p.is_active = TRUE
       ORDER BY p.purchase_date DESC`,
      [email]
    );
    
    // Check for active premium or any plan with remaining views
    const activePurchase = purchases.find(p => 
      (p.plan_type === 'premium' && p.is_active) || 
      (p.views_remaining > 0 && p.is_active)
    );
    
    res.json({
      success: true,
      purchases: purchases.map(p => ({
        ...p,
        features: typeof p.features === 'string' ? JSON.parse(p.features) : p.features
      })),
      hasActivePlan: !!activePurchase,
      activePlan: activePurchase || null
    });
  } catch (error) {
    console.error('Error fetching purchases:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch purchases' });
  }
});

// Create Razorpay order
router.post('/create-order', authenticateToken, async (req, res) => {
  try {
    const { plan_id } = req.body;
    const { email } = req.user;
    
    if (!plan_id) {
      return res.status(400).json({ success: false, message: 'Plan ID is required' });
    }
    
    // Get plan details
    const plans = await query('SELECT * FROM `2428plans` WHERE plan_id = ? AND is_active = TRUE', [plan_id]);
    
    if (plans.length === 0) {
      return res.status(404).json({ success: false, message: 'Plan not found' });
    }
    
    const plan = plans[0];
    const amount = Math.round(parseFloat(plan.price) * 100); // Convert to paise
    
    // Create Razorpay order
    const razorpayOrder = await razorpay.orders.create({
      amount: amount,
      currency: 'INR',
      receipt: `receipt_${Date.now()}`,
      notes: {
        user_email: email,
        plan_id: plan_id,
        plan_name: plan.plan_name
      }
    });
    
    // Save transaction record
    await query(
      `INSERT INTO \`2428transactions\` 
       (razorpay_order_id, user_email, plan_id, amount, currency, status) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [razorpayOrder.id, email, plan_id, plan.price, 'INR', 'created']
    );
    
    res.json({
      success: true,
      order: {
        id: razorpayOrder.id,
        amount: razorpayOrder.amount,
        currency: razorpayOrder.currency
      },
      plan: {
        id: plan.plan_id,
        name: plan.plan_name,
        type: plan.plan_type,
        price: plan.price
      },
      key_id: process.env.RAZORPAY_KEY_ID
    });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ success: false, message: 'Failed to create order' });
  }
});

// Verify payment and activate plan
router.post('/verify-payment', authenticateToken, async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    const { email } = req.user;
    
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({ success: false, message: 'Missing payment details' });
    }
    
    // Verify signature
    const body = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(body.toString())
      .digest('hex');
    
    const isValid = expectedSignature === razorpay_signature;
    
    if (!isValid) {
      // Update transaction as failed
      await query(
        `UPDATE \`2428transactions\` SET status = ?, error_message = ? WHERE razorpay_order_id = ?`,
        ['failed', 'Invalid signature', razorpay_order_id]
      );
      return res.status(400).json({ success: false, message: 'Invalid payment signature' });
    }
    
    // Get transaction details
    const transactions = await query(
      'SELECT * FROM `2428transactions` WHERE razorpay_order_id = ?',
      [razorpay_order_id]
    );
    
    if (transactions.length === 0) {
      return res.status(404).json({ success: false, message: 'Transaction not found' });
    }
    
    const transaction = transactions[0];
    
    // Get plan details
    const plans = await query('SELECT * FROM `2428plans` WHERE plan_id = ?', [transaction.plan_id]);
    const plan = plans[0];
    
    // Update transaction as success
    await query(
      `UPDATE \`2428transactions\` 
       SET status = ?, razorpay_payment_id = ?, razorpay_signature = ? 
       WHERE razorpay_order_id = ?`,
      ['success', razorpay_payment_id, razorpay_signature, razorpay_order_id]
    );
    
    // Create purchase record
    const expiryDate = plan.plan_type === 'premium' ? null : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 1 year for non-premium
    
    const result = await query(
      `INSERT INTO \`2428purchases\` 
       (user_email, plan_id, transaction_id, amount_paid, views_remaining, expiry_date) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [email, plan.plan_id, razorpay_order_id, plan.price, plan.views_limit, expiryDate]
    );
    
    res.json({
      success: true,
      message: 'Payment verified successfully',
      purchase: {
        purchase_id: result.insertId,
        plan_name: plan.plan_name,
        plan_type: plan.plan_type,
        views_remaining: plan.views_limit
      }
    });
  } catch (error) {
    console.error('Error verifying payment:', error);
    res.status(500).json({ success: false, message: 'Failed to verify payment' });
  }
});

// Check if user can view a specific result
router.get('/can-view/:rollNo', authenticateToken, async (req, res) => {
  try {
    const { email } = req.user;
    const { rollNo } = req.params;
    
    // Check if user is viewing their own result (match by email from student table)
    const studentCheck = await query(
      `SELECT student_emailid FROM \`2428main\` WHERE roll_no = ?`,
      [rollNo]
    );
    
    if (studentCheck.length > 0 && studentCheck[0].student_emailid === email) {
      // User can view their own result without payment
      return res.json({
        success: true,
        canView: true,
        ownResult: true,
        message: 'Viewing your own result'
      });
    }
    
    // Check for active purchases
    const purchases = await query(
      `SELECT * FROM \`2428purchases\` 
       WHERE user_email = ? AND is_active = TRUE 
       AND (views_remaining > 0 OR views_remaining IS NULL)
       ORDER BY purchase_date DESC LIMIT 1`,
      [email]
    );
    
    if (purchases.length === 0) {
      return res.json({
        success: true,
        canView: false,
        reason: 'no_active_plan',
        message: 'Please purchase a plan to view results'
      });
    }
    
    const purchase = purchases[0];
    
    // Check if already viewed this student
    const views = await query(
      `SELECT * FROM \`2428resultviews\` 
       WHERE user_email = ? AND viewed_roll_no = ? AND purchase_id = ?`,
      [email, rollNo, purchase.purchase_id]
    );
    
    if (views.length > 0) {
      // Already viewed, can view again
      return res.json({
        success: true,
        canView: true,
        alreadyViewed: true,
        purchase: purchase
      });
    }
    
    // Check if has remaining views
    if (purchase.views_remaining === null || purchase.views_remaining > 0) {
      return res.json({
        success: true,
        canView: true,
        alreadyViewed: false,
        purchase: purchase
      });
    }
    
    res.json({
      success: true,
      canView: false,
      reason: 'no_views_remaining',
      message: 'No views remaining. Please purchase a new plan.'
    });
  } catch (error) {
    console.error('Error checking view permission:', error);
    res.status(500).json({ success: false, message: 'Failed to check permission' });
  }
});

// Record result view and decrement counter
router.post('/record-view', authenticateToken, async (req, res) => {
  try {
    const { email } = req.user;
    const { roll_no } = req.body;
    
    if (!roll_no) {
      return res.status(400).json({ success: false, message: 'Roll number is required' });
    }
    
    // Check if viewing own result - no recording needed
    const studentCheck = await query(
      `SELECT student_emailid FROM \`2428main\` WHERE roll_no = ?`,
      [roll_no]
    );
    
    if (studentCheck.length > 0 && studentCheck[0].student_emailid === email) {
      // Own result - no need to record or decrement
      return res.json({
        success: true,
        message: 'Own result viewed',
        ownResult: true
      });
    }
    
    // Get active purchase
    const purchases = await query(
      `SELECT * FROM \`2428purchases\` 
       WHERE user_email = ? AND is_active = TRUE 
       AND (views_remaining > 0 OR views_remaining IS NULL)
       ORDER BY purchase_date DESC LIMIT 1`,
      [email]
    );
    
    if (purchases.length === 0) {
      return res.status(403).json({ success: false, message: 'No active plan found' });
    }
    
    const purchase = purchases[0];
    
    // Check if already viewed
    const existingViews = await query(
      `SELECT * FROM \`2428resultviews\` 
       WHERE user_email = ? AND viewed_roll_no = ? AND purchase_id = ?`,
      [email, roll_no, purchase.purchase_id]
    );
    
    if (existingViews.length > 0) {
      return res.json({
        success: true,
        message: 'Already viewed',
        viewsRemaining: purchase.views_remaining
      });
    }
    
    // Record the view
    await query(
      `INSERT INTO \`2428resultviews\` (user_email, viewed_roll_no, purchase_id) 
       VALUES (?, ?, ?)`,
      [email, roll_no, purchase.purchase_id]
    );
    
    // Decrement views_remaining if not unlimited
    if (purchase.views_remaining !== null) {
      await query(
        `UPDATE \`2428purchases\` 
         SET views_remaining = views_remaining - 1 
         WHERE purchase_id = ?`,
        [purchase.purchase_id]
      );
      
      // Deactivate if no views remaining
      if (purchase.views_remaining - 1 <= 0) {
        await query(
          `UPDATE \`2428purchases\` SET is_active = FALSE WHERE purchase_id = ?`,
          [purchase.purchase_id]
        );
      }
    }
    
    res.json({
      success: true,
      message: 'View recorded',
      viewsRemaining: purchase.views_remaining !== null ? purchase.views_remaining - 1 : null
    });
  } catch (error) {
    console.error('Error recording view:', error);
    res.status(500).json({ success: false, message: 'Failed to record view' });
  }
});

// Submit premium request (edit or support)
router.post('/premium-request', authenticateToken, async (req, res) => {
  try {
    const { email } = req.user;
    const { request_type, subject, description } = req.body;
    
    if (!request_type || !subject || !description) {
      return res.status(400).json({ success: false, message: 'All fields are required' });
    }
    
    // Check if user has premium plan
    const purchases = await query(
      `SELECT p.*, pl.plan_type FROM \`2428purchases\` p
       JOIN \`2428plans\` pl ON p.plan_id = pl.plan_id
       WHERE p.user_email = ? AND p.is_active = TRUE AND pl.plan_type = 'premium'
       ORDER BY p.purchase_date DESC LIMIT 1`,
      [email]
    );
    
    if (purchases.length === 0) {
      return res.status(403).json({ success: false, message: 'Premium plan required' });
    }
    
    // Create request
    const result = await query(
      `INSERT INTO \`2428premiumrequests\` (user_email, request_type, subject, description) 
       VALUES (?, ?, ?, ?)`,
      [email, request_type, subject, description]
    );
    
    res.json({
      success: true,
      message: 'Request submitted successfully',
      request_id: result.insertId
    });
  } catch (error) {
    console.error('Error submitting premium request:', error);
    res.status(500).json({ success: false, message: 'Failed to submit request' });
  }
});

// Get user's premium requests
router.get('/my-requests', authenticateToken, async (req, res) => {
  try {
    const { email } = req.user;
    
    const requests = await query(
      `SELECT * FROM \`2428premiumrequests\` 
       WHERE user_email = ? 
       ORDER BY created_at DESC`,
      [email]
    );
    
    res.json({
      success: true,
      requests: requests
    });
  } catch (error) {
    console.error('Error fetching requests:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch requests' });
  }
});

module.exports = router;
