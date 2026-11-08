# CinemaFlix

A full-featured movie streaming and social app built with Flutter & Supabase.

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
- Install cards (Android APK, iOS, Desktop, Linux)
- Hosting options (Cloud, Self-Hosted, Enterprise)
- Auto-update toggle with background checks
- Check for Updates button with progress bar
- Update dialog with release notes
- Simulated download with file size info

### Auto-Update System
- Background periodic checking (every 6 hours)
- Version comparison logic
- Download simulation with 10-step progress
- Release notes display
- Manual check button
- Last checked timestamp

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
