const express = require('express');
const crypto = require('crypto');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.WEBHOOK_PORT || 9000;
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET || 'your_webhook_secret_change_this';
const DEPLOY_SCRIPT = '/home/jecrcfoundation.live/jf-app-backend/auto-deploy.sh';
const LOG_FILE = '/home/jecrcfoundation.live/jf-app-backend/webhook.log';

// Middleware to parse JSON
app.use(express.json());

// Logging function
function log(message) {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] ${message}\n`;
  console.log(logMessage.trim());
  fs.appendFileSync(LOG_FILE, logMessage);
}

// Verify GitHub webhook signature
function verifySignature(payload, signature) {
  if (!signature) {
    return false;
  }

  const hmac = crypto.createHmac('sha256', WEBHOOK_SECRET);
  const digest = 'sha256=' + hmac.update(JSON.stringify(payload)).digest('hex');
  
  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(digest));
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'GitHub Webhook Server is running',
    timestamp: new Date().toISOString()
  });
});

// GitHub webhook endpoint
app.post('/webhook', (req, res) => {
  const signature = req.headers['x-hub-signature-256'];
  const event = req.headers['x-github-event'];
  
  log(`Received webhook event: ${event}`);

  // Verify signature
  if (!verifySignature(req.body, signature)) {
    log('ERROR: Invalid webhook signature');
    return res.status(401).json({ error: 'Invalid signature' });
  }

  // Only process push events to master branch
  if (event === 'push') {
    const branch = req.body.ref;
    const repository = req.body.repository?.full_name;
    const pusher = req.body.pusher?.name;
    const commits = req.body.commits?.length || 0;

    log(`Push event detected:`);
    log(`  Repository: ${repository}`);
    log(`  Branch: ${branch}`);
    log(`  Pusher: ${pusher}`);
    log(`  Commits: ${commits}`);

    if (branch === 'refs/heads/master' || branch === 'refs/heads/main') {
      log('Triggering auto-deployment...');

      // Execute deployment script
      exec(`bash ${DEPLOY_SCRIPT}`, (error, stdout, stderr) => {
        if (error) {
          log(`ERROR: Deployment failed - ${error.message}`);
          log(`STDERR: ${stderr}`);
          return;
        }

        log('Deployment output:');
        log(stdout);
        
        if (stderr) {
          log('Deployment warnings:');
          log(stderr);
        }

        log('✅ Auto-deployment completed successfully');
      });

      res.json({ 
        success: true, 
        message: 'Deployment triggered',
        branch: branch 
      });
    } else {
      log(`Skipping deployment - not master/main branch`);
      res.json({ 
        success: false, 
        message: 'Deployment skipped - not master/main branch' 
      });
    }
  } else {
    log(`Ignoring ${event} event`);
    res.json({ 
      success: false, 
      message: `Event ${event} ignored` 
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

// Error handler
app.use((err, req, res, next) => {
  log(`ERROR: ${err.message}`);
  res.status(500).json({ error: 'Internal Server Error' });
});

// Start server
app.listen(PORT, () => {
  log(`🚀 GitHub Webhook Server started on port ${PORT}`);
  log(`Listening for GitHub webhooks...`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  log('SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  log('SIGINT received, shutting down gracefully...');
  process.exit(0);
});
