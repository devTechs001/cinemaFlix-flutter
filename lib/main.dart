import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:system_tray/system_tray.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/theme_service.dart';
import 'services/globals.dart';
import 'services/storage_service.dart';
import 'services/lock_service.dart';
import 'services/movie_db_service.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_screen.dart';
import 'screens/dating_screen.dart';
import 'screens/shorts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/dev_panel_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/ecommerce_screen.dart';
import 'screens/seller_dashboard_screen.dart';
import 'screens/gaming_screen.dart';
import 'screens/gifting_screen.dart';
import 'screens/records_screen.dart';
import 'screens/recover_screen.dart';
import 'screens/themes_screen.dart';
import 'screens/search_screen.dart';
import 'screens/explore_screen.dart';
import 'models/sample_movies.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/social_feed_screen.dart';
import 'screens/install_host_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/creator_hub_screen.dart';
import 'screens/creator_content_screen.dart';
import 'screens/creator_analytics_screen.dart';
import 'screens/creator_earnings_screen.dart';
import 'screens/upload_content_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/connected_devices_screen.dart';
import 'screens/cache_cleaner_screen.dart';
import 'screens/plugins_screen.dart';
import 'screens/local_media_screen.dart';
import 'screens/local_media_player_screen.dart';
import 'screens/watch_party_screen.dart';
import 'screens/user_profile_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/desktop_sidebar.dart';
import 'widgets/offline_banner.dart';
import 'widgets/notification_alert_overlay.dart';
import 'widgets/shorts_tiktok_nav.dart';
import 'widgets/persistent_nav.dart';
import 'services/sound_service.dart' show SoundEvent;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Missing/unreadable .env — surface a clear config screen instead
    // of crashing before the first frame (see ConfigErrorApp below).
    runApp(const ConfigErrorApp(message: 'Missing env'));
    return;
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await themeService.initialize();
  await SupabaseService().initialize(); // never throws; app runs backend-only on failure
  storageService.checkStorage();
  await lockService.initialize();
  featureFlagsService.load(); // fire-and-forget: admin feature flags
  await localDbService.initialize(); // SQLite — without this everything runs in-memory
  await syncService.initialize();
  await movieDbService.initialize(); // real-time catalogue import
  _initSystemTray();
  runApp(const CinemaFlixApp());
}

/// Shown instead of the app when required configuration (.env) is missing.
class ConfigErrorApp extends StatelessWidget {
  final String message;
  const ConfigErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinemaFlix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF141414),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.movie_filter_rounded,
                    color: Color(0xFFE50914), size: 56),
                const SizedBox(height: 20),
                const Text(
                  'Configuration error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Copy .env.example to .env and fill in your keys, then restart.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _initSystemTray() async {
  if (!Platform.isLinux) return;
  try {
    final tray = SystemTray();
    await tray.initSystemTray(
      title: 'CinemaFlix',
      iconPath: 'assets/icon/app_icon.png',
      toolTip: 'CinemaFlix',
    );
    final menu = [
      MenuItem(label: 'Show', onClicked: () => tray.popUpContextMenu()),
      MenuItem(label: 'Quit', onClicked: () => SystemNavigator.pop()),
    ];
    await tray.setContextMenu(menu);
  } catch (e) {
    debugPrint('SystemTray: Failed to init: $e');
  }
}

final cinemaNavigatorKey = GlobalKey<NavigatorState>();

class CinemaFlixApp extends StatefulWidget {
  const CinemaFlixApp({super.key});

  @override
  State<CinemaFlixApp> createState() => _CinemaFlixAppState();
}

class _CinemaFlixAppState extends State<CinemaFlixApp> {
  bool _wasOnline = true;
  bool _updateNotified = false;

  @override
  void initState() {
    super.initState();
    _wasOnline = connectivityService.isOnline;
    connectivityService.addListener(_onConnectivityChanged);
    storageService.addListener(_onStorageChanged);
    updateService.addListener(_onUpdateService);
    updateService.startBackgroundCheck();
  }

  @override
  void dispose() {
    connectivityService.removeListener(_onConnectivityChanged);
    storageService.removeListener(_onStorageChanged);
    updateService.removeListener(_onUpdateService);
    super.dispose();
  }

  void _onUpdateService() {
    if (_updateNotified || !updateService.hasNewerBuild) return;
    _updateNotified = true;
    final version = updateService.latestUpdate?.version ?? '';
    notificationService.notifyUpdate(
      version: version,
      onTap: () => cinemaNavigatorKey.currentState?.pushNamed('/install'),
    );
  }

  void _onConnectivityChanged() {
    final online = connectivityService.isOnline;
    if (online != _wasOnline) {
      _wasOnline = online;
      if (online) {
        notificationService.showAlert(
          title: 'Back Online',
          body: 'Connection restored (${connectivityService.strengthLabel})',
          icon: '📶',
          color: const Color(0xFF10B981),
        );
      } else {
        notificationService.showConnectivityAlert(false, '');
      }
    }
  }

