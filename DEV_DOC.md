# CinemaFlix — Development Status Doc

Last updated: 2026-10-19 (second pass — production-grade fixes to the first pass limitations)

## What's accomplished ✅

### Auth system (fixed — was incomplete)
- Email/password sign-in + sign-up wired to backend `/api/auth/login` & `/api/auth/register` (JWT sessions, bcrypt, 7-day tokens).
- **Removed the hard-coded developer backdoor** (devtechs842/pass123 special case) — developer access now goes exclusively through the Dev Panel access code.
- **Google & Apple OAuth**: backend upserts the provider profile into a user account (`/api/auth/oauth/google`, `/api/auth/oauth/apple`). Google OAuth runs in dev-simulated mode; production requires verifying the idToken against Google's JWKs (see pending).
- **Phone sign-in (OTP)**: `/api/auth/phone/request-otp` + `/api/auth/phone/verify-otp`, 6-digit codes with expiry and attempt limits, full dialog flow in the auth screen. Dev response returns the code for testing — production must send via an SMS provider (pending).
- Session restore with wallet mirroring enabled on restore.

### Backend systems (was "backend incomplete")
New `backend/systems.js` module — works with or without the database (in-memory fallbacks):
- **App config** `GET /api/app/config` — version, maintenance status, feature flags.
- **Admin/dev system** `GET /api/admin/stats`, `GET/PUT /api/admin/feature-flags`, `GET/PUT /api/admin/maintenance` (message + allowAdmins + allowSpecific), `PUT /api/admin/users/:id/ban|unban`, `PUT /api/admin/popups`. Auth via `x-admin-code` header (`ADMIN_CODE` env, default `admin123`).
- **Wallet** `/api/wallet/:userId` — balance, spend, earn, convert (points↔diamonds), gift (p2p with note history). Flutter `WalletService` mirrors every local transaction to these endpoints non-destructively (local wallet stays source of truth).
- **Ads** `GET /api/ads`, impression/click tracking, click rewards (+2 pts into the ad clicker's wallet), `GET /api/admin/ads/stats` for partner/earnings view.
- **Gaming** `GET /api/games`, `POST /api/games/:id/play` (diamond stake, weighted multipliers, wallet payout, session log), `GET /api/games/leaderboard`.
- **Ecommerce** — seller applications requiring admin approval, approved-seller-only product posting, diamond-priced orders with stock, `GET /api/ecommerce/products`.
- **Sounds/settings endpoints** `GET/PUT /api/settings/:userId` — sound toggles, auto-clean prefs, popup prefs.
- **Live / real_me interop** `POST /api/live/create` (host token), `POST /api/live/viewer/token`, `GET /api/live/rooms` — token-based bridge for the real_me companion app.

### Admin dashboard (new screen)
`admin_dashboard_screen.dart` (route `/admin-dashboard`, also in the Dev Panel quick links):
- Unlock gate (admin code), live backend stats (users, wallets, ad impressions/clicks, gaming sessions, orders).
- Maintenance mode toggle wired both locally (DevService) and to the backend endpoint.
- User ban/unban dialog through `/api/admin/users/:id/ban`.
- Backend feature flags endpoint exists for every major system (`ecommerce`, `gaming`, `ads`, `dating`, `live`, `shorts`, `walletPoints`).

### Splash, onboarding, nav
- Splash: glow/particle animations + boot notification sound + **Netflix-style featured movie-card strip** (poster images with title/rating overlays).
- **One-time preference onboarding**: persisted `onboarding_complete` flag; skip/finish both persist it; subsequent launches go straight to `/main`.
- Dedicated nav per dashboard: TikTok-style nav for shorts (`shorts_tiktok_nav.dart`), app drawer + desktop sidebar already cover the main dashboards; new screens registered in the router.

### Sounds, notifications, popups
- New `SoundService` with per-event toggles persisted locally (notification, success, transaction, like, comment, celebrate, gift, popups, navigation) — haptics + `SystemSound`.
- **Settings screen "Sounds" section**: master toggle + per-event rows.
- Sounds play on: boot, onboarding finish, purchases, ads, gaming outcomes, notifications.
- Popup/notification overlay existed (`notification_alert_overlay.dart`); backend popup toggle added.

### Ads in shorts
- `AdsService` fetches backend banners, tracks impressions + click rewards into the wallet.
- `AdOverlayScheduler`: free users see a sponsored banner after **2 minutes of continuous watching**; closing requires 5s view; click pays wallet points with a snackbar.
- **Subscription gate**: high wallet balance (≫900 diamonds ≈ premium) exempts from mid-watch ads.

### Ecommerce & gaming screens (new)
- `/ecommerce`: marketplace grid priced in diamonds, buyer flow (sign-in required, order + wallet debit), seller application CTA with status feedback, amber "approved seller" chip.
- `/gaming`: Arcade with 3 games, wallet-staked plays, result banner, top-10 leaderboard.

## What's done in the repo but still pending polish

- **Profiles/screens polish**: profile, dating, wallet, vault screens exist with modern layouts; per bugs.txt further design iterations (e.g., cover photo pickers, engagement analytics components) remain design work.
- **Stories interactions / watch-party reactions**: stories + watch party screens exist; deeper reaction/gift wiring is incremental.

## Second pass — previous limitations resolved ✅

1. **Real OAuth** — `/api/auth/oauth/*` now verifies Google/Apple idTokens against the provider JWKS (RS256, issuer + audience checks; no extra deps — node crypto imports JWKs directly). Keys cached 1h. The simulated path is now gated behind `OAUTH_DEV_MODE=true`; without it, requests without a valid idToken get 401.
2. **SMS provider** — phone OTP sends via Twilio when `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER` are set; only when they are missing does the endpoint return `devCode` (marked `"via": "dev"`).
3. **WebSockets** — real WS gateway at `ws://<backend>/ws` (`backend/realtime.js`): rooms, presence broadcasts, typing, chat relay, admin announcements (via `POST /api/admin/announce`); JWT-authenticated identity or dev `userId` params. Flutter `RealtimeMessagingService` now connects with `web_socket_channel` (works on web + mobile), auto-reconnects every 5s, joins rooms on open, relays messages/typing, plays a comment sound on incoming messages.
4. **DB-backed stores** — `backend/models/systems.js` gives Mongoose models for wallets (with transaction history), game sessions, leaderboard, products, seller applications, orders, user settings, admin config, ad events. `systems.js` routes read/write Mongo when connected and transparently fall back to in-memory Maps otherwise. Wallet saves go through `doc.save()`; a Mongoose `type`-key pitfall in the transaction subdoc was fixed with an explicit sub-Schema.
5. **Sound assets** — ten synthesized WAVs under `assets/sounds/` (notification, popups, success, transaction, like, comment, celebrate, gift, navigation, open) played through `audioplayers` with a small player pool + haptics; splash uses the branded `open.wav` boot chime. Recorded announcer voice can replace `open.wav` with no code changes.

> Note: live tests covered the Mongo path (storage: `mongo`), the OTP dev-code fallback, OAuth 401-rejection, wallet mirroring, and a two-client WS room relay. Twilio delivery itself could not be verified here — no credentials — set the env vars and send to a real number to confirm.

## Remaining future improvements

6. **Rate limiting / abuse controls** on gifts, gaming, and seller endpoints.
7. **Test coverage**: add tests for `SoundService`, `AdsService`, wallet mirroring, and backend systems.js flows.
