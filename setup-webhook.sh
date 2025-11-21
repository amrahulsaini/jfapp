#!/bin/bash

# Setup Script for GitHub Auto-Deployment
# Run this script once on your server to set up auto-deployment

echo "🚀 Setting up GitHub Auto-Deployment..."

APP_DIR="/home/jecrcfoundation.live/jf-app-backend"
WEBHOOK_SECRET="$(openssl rand -hex 32)"

# Navigate to app directory
cd $APP_DIR || exit 1

# Make scripts executable
echo "📝 Making scripts executable..."
chmod +x auto-deploy.sh
chmod +x setup-webhook.sh

# Install webhook server dependencies
echo "📦 Installing webhook server dependencies..."
npm install express --save

# Create logs directory
mkdir -p logs

# Generate random webhook secret
echo "🔐 Generated Webhook Secret (save this!):"
echo "   $WEBHOOK_SECRET"
echo ""
echo "⚠️  IMPORTANT: Copy this secret for GitHub webhook configuration!"
echo ""

# Update webhook server with secret
sed -i "s/your_webhook_secret_change_this/$WEBHOOK_SECRET/g" webhook-server.js
sed -i "s/your_webhook_secret_change_this/$WEBHOOK_SECRET/g" auto-deploy.sh
sed -i "s/your_webhook_secret_change_this/$WEBHOOK_SECRET/g" webhook-ecosystem.config.js

# Start webhook server with PM2
echo "🚀 Starting webhook server..."
pm2 start webhook-ecosystem.config.js
pm2 save

# Open firewall port (if using firewalld)
if command -v firewall-cmd &> /dev/null; then
    echo "🔓 Opening firewall port 9000..."
    sudo firewall-cmd --permanent --add-port=9000/tcp
    sudo firewall-cmd --reload
fi

# Display status
pm2 status

echo ""
echo "✅ Auto-deployment setup completed!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT STEPS - Configure GitHub Webhook:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Go to your GitHub repository:"
echo "   https://github.com/amrahulsaini/jfapp/settings/hooks"
echo ""
echo "2. Click 'Add webhook'"
echo ""
echo "3. Set Payload URL:"
echo "   http://jecrcfoundation.live:9000/webhook"
echo ""
echo "4. Set Content type:"
echo "   application/json"
echo ""
echo "5. Set Secret:"
echo "   $WEBHOOK_SECRET"
echo ""
echo "6. Select events:"
echo "   ☑ Just the push event"
echo ""
echo "7. Check 'Active' and click 'Add webhook'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🧪 Test webhook server:"
echo "   curl http://localhost:9000/health"
echo ""
echo "📊 View webhook logs:"
echo "   pm2 logs jf-webhook-server"
echo ""
echo "📄 View deployment logs:"
echo "   tail -f $APP_DIR/deploy.log"
echo ""
