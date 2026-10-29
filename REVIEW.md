# CinemaFlix — Code Review

**Scope:** static review of the full codebase (7,731 lines of Dart, platform configs, scripts).
**Note:** no Flutter SDK in the review environment, so `flutter analyze` / a build could not be run — findings are from reading the code.

## Verdict

A broad, good-looking **prototype/demo**, not yet a production app. The UI shell is impressively complete
(20 screens), but roughly half the features are simulated with hardcoded data, several core flows
(auth gating, chat, profile navigation) are broken, and there are release-blocking issues
(missing asset, missing Android network permission, hardcoded credentials). Zero tests, no CI.

---

## 🔴 Critical / release-blocking

| # | Issue | Evidence |
|---|-------|----------|
| 1 | **Build will fail — missing asset.** `pubspec.yaml` declares `assets/icon/app_icon.png` but there is no `assets/` directory. Also breaks `flutter_launcher_icons` and `scripts/deploy.sh` step 2. | `pubspec.yaml` (assets), no `assets/` in `git ls-files` |
| 2 | **Release Android build has no internet.** `INTERNET` permission exists only in the debug manifest. Supabase, video — all dead in release. | `android/app/src/main/AndroidManifest.xml` vs `src/debug/` |
| 3 | **Hardcoded credentials in source (committed to GitHub — rotate them).** Admin email+password special-case; dev panel code `admin123`; demo login pre-filled in the auth form. | `lib/services/auth_service.dart:48`, `lib/services/dev_service.dart:9`, `lib/screens/auth_screen.dart:16-17` |
| 4 | **No permission declarations** for contacts/camera/mic/photos on Android, and no `*UsageDescription` keys on iOS — `permission_handler` requests will be denied outright (or crash / fail App Store review on iOS). | `AndroidManifest.xml`, `ios/Runner/Info.plist` |
| 5 | **App crashes before first frame if `.env` is missing/invalid** — force-unwraps, and `main()` awaits init before `runApp()` with no error fallback. `.env` is also tracked in git and bundled as an asset (anon key is publishable, but safety then rests entirely on RLS, and no SQL/RLS exists in the repo to verify). | `lib/services/supabase_service.dart:14-15`, `lib/main.dart:29`, `git ls-files` |
| 6 | **Release signing = debug keys**, `applicationId = com.example.cinemaflix`, app label `cinemaflix`. Can't ship to Play Store as-is. | `android/app/build.gradle.kts`, manifest, `web/index.html` title |

## 🔴 Broken core flows

- **Auth is decorative.** Splash always routes to onboarding (`splash_screen.dart:40`); onboarding *Skip/Get Started* go straight to `/main` (`onboarding_screen.dart:70,183`). The existing Supabase session is never checked, "seen onboarding" is never persisted, so (a) anyone bypasses login, (b) logged-in users re-onboard every launch. "Remember me" does nothing.
- **Chat can never be started.** The message input only renders when `_messages.isNotEmpty`; tapping a conversation is a literal no-op (`_messages.isNotEmpty ? null : null;`, `chat_screen.dart:178-180`). Own-message detection `msg.userId == 'me'` (`:297`) never matches the real user/guest id sent at `:61`, so your own bubbles render as someone else's. `sendMessage` is un-awaited with no error handling — if the insert/realtime echo fails, the message silently vanishes. The "MovieBot AI" auto-reply inserts a fake row (`userId: '1'`, non-UUID id) into your real `messages` table.
- **Profile screen is orphaned.** Imported in `main.dart` but has no route and isn't a tab. Drawer's *Profile* item navigates to `/main` index 4 — which is **Chat** (`app_drawer.dart`, `main.dart` `_screens`). Watchlist/Favorites drawer items misroute to `/search`.
- **Favorites/watchlist state never survives reload.** `getWatchlist()/getFavorites()` map DB rows with `MovieModel.fromMap`, which reads the row's `id` (UUID), but Home compares against `SampleMovie` ids (`'dune2'`, …) — they can never match (`database_service.dart:24-65`, `movie_model.dart`, `home_screen.dart:33-36`).
- **Records screen shows impossible dates** (`'2024-06-${1 - i}'` → `2024-06--6`) and its *Watchlist* filter never matches the stored action `'Added to Watchlist'`. All records are fabricated in `initState` (`records_screen.dart:21-31`).
- **Video player hangs forever on error.** `initialize()` has no try/catch (`movie_play_screen.dart:34`); the placeholder says "No video URL available" even while loading. Controllers are disposed video-before-Chewie.
- **Dev panel toggles do nothing** — `bypassAuth`, `maintenanceMode`, `verboseLogging`, `showFps` are read nowhere else in the app, and the panel creates its *own* `DevService()` so state resets on exit. One button calls `toggleMaintenanceMode()` twice in a row (net no-op, `dev_panel_screen.dart:152-153`).
- Password minimum is 4 chars in UI (`auth_screen.dart:52`) but Supabase defaults to 6 — sign-ups will fail with a generic error. `resetPasswordForEmail` has no `redirectTo`/deep-link config, so the recovery flow can't complete back into the app.

