# PM2 Configuration for Webhook Server
module.exports = {
  apps: [{
    name: 'jf-webhook-server',
    script: './webhook-server.js',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    env: {
      NODE_ENV: 'production',
      WEBHOOK_PORT: 9000,
      WEBHOOK_SECRET: 'your_webhook_secret_change_this'
    },
    error_file: './logs/webhook-err.log',
    out_file: './logs/webhook-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true
  }]
};
