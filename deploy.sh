#!/bin/bash

# JF App Deployment Script for CyberPanel Server
# Run this script on your server after cloning the repository

echo "🚀 Starting JF App Deployment..."

# Configuration Variables
APP_DIR="/home/jecrcfoundation.live/jf-app-backend"
REPO_URL="https://github.com/amrahulsaini/jfapp.git"
NODE_VERSION="18"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Install Node.js (if not installed)
echo -e "${YELLOW}📦 Checking Node.js installation...${NC}"
if ! command -v node &> /dev/null; then
    echo "Installing Node.js ${NODE_VERSION}..."
    curl -sL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | sudo bash -
    sudo yum install nodejs -y
else
    echo -e "${GREEN}✅ Node.js already installed: $(node --version)${NC}"
fi

# Step 2: Install PM2 (if not installed)
echo -e "${YELLOW}📦 Checking PM2 installation...${NC}"
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    sudo npm install -g pm2
else
    echo -e "${GREEN}✅ PM2 already installed: $(pm2 --version)${NC}"
fi

# Step 3: Create app directory
echo -e "${YELLOW}📁 Setting up application directory...${NC}"
sudo mkdir -p $APP_DIR
cd /home/jecrcfoundation.live

# Step 4: Clone or pull repository
if [ -d "$APP_DIR/.git" ]; then
    echo -e "${YELLOW}🔄 Updating existing repository...${NC}"
    cd $APP_DIR
    git pull origin main
else
    echo -e "${YELLOW}📥 Cloning repository...${NC}"
    git clone $REPO_URL $APP_DIR
    cd $APP_DIR
fi

# Step 5: Navigate to backend
cd backend

# Step 6: Install dependencies
echo -e "${YELLOW}📦 Installing backend dependencies...${NC}"
npm install --production

# Step 7: Setup environment file
echo -e "${YELLOW}⚙️ Setting up environment configuration...${NC}"
if [ ! -f .env ]; then
    echo "Creating .env file from example..."
    cp .env.example .env
    echo -e "${RED}⚠️ IMPORTANT: Edit .env file with your database credentials!${NC}"
    echo "Run: nano .env"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Step 8: Create logs directory
mkdir -p logs

# Step 9: Set proper permissions
echo -e "${YELLOW}🔐 Setting permissions...${NC}"
sudo chown -R jecrc9597:jecrc9597 $APP_DIR
chmod -R 755 $APP_DIR

# Step 10: Stop existing PM2 process (if running)
echo -e "${YELLOW}🛑 Stopping existing application...${NC}"
pm2 stop jf-app-backend 2>/dev/null || true
pm2 delete jf-app-backend 2>/dev/null || true

# Step 11: Start application with PM2
echo -e "${YELLOW}🚀 Starting application with PM2...${NC}"
pm2 start ecosystem.config.js

# Step 12: Save PM2 configuration
pm2 save

# Step 13: Setup PM2 startup script (first time only)
echo -e "${YELLOW}⚡ Configuring PM2 startup...${NC}"
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u jecrc9597 --hp /home/jecrc9597 2>/dev/null || true

# Step 14: Check application status
echo -e "${YELLOW}📊 Checking application status...${NC}"
pm2 status

# Step 15: Restart LiteSpeed
echo -e "${YELLOW}🔄 Restarting LiteSpeed Web Server...${NC}"
sudo systemctl restart lsws

# Display completion message
echo ""
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo "📝 Next Steps:"
echo "1. Edit .env file: nano $APP_DIR/backend/.env"
echo "2. Update database credentials in .env"
echo "3. Check logs: pm2 logs jf-app-backend"
echo "4. Monitor status: pm2 status"
echo "5. Test API: curl https://jecrcfoundation.live/api/health"
echo ""
echo "🔗 API Endpoint: https://jecrcfoundation.live/api"
echo "📊 PM2 Dashboard: pm2 monit"
echo ""

# Display application logs
echo -e "${YELLOW}📋 Application logs:${NC}"
pm2 logs jf-app-backend --lines 20 --nostream
