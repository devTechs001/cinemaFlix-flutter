# CinemaFlix

A full-featured movie streaming and social app built with Flutter & Supabase.

## Installers

Get the app from GitHub. In-app **Install & Host** uses the same links (Download / Install).

| Platform | Installer |
|----------|-----------|
| **Latest release** | [github.com/devTechs001/cinemaFlix-flutter/releases/latest](https://github.com/devTechs001/cinemaFlix-flutter/releases/latest) |
| **v0.2.0** | [Releases / v0.2.0](https://github.com/devTechs001/cinemaFlix-flutter/releases/tag/v0.2.0) |
| **Android APK** | Attach a `.apk` to a GitHub release, or use the in-app Download button (falls back to source zip until an APK is published) |
| **Linux** | [`installers/install-linux.sh`](https://github.com/devTechs001/cinemaFlix-flutter/blob/main/installers/install-linux.sh) · [raw](https://raw.githubusercontent.com/devTechs001/cinemaFlix-flutter/main/installers/install-linux.sh) |
| **macOS** | [`installers/install-macos.sh`](https://github.com/devTechs001/cinemaFlix-flutter/blob/main/installers/install-macos.sh) · [raw](https://raw.githubusercontent.com/devTechs001/cinemaFlix-flutter/main/installers/install-macos.sh) |
| **Windows** | [`installers/install-windows.ps1`](https://github.com/devTechs001/cinemaFlix-flutter/blob/main/installers/install-windows.ps1) · [raw](https://raw.githubusercontent.com/devTechs001/cinemaFlix-flutter/main/installers/install-windows.ps1) |
| **Source zip** | [cinemaFlix-flutter-main.zip](https://github.com/devTechs001/cinemaFlix-flutter/archive/refs/heads/main.zip) |
| **Clone the repo** | [github.com/devTechs001/cinemaFlix-flutter](https://github.com/devTechs001/cinemaFlix-flutter) |

```bash
# Linux
curl -fsSL https://raw.githubusercontent.com/devTechs001/cinemaFlix-flutter/main/installers/install-linux.sh | bash

# macOS
curl -fsSL https://raw.githubusercontent.com/devTechs001/cinemaFlix-flutter/main/installers/install-macos.sh | bash
```

```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/devTechs001/cinemaFlix-flutter/main/installers/install-windows.ps1 | iex
```

The in-app updater checks GitHub Releases every 30 minutes (and on resume / reconnect).

## Core Features

### Authentication
- Email/password sign up & sign in
- Password reset flow (email code → new password)
- Email verification screen with resend
- Guest mode (browse without account)
- Admin bypass for devtechs842@gmail.com

### Movie Experience
- 18 sample movies with genre, cast, director, ratings
- Movie detail screen with parallax SliverAppBar, animated stars, trailer button
- Movie play screen with auto-hide controls, rewind/forward, brightness/volume gestures
- Search & explore screens
- Watchlist, favorites, history tracking

### Social Feed
- Post creation with images and text
- Like, comment, share, bookmark system
- Gifting with wallet integration (diamond costs)
- Trending topics bar
- Pull-to-refresh, infinite scroll
- Comment sheet with real-time updates

### Shorts (TikTok-style)
- Full-screen vertical video feed
- Double-tap heart animation
- Play/pause on tap
- Progress dots for navigation
- Animated sound waves
- Own bottom nav (Home/Explore/Upload/Dating/Profile)
- Shimmer loading placeholders

### Chat
- Direct 1-on-1 messaging
- Chat rooms with toggleable room list
- Emoji picker for messages
- Reaction long-press on messages
- Read/delivered status indicators
- Typing indicators
- Online presence dots
- User profile bottom sheets

### Live Streaming
- Go-live setup with title & category
- Viewer count, duration timer
- Live gifting with wallet integration
- Interactive comments during stream

### Dating
- Swipeable card stack (Discover tab)
- Like/pass with animations
- Matches grid (Match tab)
- Messages tab for matched users
- Profile details on each card

### Wallet & Economy
- Diamond currency (💎) for gifting & purchases
- Points system earned through engagement
- Points → diamonds conversion (100 pts = 1💎)
- Shop with 6 tiered diamond packs ($0.99-$99.99)
- Transaction history with type icons
- Balance displayed in app bar across screens

### Gifting System
- 6 gift types (Premium, Rental Pass, Ad-Free, etc.)
- Diamond-based pricing instead of dollars
- Wallet integration with balance checking
- Gift history with delivered/pending status
- Send to email or from contacts

### Vault (Private Storage)
- 4-digit PIN lock screen
- Private watchlist (hidden from main lists)
- Secret notes with timestamps
- Hidden gems collection
- Green accent theme (#00C853)

### Stories
- Story bar on home screen (top row)
- Full-screen story viewer
- Tap sides to advance
- Long-press to pause/resume
- Auto-progress bars per segment
- Gradient backgrounds per user

### Install & Host
- Install cards with **Download** and **Install** (Android, iOS/macOS, Windows, Linux, source zip)
- Links match the [Installers](#installers) table above
- Hosting options (Cloud, Self-Hosted, Enterprise)
- Auto-update toggle with GitHub Releases checks
- Check for Updates button with real download progress
- Update dialog with release notes → Download & install

### Auto-Update System
- Background checking every 30 minutes, plus on resume and reconnect
- Version comparison against GitHub Releases latest
- Streams the platform asset (or `main.zip`) to disk
- In-app notification when a newer build is ready
- Manual check button and last-checked timestamp

### Profile & Settings
- Gradient cover banner with avatar
- Animated stat counters (movies, reviews, followers)
- Achievement badges
- Favorites grid, watchlists, reviews
- Edit profile (website, location, bio)
- Share profile button
- QR code display
- Theme customization (multiple color schemes)
- Notifications screen with filters

### Admin
- Dev Panel (visible only to admin email)
- Maintenance mode toggle (blocks all non-admin access)
- Maintenance screen with 5-second polling
- App-wide theme management

### UI/UX
- Dark theme: background #141414, accent #E50914
- InteractiveCard widget for tappable areas
- HapticFeedback on all interactions
- Parallax effects, gradient animations
- Shimmer loading states
- Bouncing scroll physics
- Slide transitions between screens

## Technical Architecture

### State Management
- Provider pattern with ChangeNotifier
- ListenableBuilder for reactive UI
- Singleton services (Supabase, Auth, Wallet, Update)

### Backend
- Supabase for auth, database, real-time, storage
- RLS policies for data security
- 7 database tables with indexes
- Seed data for development

### Services
- AuthService — sign in/up/out, profile management
- SupabaseService — singleton DB wrapper with dotenv
- WalletService — diamonds, points, transactions
- GiftingService — gift catalog & history
- UpdateService — version check & download simulation
- ContactsService — mock contacts with avatars
- MediaService — camera/gallery/media picker
- ThemeService — dynamic theme switching
- DevService — maintenance mode toggle
- GuestService — guest session management

### Models
- SampleMovie — movie metadata with gradient colors
- UserModel — user profile with admin flag
- ChatMessageModel — message with reactions & status
- ReviewModel — movie reviews with ratings
- NotificationModel — notification data

## Screens & Routes

| Route | Screen | Description |
|-------|--------|-------------|
| /splash | SplashScreen | Animated gradient, particles, version |
| /onboarding | OnboardingScreen | Feature walkthrough |
| /auth | AuthScreen | Sign in / sign up / guest |
| /main | MainShell | Bottom nav (Home/Feed/Shorts/Live/Chat) |
| /movie-detail | MovieDetailScreen | Parallax movie details |
| /shorts | ShortsScreen | TikTok-style feed |
| /search | SearchScreen | Movie search |
| /explore | ExploreScreen | Browse by genre |
| /dating | DatingScreen | Swipe cards & matches |
| /chat | ChatScreen | Messages & rooms |
| /wallet | WalletScreen | Diamonds, shop, history |
| /gifting | GiftingScreen | Send gifts to friends |
| /vault | VaultScreen | PIN-locked private storage |
| /install | InstallHostScreen | Downloads & auto-updates |
| /settings | SettingsScreen | App settings |
| /themes | ThemesScreen | Color themes |
| /profile | ProfileScreen | User profile with stats |
| /notifications | NotificationsScreen | Alerts & updates |
| /dev-panel | DevPanelScreen | Admin controls |
| /maintenance | MaintenanceScreen | App disabled notice |
| /records | RecordsScreen | Watch history |
| /recover | RecoverScreen | Account recovery |
| /email-verification | EmailVerificationScreen | Verify email prompt |
| /password-reset | PasswordResetScreen | Reset password flow |

## Testing
- 19 unit tests (MovieModel, ReviewModel, ChatMessageModel, GuestService)
- Run with: `flutter test`

## Development Setup
1. Clone the repo
2. `flutter pub get`
3. Copy `.env.example` to `.env` and add Supabase credentials
4. `flutter run`

## Build Commands
- `flutter analyze` — static analysis
- `flutter test` — run tests
- `flutter build apk` — Android release
- `flutter build ios` — iOS release
- `flutter build web` — web deployment
