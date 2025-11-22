# JF App Payment System - Complete Implementation Guide

## 🎯 Overview
Complete payment integration with Razorpay for result viewing access. Users must purchase plans to unlock student results.

## 📊 Database Tables Created

### 1. `2428plans` - Available Plans
- **Basic (₹1)**: View 3 students' results
- **Standard (₹21)**: View 5 students' results  
- **Premium (₹51)**: Unlimited views + Edit requests + Support access

### 2. `2428purchases` - User Purchases
Tracks all user plan purchases with views remaining

### 3. `2428transactions` - Payment Records
Stores all Razorpay transactions with verification status

### 4. `2428resultviews` - Result Views Tracking
Records each result view and decrements remaining views

### 5. `2428premiumrequests` - Premium Support
Edit requests and support tickets for premium users

## 🔧 Backend Setup

### 1. Install Database Tables
```bash
cd /home/jecrcfoundation.live/jf-app/backend
mysql -u jecr_app -p jecr_app < database-payment-tables.sql
```

### 2. Add Razorpay Credentials to .env
```bash
# Add to /home/jecrcfoundation.live/jf-app/backend/.env
RAZORPAY_KEY_ID=rzp_test_YOUR_KEY_ID
RAZORPAY_KEY_SECRET=YOUR_SECRET_KEY
```

Get your keys from: https://dashboard.razorpay.com/app/keys

### 3. Install Razorpay Package
```bash
cd /home/jecrcfoundation.live/jf-app/backend
npm install razorpay@^2.9.2
```

### 4. Restart PM2
```bash
pm2 restart jf-app-backend
pm2 logs jf-app-backend
```

## 📱 Frontend Setup

### 1. Install Dependencies
```bash
cd frontend_temp
flutter pub get
```

This will install:
- `razorpay_flutter: ^1.3.7`

### 2. Build and Run
```bash
flutter run
```

## 🔐 Payment Flow

### User Journey:
1. **Login** → User logs in with OTP
2. **Browse Students** → Can see all students in grid
3. **Click View Results** → Shown locked screen if no plan
4. **Purchase Plan** → Redirected to plans screen
5. **Select Plan** → Choose Basic/Standard/Premium
6. **Razorpay Checkout** → Complete payment
7. **Verification** → Backend verifies payment signature
8. **Plan Activated** → Purchase record created
9. **View Results** → Can now view based on plan limits

### Technical Flow:
```
Frontend (Flutter)
    ↓ Check if can view result
Backend API: GET /api/payment/can-view/:rollNo
    ↓ Returns: canView: true/false
    
IF FALSE → Show locked screen with "Purchase Plan" button
    ↓ User clicks button
Flutter: Navigate to PlansScreen
    ↓ Load plans
Backend API: GET /api/payment/plans
    ↓ User selects plan
Backend API: POST /api/payment/create-order
    ↓ Returns Razorpay order_id
Razorpay SDK: Opens checkout
    ↓ User completes payment
Razorpay: Returns payment_id + signature
    ↓ Verify payment
Backend API: POST /api/payment/verify-payment
    ↓ Verifies signature + Creates purchase
Backend: Updates 2428purchases table
    ↓ Success
Flutter: Shows success + Returns to results
    ↓ Record view
Backend API: POST /api/payment/record-view
    ↓ Decrements views_remaining
Backend: Shows actual results
```

## 🎨 UI Features

### Locked State (No Plan):
- 🔒 Lock icon with gradient background
- Clear "Results Locked" message
- "Purchase a plan" call-to-action
- Big orange button: "View Plans & Purchase"
- Go Back button

### Plans Screen:
- 3 beautiful plan cards
- Popular badge on Standard plan
- Best Value badge on Premium plan
- Feature comparisons
- Price in ₹ INR
- Gradient buttons
- Info section explaining premium benefits

### Premium Features Screen:
- Edit request form
- Support ticket form
- Submit to backend
- Track request status

## 📡 API Endpoints

