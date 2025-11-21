#!/bin/bash

# Quick Update Script - Run this for updates after initial deployment

echo "🔄 Updating JF App..."

APP_DIR="/home/jecrcfoundation.live/jf-app-backend"

cd $APP_DIR

# Pull latest changes
git pull origin main

# Update backend dependencies
cd backend
npm install --production

# Restart application
pm2 restart jf-app-backend

# Show status
pm2 status

echo "✅ Update completed!"
pm2 logs jf-app-backend --lines 10 --nostream
