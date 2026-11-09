#!/usr/bin/env bash
# CinemaFlix iOS installer — pulls the GitHub build and (if Flutter + Xcode
# are available) prepares an iOS/ipa build. TestFlight / App Store links
# go here when published.
set -euo pipefail
REPO="https://github.com/devTechs001/cinemaFlix-flutter.git"
DEST="${CINEMAFLIX_HOME:-$HOME/cinemaFlix-flutter}"
RELEASE="https://github.com/devTechs001/cinemaFlix-flutter/releases/latest"

echo "CinemaFlix installer (iOS)"
echo "On iPhone: open $RELEASE"
echo "TestFlight / App Store: attach a build to the GitHub release notes when live."
echo

if [ -d "$DEST/.git" ]; then
  git -C "$DEST" fetch --depth 1 origin
  git -C "$DEST" reset --hard origin/main
else
  rm -rf "$DEST"
  git clone --depth 1 "$REPO" "$DEST"
fi

echo "Source at $DEST"

if command -v flutter >/dev/null 2>&1; then
  echo "Preparing iOS…"
  (cd "$DEST" && flutter pub get && flutter build ios --release --no-codesign)
  echo
  echo "Open $DEST/ios/Runner.xcworkspace in Xcode, sign, and install to a device."
else
  echo "Flutter not on PATH — on a Mac:"
  echo "  cd \"$DEST\" && flutter pub get && flutter build ios --release"
fi
