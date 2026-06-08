#!/bin/bash

# CinemaFlix Deployment Script
echo "🎬 CinemaFlix Deployment Started..."

# 1. Clean and Get Dependencies
echo "📦 Cleaning and getting dependencies..."
flutter clean
flutter pub get

# 2. Run Icon Generation
echo "🎨 Generating app icons..."
flutter pub run flutter_launcher_icons

# 3. Build Android APK
echo "🤖 Building Android APK (Release)..."
flutter build apk --release

# 4. Build Android App Bundle
echo "📦 Building Android App Bundle (AAB)..."
flutter build appbundle --release

# 5. Build Web
echo "🌐 Building Web version..."
flutter build web --release

echo "✅ Build Complete!"
echo "📍 APK: build/app/outputs/flutter-apk/app-release.apk"
echo "📍 AAB: build/app/outputs/bundle/release/app-release.aab"
echo "📍 Web: build/web/"

# Optional: Push to Firebase App Distribution or similar
# echo "🚀 Uploading to distribution..."
# firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk --app YOUR_APP_ID --groups "testers"

echo "🚀 Deployment ready!"
