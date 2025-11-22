#!/bin/bash

# GitHub Webhook Auto-Deploy Script
# This script is triggered by GitHub webhooks to automatically deploy updates

LOG_FILE="/home/jecrcfoundation.live/jf-app-backend/deploy.log"
APP_DIR="/home/jecrcfoundation.live/jf-app-backend"
WEBHOOK_SECRET="your_webhook_secret_change_this"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "=== Auto-deployment started ==="

# Navigate to app directory
cd $APP_DIR || exit 1

# Stash any local changes (if any)
git stash

# Pull latest changes from GitHub
log_message "Pulling latest changes from GitHub..."
git pull origin master

if [ $? -ne 0 ]; then
    log_message "ERROR: Git pull failed"
    exit 1
fi

# Navigate to backend
cd backend || exit 1

# Install/update dependencies (remove --production to install all deps including devDependencies)
log_message "Installing/updating dependencies..."
npm install

if [ $? -ne 0 ]; then
    log_message "ERROR: npm install failed"
    exit 1
fi

# Verify nodemailer is installed
if ! npm list nodemailer > /dev/null 2>&1; then
    log_message "nodemailer not found, installing explicitly..."
    npm install nodemailer
fi

# Restart application with PM2
log_message "Restarting application..."
pm2 restart jf-app-backend

if [ $? -ne 0 ]; then
    log_message "ERROR: PM2 restart failed"
    exit 1
fi

# Check application status
pm2 status jf-app-backend

log_message "✅ Admin page is served from backend/public directory"
log_message "=== Auto-deployment completed successfully ==="
log_message "Application is now running with latest code"

# Send deployment notification (optional)
# curl -X POST "https://your-notification-service.com/notify" \
#   -H "Content-Type: application/json" \
#   -d '{"message":"Deployment successful","timestamp":"'$(date)'"}'

exit 0
