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

### 2026-10-29 — Unified catalogue, tokens, accessibility, desktop, realtime

- [x] **One unified `Movie` model** (`lib/models/movie.dart`) replaces SampleMovie + MovieModel; old files deleted. `fromMap` tolerates catalogue rows, Supabase rows and SQLite rows.
- [x] **Real catalogue**: 20 real movies (`movie_catalogue.dart`) with TMDB-CDN poster images via new `MoviePoster` widget (gradient fallback on load failure/offline), wired into Home (featured/trending/popular/continue), Detail (header + related), Search, Shorts, Social, Profile, Records. Distinct playable sample streams per title (swap for licensed URLs later). Poster CDN paths are best-effort — any miss degrades to gradient artwork, never a broken image icon.
- [x] **Realtime catalogue**: `MovieService` loads the Supabase `movies` table (schema + 20-row seed appended to `supabase/schema.sql`) and live-updates on Realtime changes (run the new SQL section to enable the table/publication).
- [x] **Realtime hardened**: chat auto-reconnects after drops; header shows real Online/Connecting state; notifications are driven by real chat activity (fake 30s generator removed); Home notification dot reflects the real unread count; Continue Watching row on Home is real SQLite progress (hidden when empty).
- [x] **Theme tokens**: `lib/theme/app_tokens.dart` (`AppColors`, spacing, radii); 186 raw color literals migrated. Remaining one-off accent colors are intentional (categories/avatars). Full ColorScheme-driven theming is still future work.
- [x] **Accessibility**: `InteractiveCard` exposes button semantics (+ optional `semanticLabel`); posters carry image semantics labels.
- [x] **Desktop UX**: NavigationRail shell ≥900dp, mouse/trackpad drag scrolling, hover click cursors, responsive grids (Home popular, Explore).
- [ ] Still: run `flutter analyze && flutter test` locally (or enable CI workflow); give the app a TMDB API key + licensed streams when ready; live rooms/social feed content are still demo data on top of real movie metadata.

---

## 2026-10-29 — bugs_fixed.txt consistency round (main force-push reconciliation)

