import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../services/globals.dart';
import '../services/sound_service.dart' show SoundEvent;
import 'app_drawer.dart';
import 'desktop_sidebar.dart';
import 'offline_banner.dart';

/// Navigation shell that persists around pushed screens: bottom bar +
/// drawer on mobile, the full desktop sidebar at ≥900dp.
///
/// Tapping a tab pops back to the existing `/main` shell and switches its
/// index (via [ShellNav]), so navigation state and the shell itself are
/// never duplicated — the nav simply never disappears while browsing
/// sub-screens (Marketplace, Live, Wallet, Settings, ...).
class ShellNav {
  ShellNav._();

  /// Registered by [MainShell]; accepts the target tab index.
  static void Function(int index)? _setTab;

  static void register(void Function(int index) setter) => _setTab = setter;
  static void unregister() => _setTab = null;

  /// Pops to `/main` (if it's on the stack) and selects [index].
  static void goTab(BuildContext context, int index) {
    final nav = Navigator.of(context);
    var poppedToMain = false;
    nav.popUntil((route) {
      if (route.settings.name == '/main') poppedToMain = true;
      return poppedToMain;
    });
    if (!poppedToMain) {
      nav.pushNamedAndRemoveUntil('/main', (r) => false, arguments: index);
      return;
    }
    _setTab?.call(index);
  }
}

class PersistentNav extends StatelessWidget {
  final Widget child;

  /// Tab to highlight; -1 for pushed sub-screens (no tab selected).
  final int highlightTab;

  const PersistentNav({super.key, required this.child, this.highlightTab = -1});

  static const _tabs = [
    (0, Icons.home_outlined, Icons.home, 'Home', 'home'),
    (1, Icons.dynamic_feed_outlined, Icons.dynamic_feed, 'Feed', null),
    (2, Icons.video_library_outlined, Icons.video_library, 'Shorts', 'shorts'),
    (3, Icons.chat_outlined, Icons.chat, 'Chat', 'chat'),
    (4, Icons.person_outline, Icons.person, 'Profile', null),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return Row(
        children: [
          DesktopSidebar(
            currentIndex: highlightTab,
            onNavigate: (index) => ShellNav.goTab(context, index),
          ),
          const VerticalDivider(width: 1, color: Color(0xFF2A2A2A)),
          Expanded(
            child: OfflineBanner(
              connectivityService: connectivityService,
              child: child,
            ),
          ),
        ],
      );
    }

    final visibleTabs =
        _tabs.where((t) => t.$5 == null || featureFlagsService.isEnabled(t.$5!)).toList();

    return Scaffold(
      drawer: const AppDrawer(),
      body: OfflineBanner(
        connectivityService: connectivityService,
        child: child,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: () {
            final idx = visibleTabs.indexWhere((t) => t.$1 == highlightTab);
            return idx < 0 ? 0 : idx;
          }(),
          onTap: (position) {
            HapticFeedback.selectionClick();
            soundService.play(SoundEvent.navigation);
            ShellNav.goTab(context, visibleTabs[position].$1);
          },
          type: BottomNavigationBarType.fixed,
          items: [
            for (final t in visibleTabs)
              BottomNavigationBarItem(
                icon: Icon(t.$2),
                activeIcon: Icon(t.$3),
                label: t.$4,
              ),
          ],
        ),
      ),
    );
  }
}
