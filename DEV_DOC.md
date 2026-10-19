# CinemaFlix — Development Status Doc

Last updated: 2026-10-19 (post bugs.txt implementation pass)

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

## Future improvements (advice)

1. **Real OAuth**: verify Google/Apple idTokens server-side (JWKs) before trusting the email payload; then remove the dev-simulated path.
2. **SMS provider**: wire `/auth/phone/request-otp` to a provider (Twilio/ Africa's Talking) and stop returning `devCode`.
3. **WebSockets**: bugs.txt asks for real-time sockets for chat/notifications. The realtime messaging service in the client targets a WS endpoint; add `ws` on the backend and use the same endpoints rather than polling.
4. **DB-backed admin stores**: wallets/games/ecommerce are currently in-memory in `systems.js` — move to Mongo/Postgres models for durability before production.
5. **Sound assets**: add `assets/sounds/*` (including the CinemaFlix announcer voice) and switch `SoundService` to playing real audio files — the per-event API stays the same.
6. **Rate limiting / abuse controls** on gifts, gaming, and seller endpoints.
7. **Test coverage**: add tests for `SoundService`, `AdsService`, wallet mirroring, and backend systems.js flows.