## 🟠 What's real vs. what's fake

**Real (assuming the Supabase tables exist):** email sign-in/up, profile fetch + username update,
watchlist/favorites *writes*, review *writes*, password-reset email, realtime message inserts.

**Simulated / hardcoded:**
- Movie catalogue: 8 `SampleMovie`s; every Home row (Featured/Trending/Popular) shows the *same* list. No posters anywhere — gradients only; zero `Image.network` in the app. Every "movie" plays the same W3Schools Big Buck Bunny MP4.
- Shorts (no video playback — gradient + play icon), Live rooms/viewer counts/chat, Social Feed posts,
  Notifications (a new fake one is generated every 30 s forever — `notification_service.dart:23-35`),
  Contacts (mock list after real permission request), Gifting history, activity Records,
  **Update check** (always "finds" v1.1.0 after a fake 2 s delay, using `!=` string compare — it would happily "update" to an older version), Downloads, and most Settings toggles (HD streaming, subtitles… have no effect on anything).
- Dead code with zero call sites: `DatabaseService.getMovieReviews` & `updateWatchProgress` (so *Continue Watching* and DB reviews never load — detail screen shows `_sampleComments`), `GuestService.incrementViews` + all guest restrictions (never enforced), `NotificationBadge` & `LoadingAnimation` widgets, `uuid` dependency. Home's notification dot and the drawer's `3` badge are hardcoded.

## 🟡 Architecture & robustness

- **Global singletons used inconsistently** (`globals.dart`): Notifications, Dev Panel, Gifting, Chat (contacts) and Settings each `new` their own service instance, so state fragments and resets per screen — e.g. each visit to Notifications spawns a fresh service with a fresh 30 s fake-notification timer.
- **Two competing movie models** — `SampleMovie` (UI, carries `Color`s — presentation data in a model) vs `MovieModel` (DB). Nothing converts between them; this is the root of the watchlist bug above.
- **Error handling is near-absent:** `DatabaseService` and `RealtimeService` have no try/catch at all; `_fetchUser` swallows everything (`catch (_)`), so a missing `profiles` row looks identical to being logged out. Brittle casts throughout (`as String`, `as List`, `settings.arguments as SampleMovie`, `firstWhere` without `orElse` in `live_screen.dart:252` and `sample_movies.dart:157`). Sign-up inserts the profile after `auth.signUp` — if email confirmation is enabled there's no session and that insert will fail under typical RLS.
- **Nothing is persisted locally** (no `shared_preferences`/storage at all): chosen theme, settings toggles, guest state, onboarding — all reset on restart.
- **No Supabase schema in the repo** — tables referenced (`profiles`, `watchlist`, `favorites`, `reviews`, `watch_history`, `messages`) can't be reproduced or reviewed (RLS, unique constraints for the select-then-insert toggles, `onConflict` for `watch_history` upsert).

