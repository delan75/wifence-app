# Mobile

Flutter mobile app for NetworkApp.

Current scope:

- dashboard view
- device list
- device detail
- pause and resume
- quota editing
- category rule creation
- first-owner setup and local login

The app currently expects the local gateway API at `http://10.0.2.2:8000` for Android emulator testing.

## Run locally

1. Start the gateway on port `8000`
2. `cd mobile`
3. `flutter pub get`
4. `flutter run`

## Setup Flow

1. Start the WiFence gateway
2. Open the app
3. If the gateway has no owner yet, create one in-app
4. Sign in locally
5. Use the dashboard to scan for devices and manage them
