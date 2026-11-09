#!/usr/bin/env bash
# CinemaFlix Linux installer — clones or updates the GitHub build.
set -euo pipefail
REPO="https://github.com/devTechs001/cinemaFlix-flutter.git"
DEST="${CINEMAFLIX_HOME:-$HOME/cinemaFlix-flutter}"

echo "CinemaFlix installer"
echo "→ $DEST"

if [ -d "$DEST/.git" ]; then
  git -C "$DEST" fetch --depth 1 origin
  git -C "$DEST" reset --hard origin/main
else
  rm -rf "$DEST"
  git clone --depth 1 "$REPO" "$DEST"
fi

echo
echo "Installed source at $DEST"
echo "Next:  cd \"$DEST\" && flutter pub get && flutter run"
echo "Backend: cd \"$DEST/backend\" && npm install && npm start"