  void _onStorageChanged() {
    if (storageService.checkAlertNeeded()) {
      notificationService.showStorageAlert(storageService.info!.alertLevel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp(
      navigatorKey: cinemaNavigatorKey,
      title: 'CinemaFlix',
      debugShowCheckedModeBanner: false,
      theme: themeService.activeTheme,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: _NoScrollbarBehavior(),
          child: NotificationAlertOverlay(child: child!),
        );
      },
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/auth': (_) => const AuthScreen(),
        '/main': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final int index = args is int ? args : 0;
          return MainShell(initialIndex: index);
        },
        '/shorts': (_) => const PersistentNav(child: ShortsScreen()),
        '/search': (_) => const PersistentNav(child: SearchScreen()),
        '/explore': (_) => const PersistentNav(child: ExploreScreen()),
        '/notifications': (_) => const PersistentNav(child: NotificationsScreen()),
        '/settings': (_) => const PersistentNav(child: SettingsScreen()),
        '/dev-panel': (_) => const PersistentNav(child: DevPanelScreen()),
        '/admin-dashboard': (_) => const AdminDashboardScreen(),
        '/ecommerce': (_) => const PersistentNav(child: EcommerceScreen()),
        '/seller-dashboard': (_) => const PersistentNav(child: SellerDashboardScreen()),
        '/gaming': (_) => const PersistentNav(child: GamingScreen()),
        '/gifting': (_) => const PersistentNav(child: GiftingScreen()),
        '/records': (_) => const PersistentNav(child: RecordsScreen()),
        '/recover': (_) => const RecoverScreen(),
        '/themes': (_) => const PersistentNav(child: ThemesScreen()),
        '/dating': (_) => const PersistentNav(child: DatingScreen()),
        '/live': (_) => const PersistentNav(child: LiveScreen()),
        '/chat': (_) => const PersistentNav(child: ChatScreen()),
        '/downloads': (_) => const PersistentNav(child: DownloadsScreen()),
        '/install': (_) => const PersistentNav(child: InstallHostScreen()),
        '/maintenance': (_) => const PersistentNav(child: MaintenanceScreen()),
        '/vault': (_) => const PersistentNav(child: VaultScreen()),
        '/wallet': (_) => const PersistentNav(child: WalletScreen()),
        '/email-verification': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return EmailVerificationScreen(email: email);
        },
        '/password-reset': (_) => const PasswordResetScreen(),
        '/creator-hub': (_) => const PersistentNav(child: CreatorHubScreen()),
        '/creator-content': (_) => const PersistentNav(child: CreatorContentScreen()),
        '/creator-analytics': (_) => const PersistentNav(child: CreatorAnalyticsScreen()),
        '/creator-earnings': (_) => const PersistentNav(child: CreatorEarningsScreen()),
        '/creator-upload': (_) => const PersistentNav(child: UploadContentScreen()),
        '/devices': (_) => const PersistentNav(child: ConnectedDevicesScreen()),
        '/cache-cleaner': (_) => const PersistentNav(child: CacheCleanerScreen()),
        '/plugins': (_) => const PersistentNav(child: PluginsScreen()),
        '/local-media': (_) => const PersistentNav(child: LocalMediaScreen()),
        '/local-player': (_) => const LocalMediaPlayerScreen(),
        '/watch-party': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          return PersistentNav(
            child: WatchPartyScreen(movieId: args['movieId'] ?? '', movieTitle: args['movieTitle'] ?? ''),
          );
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/user-profile') {
          final userId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => PersistentNav(child: UserProfileScreen(userId: userId)),
          );
        }
        if (settings.name == '/movie-detail') {
          final movie = settings.arguments as SampleMovie;
          return PageRouteBuilder(
            pageBuilder: (context, anim1, anim2) => MovieDetailScreen(movie: movie),
            transitionsBuilder: (context, anim, secondaryAnimation, child) =>
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
            transitionDuration: const Duration(milliseconds: 300),
          );
        }
        return null;
      },
    );
        },
    );
  }
}

class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    ShellNav.register((index) {
      if (mounted) setState(() => _currentIndex = index);
    });
  }

  @override
  void dispose() {
    ShellNav.unregister();
    super.dispose();
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    SocialFeedScreen(),
    ShortsScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Desktop layout at the ≥900dp breakpoint (any platform, incl. web).
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return Row(
        children: [
          DesktopSidebar(
            currentIndex: _currentIndex,
            onNavigate: (index) => setState(() => _currentIndex = index),
          ),
          const VerticalDivider(width: 1, color: Color(0xFF2A2A2A)),
          Expanded(
            child: OfflineBanner(
              connectivityService: connectivityService,
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: OfflineBanner(
        connectivityService: connectivityService,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _currentIndex == 2
          ? ShortsTikTokNav(
              onHome: () {
                soundService.play(SoundEvent.navigation);
                setState(() => _currentIndex = 0);
              },
              onDiscover: () {},
              onCreate: () {
                soundService.play(SoundEvent.navigation);
                Navigator.pushNamed(context, '/creator-upload');
              },
              onInbox: () {
                soundService.play(SoundEvent.navigation);
                setState(() => _currentIndex = 3);
              },
              onProfile: () {
                soundService.play(SoundEvent.navigation);
                setState(() => _currentIndex = 4);
              },
              inboxBadge: 3,
            )
          : Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
        ),
        child: Builder(
          builder: (context) {
            // Tabs can be switched off by the admin (feature flags).
            final tabs = <(int, BottomNavigationBarItem)>[
              (0, BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home')),
              (1, BottomNavigationBarItem(icon: Icon(Icons.dynamic_feed_outlined), activeIcon: Icon(Icons.dynamic_feed), label: 'Feed')),
              if (featureFlagsService.isEnabled('shorts'))
                (2, BottomNavigationBarItem(icon: Icon(Icons.video_library_outlined), activeIcon: Icon(Icons.video_library), label: 'Shorts')),
              if (featureFlagsService.isEnabled('chat'))
                (3, BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: 'Chat')),
              (4, BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile')),
            ];
            var pos = tabs.indexWhere((t) => t.$1 == _currentIndex);
            if (pos < 0) pos = 0;
            return BottomNavigationBar(
              currentIndex: pos,
              onTap: (index) {
                HapticFeedback.selectionClick();
                soundService.play(SoundEvent.navigation);
                setState(() => _currentIndex = tabs[index].$1);
              },
              type: BottomNavigationBarType.fixed,
              items: [for (final t in tabs) t.$2],
            );
          },
        ),
      ),
    );
  }
}
