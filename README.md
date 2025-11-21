# JF App

Full-stack application with Flutter frontend and Node.js backend.

## Project Structure

```
jf-app/
├── backend/          # Node.js Express API
├── frontend/         # Flutter mobile app
├── deploy.sh         # Server deployment script
├── update.sh         # Quick update script
├── auto-deploy.sh    # GitHub webhook auto-deploy script
├── webhook-server.js # GitHub webhook listener
└── setup-webhook.sh  # One-time webhook setup
```

## Backend

Node.js Express API with JWT authentication and MySQL database integration.

See [backend/README.md](backend/README.md) for detailed setup instructions.

## Frontend

Flutter mobile application with authentication and API integration.

See [frontend/README.md](frontend/README.md) for detailed setup instructions.

## Quick Start

### Backend Setup

1. Navigate to backend directory
2. Install dependencies: `npm install`
3. Configure `.env` file
4. Run: `npm run dev`

### Frontend Setup

1. Navigate to frontend directory
2. Install dependencies: `flutter pub get`
3. Run: `flutter run`

## Deployment

### Manual Deployment

See `deploy.sh` for server deployment commands.

### Auto-Deployment (GitHub Webhooks)

Enable automatic deployment on every push to GitHub.

See [AUTO_DEPLOY_GUIDE.md](AUTO_DEPLOY_GUIDE.md) for complete setup instructions.

**Quick setup:**
```bash
# On server
./setup-webhook.sh
```

Then configure GitHub webhook at:
`https://github.com/amrahulsaini/jfapp/settings/hooks`

## Tech Stack

- **Backend**: Node.js, Express, MySQL, JWT
- **Frontend**: Flutter, Provider, HTTP
- **Server**: CyberPanel, LiteSpeed, PM2
- **CI/CD**: GitHub Webhooks, Auto-deployment

## API Endpoint

Production: `https://jecrcfoundation.live/api`
