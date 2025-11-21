# JF Foundation Flutter App

Mobile application for JF Foundation with authentication and backend integration.

## Features

- ✅ User Authentication (Login/Register)
- ✅ JWT Token Management
- ✅ Secure Local Storage
- ✅ State Management with Provider
- ✅ Modern Material Design UI
- ✅ Backend API Integration

## Setup

1. Install Flutter dependencies:
```bash
cd frontend
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## Backend Connection

The app connects to: `https://jecrcfoundation.live/api`

Update the base URL in `lib/config/api_constants.dart` if needed.

## Project Structure

```
lib/
├── config/          # App configuration (API, Theme)
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # API & Storage services
├── widgets/         # Reusable widgets
└── main.dart        # App entry point
```

## Build APK

```bash
flutter build apk --release
```

## Build for iOS

```bash
flutter build ios --release
```