## 🟡 UX / design / performance

- **The 12-theme system barely works:** 224 hardcoded `Color(0x…)` literals (102× Netflix red `0xFFE50914`) bypass `ThemeData`, so switching themes only re-skins scaffold/app-bar/bottom-nav. Version strings (`v1.0`) are hardcoded in 5 places while `pubspec.yaml` says `0.1.0+1`.
- `IndexedStack` builds all 5 tabs at launch — Chat connects to Supabase Realtime before the user ever opens it; messages list grows unbounded; every realtime message `setState`s the whole screen. `InteractiveCard` allocates an `AnimationController` per tappable card.
- Accessibility: `InteractiveCard` is a raw `GestureDetector` — no semantics/button role for screen readers; `white24/white38` text on near-black fails contrast; no `Semantics`/`tooltip` anywhere.
- `Permission.storage` is deprecated on Android 13+; `requestAllMedia()` requests four sensitive permissions at once with no rationale UI.
- Repo hygiene: `wget-log` committed; `scripts/update_version.sh` uses GNU-only `sed -i` (breaks on macOS); no `test/` directory, no CI, single commit.

## 🟢 What's genuinely good

- Clean `models / services / screens / widgets` separation; small, focused `ChangeNotifier` services; immutable models with `fromMap`/`toMap`/`copyWith`.
- Disciplined `dispose()` of controllers and `mounted` checks after most `await`s (chat, home, detail, auth, recover).
- Nice touches: shimmer skeletons, haptics, pull-to-refresh, optimistic favorite/watchlist toggles, `ListenableBuilder` theming, custom slide transition for movie detail, modern `withAlpha`.

## Recommended order of work

**P0 — make it safe & runnable:** rotate the admin password, remove hardcoded creds/dev codes from client (gate admin via Supabase role/RLS); add the app icon asset (or drop it from pubspec); add `INTERNET` + real permission declarations (Android + iOS); own `applicationId` + release signing; session-aware splash routing (splash → auth or main; persist onboarding-seen); fix chat (always-visible input, real `isMe`, awaited sends with error surfacing, drop the DB-writing bot), profile tab/routing, watchlist `movie_id` mapping, records dates/filters, player error state, graceful Supabase-init failure.

**P1 — make it real:** unify on one movie model backed by a real catalogue (Supabase table or TMDB API) with poster images (`cached_network_image`); use the shared service instances everywhere (or Provider/Riverpod); persist theme/settings (`shared_preferences`); wire `getMovieReviews` + `updateWatchProgress` (save progress from the player); real update check with proper version comparison; commit Supabase SQL (schema + RLS) to the repo; add smoke/widget tests + a CI `flutter analyze` job.

**P2 — polish:** replace hardcoded colors with theme tokens so the 12 themes actually apply; semantics/tooltips + contrast pass; lazy tab init + message pagination; remove dead code/deps (`uuid`, unused widgets, `wget-log`); single source of truth for the app version string.

---

## Progress log

### 2026-10-29 — P0 fixes applied (branch `arena/089861cd-cinemaflix-flutter`)

Verified statically only (no Flutter SDK in the review sandbox — run `flutter pub get && flutter analyze` locally).

