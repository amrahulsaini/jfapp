# JF App Backend API

Node.js Express backend API for Flutter mobile application.

## Features

- ✅ RESTful API architecture
- ✅ JWT authentication
- ✅ MySQL database integration
- ✅ Express.js framework
- ✅ Security middleware (Helmet, CORS)
- ✅ Request validation
- ✅ Error handling
- ✅ PM2 ready for production

## Setup Instructions

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment

Copy `.env.example` to `.env` and update with your database credentials:

```bash
cp .env.example .env
```

Edit `.env` file:
```
DB_HOST=localhost
DB_USER=your_database_user
DB_PASSWORD=your_database_password
DB_NAME=your_database_name
JWT_SECRET=your_super_secret_key
```

### 3. Create Database Tables

Run this SQL to create the users table (example):

```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4. Run Development Server

```bash
npm run dev
```

The API will run on `http://localhost:3001`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Users (Protected)
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile

### Data
- `GET /api/data/public` - Get public data
- `GET /api/data/protected` - Get protected data (requires auth)
- `POST /api/data/items` - Create new item (requires auth)

### Health Check
- `GET /health` - Server health status

## Production Deployment on CyberPanel

### 1. Upload Files to Server

Upload the backend folder to your server (e.g., `/home/yourdomain/jf-app-backend`)

### 2. Install Node.js on Server

```bash
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install nodejs -y
```

### 3. Install Dependencies on Server

```bash
cd /home/yourdomain/jf-app-backend
npm install --production
```

### 4. Install PM2

```bash
sudo npm install -g pm2
```

### 5. Start Application with PM2

```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### 6. Configure VHost in CyberPanel

Add this to your virtual host configuration:

```
# Proxy to Node.js Express API running on localhost:3001
extprocessor jf-app-backend {
  type                   proxy
  address                127.0.0.1:3001
  maxConns               100
  pcKeepAliveTimeout     60
  initTimeout            60
  retryTimeout           0
  respBuffer             0
}

rewrite {
  enable                 1
  rules                  <<<EOR
# Forward API requests to Node.js backend
RewriteRule ^/api/(.*)$ http://jf-app-backend/api/$1 [P]
EOR
}
```

### 7. Restart LiteSpeed

```bash
sudo systemctl restart lsws
```

## Flutter Integration

In your Flutter app, use this base URL:

```dart
const String API_BASE_URL = 'https://yourdomain.com/api';

// Example API call
final response = await http.post(
  Uri.parse('$API_BASE_URL/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'email': 'user@example.com',
    'password': 'password123'
  })
);
```

For authenticated requests:

```dart
final response = await http.get(
  Uri.parse('$API_BASE_URL/users/profile'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  }
);
```

## PM2 Commands

```bash
pm2 status              # Check app status
pm2 logs jf-app-backend # View logs
pm2 restart jf-app-backend # Restart app
pm2 stop jf-app-backend # Stop app
pm2 delete jf-app-backend # Remove app
```

## Security Notes

- Always use HTTPS in production
- Keep JWT_SECRET secure and complex
- Use strong database passwords
- Enable firewall rules
- Regular security updates
- Implement rate limiting for production
