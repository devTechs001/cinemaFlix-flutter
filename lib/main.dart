import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/supabase_service.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/live_screen.dart';
import 'screens/shorts_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/dev_panel_screen.dart';
import 'screens/gifting_screen.dart';
import 'screens/records_screen.dart';
import 'screens/recover_screen.dart';
import 'screens/themes_screen.dart';
import 'screens/search_screen.dart';
import 'screens/explore_screen.dart';
import 'models/sample_movies.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/social_feed_screen.dart';
import 'widgets/app_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService().initialize();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const CinemaFlixApp());
}

class CinemaFlixApp extends StatelessWidget {
  const CinemaFlixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp(
      title: 'CinemaFlix',
      debugShowCheckedModeBanner: false,
      theme: themeService.activeTheme,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: _NoScrollbarBehavior(),
          child: child!,
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
        '/shorts': (_) => const ShortsScreen(),
        '/search': (_) => const SearchScreen(),
        '/explore': (_) => const ExploreScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/dev-panel': (_) => const DevPanelScreen(),
        '/gifting': (_) => const GiftingScreen(),
        '/records': (_) => const RecordsScreen(),
        '/recover': (_) => const RecoverScreen(),
        '/themes': (_) => const ThemesScreen(),
      },
      onGenerateRoute: (settings) {
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
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    SocialFeedScreen(),
    ShortsScreen(),
    LiveScreen(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.dynamic_feed_outlined), activeIcon: Icon(Icons.dynamic_feed), label: 'Feed'),
            const BottomNavigationBarItem(icon: Icon(Icons.video_library_outlined), activeIcon: Icon(Icons.video_library), label: 'Shorts'),
            const BottomNavigationBarItem(icon: Icon(Icons.live_tv_outlined), activeIcon: Icon(Icons.live_tv), label: 'Live'),
            const BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: 'Chat'),
          ],
        ),
      ),
    );
  }
}
