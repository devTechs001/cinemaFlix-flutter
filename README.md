# CinemaFlix

A premium movie streaming and social app built with Flutter and Supabase.

## Features
- **Real Catalogue:** 20 movies with poster artwork, live-updatable from the Supabase `movies` table (Realtime), bundled fallback offline.
- **Live Streaming:** Join movie rooms and chat live.
- **Shorts:** TikTok-style movie clips and trailers.
- **Social Feed:** Share your movie thoughts with the community.
- **Dev Admin:** Secure access for admins.
- **Update System:** In-app update notifications.
- **Gifting:** Send digital gifts during live streams.
- **Offline-first:** Favorites, watchlist, Continue Watching (resume playback) and theme persist on-device in SQLite — works offline and for guests; signed-in data also syncs to Supabase.

## Development
### Setup
```bash
cp .env.example .env   # then fill in your Supabase URL + anon key
flutter pub get
```
Run `supabase/schema.sql` once in the Supabase SQL Editor to create the
tables, RLS policies, profile trigger and Realtime publication.

### Tests & CI
```bash
flutter analyze
flutter test
```
CI: copy `docs/flutter-ci-workflow.yml` to `.github/workflows/flutter.yml`
(one-time — it runs `flutter analyze` + `flutter test` on every push/PR).

### Deployment
Use the provided scripts for easy building:
```bash
./scripts/deploy.sh
```

### Versioning
Update the app version:
```bash
./scripts/update_version.sh 1.1.0+2
```

### Icons
Place your icon at `assets/icon/app_icon.png` and run:
```bash
flutter pub run flutter_launcher_icons
```