**Context:** `origin/main` was force-pushed as a single orphan commit (53835b5) containing
the large parallel feature work (admin/wallet/shorts/live/creator/… + `bugs_fixed.txt`,
`DEV_DOC.md`, `backend/`) built on the pre-PR codebase. The session branch merged it with
`--allow-unrelated-histories -X theirs` (your main's content wins; PR lineage kept).

**Static audit found the pushed tree could not compile — fixed in this round:**

- **12 files referenced but never committed** were rebuilt against their call sites:
  `api_config.dart` (`baseUrl`/`apiPath`→`/api/*`/`resolveUrl`), `video_url_resolver.dart`
  (`resolve`/`candidates` with GTV fallbacks), `lock_service.dart` (persisted vault PIN),
  `movie_db_service.dart` (startup catalogue import), `sync_service.dart` (sign-in
  push/pull of favorites/watchlist/watch-history ↔ Supabase), `feed_service.dart`
  (`GET /api/posts` → feed-card adapter), `social_service.dart` (follow/like endpoints),
  `desktop_sidebar.dart`, `shorts_tiktok_nav.dart`, `dev_mode_badge.dart`,
  `real_me_bridge.dart`, `user_profile_screen.dart` (`/user-profile` route).
- **Undefined symbols:** `DevService.authenticate/hasFullAccess/unlockAll/toggleUnlockAll`
  (+`grantFullAccess`), `movieService` singleton (exported via globals), `localDbService`
  singleton (globals), `ConfigErrorApp` (main, used by widget_test).
- **`test/models/movie_model_test.dart`** imported the deleted `movie_model.dart` →
  rewritten against the unified `Movie` (incl. `movie_id`/numeric coercion cases).
- **pubspec:** added `supabase_flutter ^2.8.4`, `sqflite ^2.3.3+1`, `path ^1.9.0`,
  declared `assets/icon/`; restored the real 1024² `app_icon.png` (push contained a
  69-byte stub).

**Runtime bugs fixed:**

- `localDbService.initialize()` was never called → SQLite silently ran in-memory (favorites/
  records/settings never persisted). Now initialized in `main()`.
- `SupabaseService().initialize()` was never called → chat Realtime, catalogue import and
  mirrors were dead. Now initialized in `main()` (non-fatal on failure).
- **`admin123` backdoor removed everywhere:** auth logo-tap now uses `grantFullAccess()`;
  dev panel shows no code (reads `DEV_ACCESS_CODE`); admin dashboard no longer prefills it;
  backend `ADMIN_CODE` has no shared default (env or per-boot random, printed to console);
  `.env.example` + `DEV_DOC.md` updated.
- Vault PIN verified through `LockService` (persisted `vault_pin`, default `1234`) instead
  of a hard-coded comparison.
- App drawer tab misroutes: Chat went to Profile (extra 4→3); Live now pushes `/live`.
- Notifications: added real Supabase Realtime `messages` insert notifications alongside the
  existing random popups (per bugs_fixed.txt "notifications(real time)").
- `main.dart` dotenv guarded: missing `.env` → `ConfigErrorApp('Missing env')` instead of a
  pre-frame crash.

**bugs_fixed.txt wiring made real:** FeedService loads the backend feed into
SocialFeedScreen (demo posts kept when offline); SocialService powers follow/unfollow on
the new profile screen; SyncService reconciles local↔cloud on sign-in; MovieDbService
imports the Supabase `movies` catalogue with Realtime refresh; desktop sidebar + TikTok
shorts nav + real_me bridge card implemented for the shell in `main.dart`.

**Verified (static only):** 0 broken imports across `lib`+`test`; delimiter balance OK;
singleton-member audit clean; no `admin123` left in code; all new tests' symbols resolve.
**Not runnable here:** `flutter pub get/analyze/test` (no SDK) — first CI/user run will be
the real gate. Move `docs/flutter-ci-workflow.yml` into `.github/workflows/` to get CI.

**Known remaining gaps (not in this round):** dual movie models still coexist
(`SampleMovie` in most screens vs unified `Movie` in records/search/service) — recommend a
follow-up unification pass; most screens still use raw `Color(0xFF…)` literals (token sweep
was lost in the force-push); live rooms/social content partly demo; rate limiting,
OAuth/OTP production hardening and test coverage per `DEV_DOC.md` §Remaining.

---

## 2026-11-09 — live system + Netflix splash/onboarding + modern profile

**Live system (functional pass):**
- Rooms now **load from the backend** (`GET /api/live/rooms`, 20s poll + pull-to-refresh on the
  grid) and merge into the list: remote rooms get refreshed viewer counts/name, new rooms are
  prepended with an adapter (`_adaptRemoteRoom`) mapping `liveRoomJSON` → card/detail shape
  (color palette, `call_id`, `host_id`, `requires_approval`). Demo rooms remain as offline
  fallback so the screen is never empty.
- Opening a room now sets `_selectedRoom` **and `_isHost`** — previously `_isHost` was never
  assigned, so host controls were dead code.
- Host **End stream** now really ends: calls `POST /api/live/end`, closes the room view and
  removes the room (graceful local-only end when the backend is offline).
- Go Live dialog gained a **"Require approval to join"** switch → `requires_approval` sent to
  `/api/live/create` (backend already supported it; the client never sent it).
- `_isRoomOwner` prefers backend `host_id` match (falls back to the legacy name compare).
- Existing flows kept: join + join-request approval sheet, requests inbox, gifts, reactions,
  share, RealMe bridge card.

**Splash + onboarding — Netflix-style movie-card backgrounds:**
- New shared `MovieCardWall` widget (`lib/widgets/movie_card_wall.dart`): three tilted rows of
  poster cards drifting in alternating directions, seamless loop (one catalogue period),
  reading the live `movieService` catalogue and rendering through `MoviePoster` (gradient
  fallback when an image fails).
- Splash: wall sits behind particles/glow/logo (opacity 0.42); the old static bottom strip was
  removed — it referenced `SampleMovie.effectivePosterUrl`, **a member that exists nowhere**
  (a compile break in the pushed tree).
- Onboarding: same wall behind the 4-step PageView with a top/middle/bottom scrim for
  readability.

**Profile — modern clean + nav bar:**
- Rebuilt `build()` as `CustomScrollView` with a **pinned SliverAppBar** carrying a new
  **section nav bar**: Overview · Library · Activity · Account (animated segmented pills,
  haptics, always visible while scrolling).
- All previous sections regrouped behind the tabs (nothing dropped): Overview = badges/stats/
  level/continue-watching/rating chart; Library = favorites/watchlists/reviews/lists; Activity
  = friends/recent/your-activity; Account = menu tiles + sign out + footer.
- `MainShell` no longer hides the bottom bar on the Profile tab (`_currentIndex == 4 → null`
  special case removed) — profile is no longer a navigation dead end.

**Verified (static):** 0 broken imports, delimiter balance OK across `lib`+`test`, helper
definitions single, `effectivePosterUrl`/`CachedNetworkImage` fully removed. Still no Flutter
SDK in sandbox — `flutter pub get && flutter analyze && flutter test` remains the real gate.

---

## 2026-11-09 — live room maintenance for the real_me companion

**Problem:** backend live rooms lived only in `memory.liveRooms` — a backend restart wiped
every room, the real_me companion's `GET /api/live/rooms` went empty, and nothing marked a
host as still present (dead hosts' rooms lingered forever).

**Backend (`backend/systems.js`):**
- **Durability:** room/request/token state flushes to `backend/data/live_state.json` after
  every mutation (debounced 250ms write) and is restored on boot — companion keeps seeing
  rooms across restarts. `backend/data/` added to `.gitignore`.
- **Heartbeat:** new `PUT /api/live/rooms/:callId/heartbeat` sets `heartbeatAt` (optional
  `viewers` override; otherwise the server keeps its own count, bumped by viewer-token
  issuance). Rooms get `heartbeatAt` at creation; `liveRoomJSON` now exposes it.
- **Stale pruning:** the room-list handler (`/live/rooms` + `/live/list`) marks rooms `ended`
  when the host's heartbeat is older than `LIVE_STALE_MS` (default 90s) or the stream exceeds
  `LIVE_MAX_AGE_MS` (default 4h) — the companion only ever sees genuinely live rooms.
- Persist hooks on create / approval / join-request / decision / end / token issuance.

**Flutter:**
- `BackendApiService.heartbeatLiveRoom(callId)`.
- `LiveScreen`: refresh timer now 15s — every tick heartbeats *our* streaming room
  (`_heartbeatHostRoom`, guarded by `_isHost && _isStreamLive`) and refreshes the grid when
  not in a room; opening your own room fires an instant first beat.
- real_me bridge card subtitle now reports maintained rooms ("kept alive by host heartbeats").

**Verified — first runtime integration test of the project** (Node 22 available; npm had to
be routed off a pinned `registry.npmmirror.com` lockfile URL to the allowed npmjs registry
for install; lockfile restored afterward):
1. create → 201, `backends: ['realme-bridge','native']`, `requiresApproval` honored ✓
2. room appears in companion list with `heartbeatAt` ✓
3. silent host → pruned after `LIVE_STALE_MS` (log: `[live] pruned room … host heartbeat stale`) ✓
4. heartbeat beats keep the room alive across the stale window; `viewers` update ✓
5. `live_state.json` written with correct contents ✓
6. **server restart → `[live] restored 2 room(s)` → companion list shows the room (viewers 42)** ✓
7. heartbeat accepted after restart; `/live/end` → status `ended` → leaves companion list ✓
8. `node --check` clean on `systems.js`/`index.js`; boot log shows random `ADMIN_CODE`
   generation working; Mongo-less fallback confirmed.

Dart static checks: 0 broken imports, delimiter balance OK.

## 2026-11-09 — Build & run test round (PR #8)

**Goal:** test whether the app can run/build and fix potential issues.

**Environment:** no Flutter/Dart SDK in the sandbox (SDK hosts blocked) → Dart side
verified with static suite; Node 22 available → backend fully runtime-tested.

**Issues found & fixed (7 files, +80/−36):**

1. `backend/video-sources.js` — **syntax error**: object keys with dots were
   unquoted (`BigBuckBunny.mp4:`) and `VIDEO_CDN_MAP.BigBuckBunny.mp4` member
   access. File is lazily `require`d by `/api/video/:filename`, so the server
   booted but every video request threw `SyntaxError` → 500. Quoted all keys,
   fixed the lookup. Now `302 → CDN` for known and unknown filenames (fallback).
2. `lib/services/backend_api_service.dart` `createLiveRoom` — checked
   `statusCode == 200` but the backend answers **201 Created**, so room creation
   from the app always returned `null` ("backend unavailable" snackbar, no
   `call_id`, heartbeats never fired). Now accepts any 2xx.
3. `backend/systems.js` — stale-pruned rooms were **dead forever** (heartbeat →
   409): a host app backgrounded >90s lost its room permanently even after
   resuming. Added `endedReason` (`stale`/`age`/`host`); heartbeat now revives
   `stale` rooms (unless max-age exceeded), host-ended/age rooms stay terminal.
4. `backend/index.js` chat join — Flutter sends `room_id`, handler read only
   `roomId`; schema requires it → membership writes failed with validation 500
   (and `findOne` could match the wrong room). Accepts both spellings + 400 when
   missing.
5. `lib/screens/chat_screen.dart` — room only opened on HTTP 200, so offline /
   no-DB (503) / 401 responses made chat-room taps dead clicks. Membership is
   best-effort: always open the room (mirrors the existing catch fallback).
6. `lib/services/backend_api_service.dart` + `lib/screens/live_screen.dart` +
   `lib/widgets/real_me_bridge.dart` — `getLiveRooms` now distinguishes
   "backend unreachable" (`null` → keep list) from "nothing live" (`[]` →
   backend rooms leave the grid, demo rooms stay); merge now also syncs
   `host_id`/`requires_approval`.
7. Fresh-clone build note: `pubspec.yaml` lists `- .env` as an asset and
   flutter_tools fails the build when it's missing ("No file or variants found
   for asset") — README step 3 (`cp .env.example .env`) covers it; a local
   `.env` (untracked) was created for this checkout.

**Runtime test log (PORT=3100, `LIVE_STALE_MS=1500`): 17/17 passed**
create→201 (backends `realme-bridge`+`native`, approval echoed) · list +
`heartbeatAt` · heartbeat `viewers:42` · join-request→202 · approve→viewerToken
· approved viewer join→200 · unapproved→403 · stale prune ✓ · **heartbeat
revives stale room (200 + back in list)** ✓ · host-end terminal (409) ✓ ·
video→302 CDN + fallback ✓ · chat join 401/503 auth contract ✓ · health OK ·
restart → `[live] restored 3 room(s)` → only live room listed → post-restart
heartbeat → end → list empty ✓. Server log shows full
`pruned (host heartbeat stale) → revived (host heartbeat returned)` cycle.

**Static checks:** `node --check` clean on all backend JS; Dart suite over 110
files: 0 broken imports, delimiter balance clean (proper tokenizer), test/
imports resolve. Real Flutter gate remains: `flutter pub get && flutter analyze
&& flutter test` locally.

## 2026-11-09 — Marketplace · seller dashboards · admin system (PR #9)

**Ask:** add the marketplace + seller dashboards (approved by admin), create an
admin system that manages the whole system and features, admin-only (no regular
user access), and account for the code/features that had been removed (the
Marketplace drawer entry was indeed missing — re-added).

### Backend (`backend/systems.js`, `backend/models/systems.js`)

- **Admin-only surface completed** — every `/api/admin/*` route now requires
  `x-admin-code` (incl. `GET /admin/maintenance`, previously public; the public
  path remains `GET /api/app/config`). New admin list endpoints:
  - `GET /api/admin/users` (db + memory modes, `banned` flag)
  - `GET /api/admin/sellers` (all seller applications)
  - `GET /api/admin/orders` (last 100)
- **Marketplace decisions:** `PUT /api/ecommerce/seller/:userId/reject` and
  `PUT /api/ecommerce/products/:id/reject` (approve now clears `rejected`);
  `productSchema` gained `rejected: Boolean`.
- **Seller dashboard feed:** `GET /api/ecommerce/seller/products` returns the
  seller's own products incl. unapproved/rejected.
- **Feature flags actually gate features:** `marketplaceGate` (ecommerce flag →
  403 on list/apply/post/order for non-admins; admins bypass so they can still
  manage), `liveGate` (live flag → 403 on **create only**; list/join/heartbeat
  untouched so real_me room maintenance is unaffected). Flags: ecommerce,
  gaming, ads, dating, live, shorts, walletPoints.
- **Admin stats** now include `sellers` + `products` counts; ban/unban respond
  `found:false` for unknown IDs (no more silent "db-managed" lies).

### Flutter

- **`admin_dashboard_screen.dart` rewritten** — ADMIN ONLY: the dev-mode
  auto-unlock was REMOVED; the only way in is the backend ADMIN_CODE verified
  against `/admin/stats` on unlock (regular users are stopped at the gate, and
  the backend 403s everything without the code). Four tabs:
  - **Overview** — stats grid (users/sellers/products/orders/wallets/gaming/ads),
    maintenance switch, broadcast announcement, quick links, Lock button.
  - **Market** — seller applications (approve/reject, pending first) + product
    listings (approve/reject, review queue first).
  - **Users** — searchable user directory with ban/unban per row.
  - **Features** — feature-flag toggles for all 7 flags (this is how removed or
    retired features are managed: switch them off platform-wide).
- **`seller_dashboard_screen.dart` (new)** — gate (none/pending/rejected
  messaging), shop header with admin-approved chip + Live/In-review/Rejected/
  Total counters, post-product form (title, price USD, stock, category → posts
  as `approved:false` awaiting admin), product list with per-listing status.
  Route `/seller-dashboard`.
- **`ecommerce_screen.dart`** — approved sellers get an "Open Dashboard"
  entry (replaces the old dead hint).
- **`app_drawer.dart`** — Marketplace entry restored for everyone (it had been
  removed); seller-specific nav only via the marketplace after approval.

### Tests — 49/49 effective checks (Node runtime, PORT=3100, ADMIN_CODE=TestAdmin99)

A: 8×403 no-code on all admin routes (+flags PUT, announce) · B: 6×200 with
code incl. enriched stats/lists · C: apply→pending→admin-sees→approve→status→
post-201→hidden-until-approved→admin all=true→seller feed→approve→public ·
D: product reject hides + seller sees rejected + seller reject + can't post ·
E: ecommerce/live flags 403, admin bypass, real_me list unaffected,
app/config reflects, restore→201 · F: register→ban found:true→list banned→
unban→ghost found:false, video 302, health OK.

Static: `node --check` clean (systems.js, models/systems.js, index.js); Dart
111 files — 0 broken imports, delimiter balance clean. Flutter gate remains
`flutter pub get && flutter analyze && flutter test` locally.

## 2026-11-09 — Nav links · modern profile · desktop · persistent nav · admin feature control · sound (PR #10)

**Ask:** restore the missing nav links, modernize the profile page, enhance the
desktop view, make the nav persist across all screens, put ALL system features
under admin control, and add the sound system.

### Nav links restored
- **Drawer**: fixed broken Downloads link (was a snackbar → now opens the
  screen); tab links no longer `pushReplacementNamed` (which reset the shell) —
  they switch the existing shell via `ShellNav.goTab`; added Search, and new
  Entertainment (Gaming, Watch Party, Local Media) + Tools (Plugins, Devices,
  Install Host, Cache Cleaner) sections; Marketplace/Dating/Live/Shorts/Chat
  hide when the admin flag is off.
- **Desktop sidebar** rebuilt: 5 tabs + 6 grouped sections (Discover, Watch,
  Create, Money, System, Admin) ≈ 30 links (was 9), scrollable, admin group
  only for admin accounts, flag-gated links.
- **Profile menu**: added Marketplace, Wallet, Live Rooms, Vault, Watch Party.

### Persistent nav (`lib/widgets/persistent_nav.dart` — new)
- Every pushed content route now wraps in `PersistentNav`: mobile keeps the
  bottom bar + drawer, desktop (≥900dp) keeps the sidebar — nav never
  disappears while browsing sub-screens. Tab taps pop back to the existing
  `/main` shell and switch its index (no shell duplication/state loss).
- `MainShell` desktop detection switched from `Platform.isLinux` →
  **width ≥ 900dp** (web/Windows/macOS get the desktop layout too).

### Modern profile
- Cover: 4-stop brand→purple gradient with radial glows + film-strip dots;
  avatar wrapped in a red→purple gradient ring with glow; followers/following
  now sit in a glass stats card with a third **Watched** stat; section pills,
  edit/share/QR kept.

### Admin controls ALL features
- Backend gates added: **chat** (`join`/`members` → 403 when off),
  **walletPoints** (`earn`/`convert` → 403; wallet reads unaffected), on top of
  the existing ecommerce/live/gaming/ads gates. `getFeatureFlags` exported for
  index.js. Flag set now: ecommerce, gaming, ads, dating, live, shorts,
  walletPoints, **chat** (8).
- Flutter `FeatureFlagsService` (`lib/services/feature_flags.dart`) loads
  `/api/app/config` at boot (defaults all-enabled, offline-safe) and hides
  nav links/tabs (bottom-nav Shorts & Chat tabs, drawer, sidebar, profile) live
  via `ListenableBuilder`-free direct reads (refresh on next build).

### Sound system
- `SoundEvent.navigation` was defined but **never played anywhere** — now
  wired into: bottom nav taps, drawer items, desktop sidebar taps, profile
  menu tiles, Shorts TikTok nav. (Boot sound + per-event toggles in Settings →
  Sounds already existed and are untouched.)

### Tests — 25/25 runtime checks (Node, PORT=3100, ADMIN_CODE=TestAdmin99)
8 flags present + writable · chat gate 403/restore · walletPoints gate 403 on
earn+convert with reads unaffected + restore 200 · ecommerce/live gates still
green (real_me list unaffected) · admin 403/200 · video 302 · health ·
app/config flags. Static: `node --check` clean (all backend JS), Dart 113
files — 0 broken imports, balance clean.

Flutter gate locally: `flutter pub get && flutter analyze && flutter test`.

## 2026-11-09 — TikTok-style profile card (PR #11)

User ask: "want a modern profile card (tiktok style)".

`_buildProfileHeader` is now a floating card overlapping the cover (offset -52):
- Dark glass card (`#161616`, 24dp radius, hairline border, drop shadow)
- 3px red→purple→cyan (`#25F4EE`) accent strip along the top (TikTok cyan)
- Avatar still has the red→purple gradient ring + online check
- Signature TikTok stats row under the avatar: **Following / Followers / Likes**
  (flat, no enclosing glass box; tap opens the followers sheet)
- Bold `@handle` as the primary name, display name as a secondary line
- Action row: full-width **Edit profile** pill (white, turns red **Save** while
  editing) + three 42×42 icon squares (add friends, share, QR) — the classic
  TikTok profile chrome
- Edit/save is shared via `_toggleEdit()` (app bar pencil + card pill)

Static: Dart 113 files — 0 broken imports, balance clean. No backend change.

Flutter gate locally: `flutter pub get && flutter analyze && flutter test`.

## 2026-11-09 — Dating · Real Me · local player · GitHub installers · top bar · profile (PR #12)

User ask: modern dating + Connect to Real Me, local MP4/MP3 player (vertical
scroll, more controls), direct installers from the GitHub repo (shareable),
restyle top bar / menu icon so clicks work, rebuild the profile card.

### Dating
- Connect to Real Me banner on Discover plus a sheet with `RealMeBridge`
  (copies the companion endpoint, opens live rooms).
- Restyled Date Night app bar with a working menu; super-like on swipe cards.

### Local media
- Browser starts in Movies/Music/Download, requests storage/video/audio
  permissions, filters MP4/MP3, Play-all FAB.
- Player is a vertical PageView. Each page binds `VideoPlayerController.file`
  (mp4) or `AudioPlayer` + `DeviceFileSource` (mp3). Controls: seek, ±10s,
  next/prev, speed, loop, mute, volume, like, share.

### Installers
- `UpdateService.checkForUpdates()` hits GitHub Releases latest
  (`devTechs001/cinemaFlix-flutter`). 404 (no tag yet) still exposes the repo
  / source zip / releases page.
- Install & Host cards share a real link (APK asset if present, else releases
  page, source zip, repo) via share_plus + clipboard.

### Top bar
- Nested Scaffolds made `Scaffold.of(context).openDrawer()` a no-op on Home,
  Shorts, Profile, Dating. `openParentDrawer` walks ancestors until a scaffold
  with a drawer. `CinemaAppBar` restyles the hamburger into a tappable tile.

### Profile
- Removed the floating Transform card (it left a hole under the cover).
- Hero is cover + overlapping gradient-ring avatar + @handle + stats + Edit
  profile pill. No layout gap.

Static: Dart 114 files — 0 broken imports, balance clean. GitHub latest
release currently 404 (no tags) — fallback paths covered.

Flutter gate locally: `flutter pub get && flutter analyze && flutter test`.

## 2026-11-09 — Real installers, download/install, in-app update (PR #13)

User ask: real installers with a download button, direct install, check for
updates, in-app notification.

- `UpdateService.downloadAsset` streams the GitHub asset (or main.zip) to
  temp with real progress. `installLocalFile` opens it: Android APK via
  FileProvider + MethodChannel (`cinemaflix/installer`), Linux/macOS/Windows
  via chmod/xdg-open/open/start.
- Install & Host cards now have **Download** and **Install** (share is
  secondary). Check Now / Update dialog call downloadAndInstall.
- Boot: `startBackgroundCheck` + in-app banner (`notifyUpdate`) that routes
  to `/install`. Also lands in the notifications list.
- Android: `REQUEST_INSTALL_PACKAGES` + FileProvider.
- Platform installer scripts under `installers/` (linux/macos/windows).

Static: Dart 114 files — 0 broken imports, balance clean.

Flutter gate locally: `flutter pub get && flutter analyze && flutter test`.

## 2026-11-09 — In-app sounds, regular update checks, wallet/arcade/creator (PR #14)

- Notifications play `SoundEvent.notification` on the in-app banner. Tapping a
  row can route (update → /install, wallet → /wallet, creator → /creator-hub).
  Leaving the notifications screen no longer `dispose()`s the singleton.
- `soundService.initialize()` runs at boot. Update checks every **30 minutes**,
  on app resume, and when the device comes back online.
- Wallet: daily check-in (streak + pts + diamonds), send-gift, purchase/convert
  sounds + banners, sync from `/api/wallet/:userId`.
- Arcade: diamond balance in the app bar, fallback games, local-wallet play
  when the API is down, win banners.
- Creator: mode persisted, cash-out to wallet, Channel/Settings routes wired.

Static: Dart 114 files — 0 broken imports, balance clean.
Flutter gate locally: `flutter pub get && flutter analyze && flutter test`.

## 2026-11-09 — README installer links (PR #15)

Added an Installers section to README.md with GitHub latest/v0.2.0, Linux /
macOS / Windows script links (blob + raw), source zip, clone URL, and curl/irm
one-liners. Updated the Install & Host / Auto-Update bullets to match.

## 2026-11-09 — Mobile installer links in README (PR #16)

Android and iOS installer scripts + README rows (blob, raw, APK latest URL)
and curl one-liners. In-app Install & Host falls back to those scripts when
no APK/IPA is on the GitHub release.