### Payment Routes (`/api/payment/*`)
- `GET /plans` - Get all available plans
- `GET /my-purchases` - Get user's active purchases
- `POST /create-order` - Create Razorpay order
- `POST /verify-payment` - Verify and activate plan
- `GET /can-view/:rollNo` - Check if user can view result
- `POST /record-view` - Record view and decrement counter
- `POST /premium-request` - Submit premium support request
- `GET /my-requests` - Get user's premium requests

## 🔒 Security Features

1. **Signature Verification**: Backend verifies Razorpay signature using HMAC SHA256
2. **JWT Authentication**: All payment APIs require valid session token
3. **Double-spending Prevention**: Unique constraints on transactions
4. **View Tracking**: Each view is recorded to prevent abuse
5. **Premium Verification**: Support requests check for active premium plan

## 💰 Plan Details

| Plan | Price | Views | Features |
|------|-------|-------|----------|
| Basic | ₹1 | 3 students | View results only |
| Standard | ₹21 | 5 students | View results only |
| Premium | ₹51 | Unlimited | Results + Edit requests + Support |

## 🎯 Premium Benefits

✅ Unlimited result views
✅ Request data corrections/edits
✅ Direct support access
✅ Priority response (24-48hrs)

## 🧪 Testing

### Test Cards (Razorpay Test Mode):
- **Success**: 4111 1111 1111 1111
- **Failure**: 4000 0000 0000 0002
- CVV: Any 3 digits
- Expiry: Any future date

### Test Flow:
1. Login to app
2. Try viewing any student's results
3. Should see locked screen
4. Click "View Plans & Purchase"
5. Select any plan
6. Use test card for payment
7. Complete purchase
8. Return to results
9. Should see actual results
10. Try viewing more students (should decrement counter)

## 📊 Admin Queries

### Check Active Purchases:
```sql
SELECT p.*, u.email 
FROM 2428purchases p 
WHERE p.is_active = TRUE 
ORDER BY p.purchase_date DESC;
```

### View Transactions:
```sql
SELECT * FROM 2428transactions 
WHERE status = 'success' 
ORDER BY created_at DESC 
LIMIT 20;
```

### Premium Requests:
```sql
SELECT * FROM 2428premiumrequests 
WHERE status = 'pending' 
ORDER BY created_at DESC;
```

### Views Tracking:
```sql
SELECT user_email, COUNT(*) as views_count 
FROM 2428resultviews 
GROUP BY user_email 
ORDER BY views_count DESC;
```

## 🚀 Deployment Checklist

- [x] Database tables created
- [x] Backend routes added
- [x] Razorpay package installed
- [x] Environment variables set
- [x] Frontend UI implemented
- [x] Payment flow tested
- [ ] Switch to Razorpay LIVE keys
- [ ] Test on production
- [ ] Monitor transactions
- [ ] Set up webhooks (optional)

## 🔄 Going Live

1. **Get Live API Keys**:
   - Login to Razorpay Dashboard
   - Complete KYC verification
   - Generate Live API keys

2. **Update .env**:
   ```
   RAZORPAY_KEY_ID=rzp_live_YOUR_LIVE_KEY
   RAZORPAY_KEY_SECRET=YOUR_LIVE_SECRET
   ```

3. **Restart Backend**:
   ```bash
   pm2 restart jf-app-backend
   ```

4. **Test with Real Payment**:
   - Use actual debit/credit card
   - Make small test purchase (₹1)
   - Verify money received in dashboard

## 📞 Support

For issues:
1. Check PM2 logs: `pm2 logs jf-app-backend`
2. Check MySQL: `mysql -u jecr_app -p jecr_app`
3. Test API: `curl https://jecrcfoundation.live/api/payment/plans`

## 🎉 Success!

Your JF App now has a complete payment system with:
- ✅ Razorpay integration
- ✅ Plan-based access control
- ✅ Beautiful locked state UI
- ✅ Premium support features
- ✅ Secure payment verification
- ✅ View tracking and limits

**Note**: Make sure to replace test API keys with live keys before accepting real payments!