- [x] Hardcoded credentials removed (admin password special-case, dev code `admin123`, pre-filled demo login). Dev Panel now gates on the signed-in admin user. **Still manual: rotate the exposed admin password in Supabase.**
- [x] App icon created at `assets/icon/app_icon.png` (build-breaker fixed; also enables `flutter_launcher_icons`).
- [x] Android: `INTERNET` + contacts/camera/mic/media permissions in the main manifest; label `CinemaFlix`. iOS: usage descriptions + display name.
- [x] Supabase init no longer crashes the app: config-error screen on failure, `.env` removed from git (kept locally), `.env.example` added, `--dart-define` fallback.
- [x] Session-aware routing: splash → `/main` (signed in), `/auth` (returning), `/onboarding` (first run, persisted via `shared_preferences`); onboarding no longer bypasses auth.
- [x] Chat fixed: conversations open, input always available in-chat, correct own-message detection, awaited sends with error feedback, bot replies are local-only (no fake DB rows), last-50 history load + de-duped realtime.
- [x] Profile reachable (`/profile` route; drawer fixed — was opening Chat). Watchlist/Favorites drawer items no longer misroute to Search (interim: Records).
- [x] Favorites/watchlist reload fixed (`movie_id` mapping in `DatabaseService`).
- [x] Records: real relative dates (no more `2024-06--6`), working Watchlist filter.
- [x] Video player: loading spinner + error state with Retry; correct dispose order.
- [x] Update check is real: queries `app_updates`, proper version comparison, no fabricated 1.1.0. (Create the table — columns documented in `update_service.dart` — or it safely reports "up to date".)
- [x] Shared service instances everywhere (notifications / dev panel / gifting use `globals.dart`); auth `_fetchUser` uses `maybeSingle()`; sign-up passes username metadata and only inserts a profile with a live session; password minimum aligned to 6.
- [x] Release signing via `android/key.properties` (template added, debug fallback for local runs); `wget-log` deleted; `.gitignore` covers `.env`.
- [ ] **Manual:** rotate admin password; choose final `applicationId` (requires moving `MainActivity.kt` package); create upload keystore + `key.properties`; run `flutter pub get` + `flutter analyze` (new dep: `shared_preferences`).
- [ ] P1/P2 items above remain open (real catalogue, persistence of theme/settings, SQL+RLS in repo, tests/CI, theme tokens, accessibility).

### 2026-10-29 — P0 merged + SQLite added

- [x] P0 work committed and merged to `main` via PR #1.
- [x] **SQLite local storage** (`lib/services/local_db_service.dart`, sqflite): tables `favorites`, `watchlist`, `watch_history`, `settings`. Favorites/watchlist are now local-first (offline + guests), mirrored to Supabase when signed in; reads fall back to SQLite on error. In-memory fallback on web (sqflite has no web support).
- [x] Theme choice persisted in SQLite (`settings.theme_index`) and restored at startup.
- [x] Watch progress wired: player saves position every 5s + on exit, resumes on reopen; signed-in progress also syncs via `DatabaseService.updateWatchProgress`.
- [x] Sign-out clears local user data.
- [ ] Still open: run `flutter pub get && flutter analyze` locally (new deps: `sqflite`, `path`); Settings screen toggles not yet persisted (use `LocalDbService.setBoolSetting`); real catalogue/posters, Supabase SQL+RLS, tests/CI (P1/P2).

### 2026-10-29 — P1 batch: schema, persistence, real records/reviews, tests+CI

- [x] SQL merged to `main` (PR #2).
- [x] **Supabase schema + RLS** in repo: `supabase/schema.sql` (all tables, policies, profile-on-signup trigger, Realtime publication for `messages`). Run it once in the SQL Editor.
- [x] **Settings toggles persisted** to SQLite (`settings` table) and restored; Profile Settings tile now opens `/profile`.
- [x] **Records screen is real**: built from SQLite watch history / watchlist / favorites with loading + empty states (demo generator removed).
- [x] **Reviews load from Supabase** on Movie Detail (`getMovieReviews` wired; samples remain below as placeholders). Fixed rating-always-0 bug (rating was reset before the ReviewModel was built) and switched review ids to `Uuid().v4()` (the `uuid` dep is no longer unused). Detail favorites/watchlist now work for guests via local-first DatabaseService.
- [x] **Tests + CI**: unit tests (version compare, models), widget smoke tests, GitHub Actions `flutter analyze` + `flutter test` on push/PR (CI creates a dummy `.env` from the example since the real one is git-ignored but declared as an asset).
- [ ] Still open: real movie catalogue + posters and one unified movie model; theme-token refactor (hardcoded colors) + accessibility; lazy tab init/pagination; more test coverage (services with a fake Supabase).
