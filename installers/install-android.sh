#!/usr/bin/env bash
# CinemaFlix Android installer — pulls the GitHub build and (if Flutter is
# on PATH) produces an APK you can sideload. Otherwise prints the download
# links to open on the phone.
set -euo pipefail
REPO="https://github.com/devTechs001/cinemaFlix-flutter.git"
DEST="${CINEMAFLIX_HOME:-$HOME/cinemaFlix-flutter}"
RELEASE="https://github.com/devTechs001/cinemaFlix-flutter/releases/latest"
APK_LATEST="https://github.com/devTechs001/cinemaFlix-flutter/releases/latest/download/app-release.apk"

echo "CinemaFlix installer (Android)"
echo "Phone download (sideload):"
echo "  $RELEASE"
echo "  $APK_LATEST   (when an APK is attached to the release)"
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
  echo "Building APK…"
  (cd "$DEST" && flutter pub get && flutter build apk --release)
  echo
  echo "APK: $DEST/build/app/outputs/flutter-apk/app-release.apk"
  echo "Copy it to the phone and open it to install (allow unknown sources)."
else
  echo "Flutter not on PATH — open $RELEASE on the phone, or:"
  echo "  cd \"$DEST\" && flutter pub get && flutter build apk --release"
fi
