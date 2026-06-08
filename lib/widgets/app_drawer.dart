import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_logo.dart';
import 'interactive_card.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onClose;

  const AppDrawer({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF141414),
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  _sectionTitle('Main'),
                  _drawerItem(Icons.home_rounded, 'Home', () => _navigate(context, '/main')),
                  _drawerItem(Icons.live_tv_rounded, 'Live', () => _navigate(context, '/main', extra: 1)),
                  _drawerItem(Icons.video_library_rounded, 'Shorts', () => Navigator.pushNamed(context, '/shorts')),
                  _drawerItem(Icons.explore_rounded, 'Explore', () => _navigate(context, '/main', extra: 2)),
                  _drawerItem(Icons.chat_rounded, 'Chat', () => _navigate(context, '/main', extra: 3)),
                  _sectionTitle('Library'),
                  _drawerItem(Icons.bookmark_rounded, 'Watchlist', () => HapticFeedback.lightImpact()),
                  _drawerItem(Icons.favorite_rounded, 'Favorites', () => HapticFeedback.lightImpact()),
                  _drawerItem(Icons.history_rounded, 'History', () => Navigator.pushNamed(context, '/records')),
                  _drawerItem(Icons.download_rounded, 'Downloads', () => HapticFeedback.lightImpact()),
                  _sectionTitle('Social'),
                  _drawerItem(Icons.notifications_rounded, 'Notifications', () => Navigator.pushNamed(context, '/notifications'), badge: '3'),
                  _drawerItem(Icons.card_giftcard_rounded, 'Gifting', () => Navigator.pushNamed(context, '/gifting')),
                  _drawerItem(Icons.group_rounded, 'Contacts', () => HapticFeedback.lightImpact()),
                  _sectionTitle('Settings'),
                  _drawerItem(Icons.settings_rounded, 'Settings', () => Navigator.pushNamed(context, '/settings')),
                  _drawerItem(Icons.palette_rounded, 'Themes', () => Navigator.pushNamed(context, '/themes')),
                  _drawerItem(Icons.admin_panel_settings_rounded, 'Dev Panel', () => Navigator.pushNamed(context, '/dev-panel')),
                  _sectionTitle('Account'),
                  _drawerItem(Icons.person_rounded, 'Profile', () => _navigate(context, '/main', extra: 4)),
                  _drawerItem(Icons.logout_rounded, 'Sign Out', () {
                    HapticFeedback.heavyImpact();
                    Navigator.pop(context);
                  }, isDanger: true),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          const AppLogo(size: 40, showText: false),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CinemaFlix', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 18)),
              Text('v1.0 • Premium', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const Spacer(),
          InteractiveCard(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onClose?.call();
            },
            scaleAmount: 0.85,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: Colors.white38, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {String? badge, bool isDanger = false}) {
    return InteractiveCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ListTile(
          leading: Icon(icon, color: isDanger ? Colors.red : Colors.white54, size: 22),
          title: Text(
            title,
            style: TextStyle(
              color: isDanger ? Colors.red : Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          trailing: badge != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                )
              : const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _footerIcon(Icons.settings, 'Settings', () => Navigator.pushNamed(context, '/settings')),
          _footerIcon(Icons.help_outline, 'Help', () => HapticFeedback.lightImpact()),
          _footerIcon(Icons.info_outline, 'About', () => HapticFeedback.lightImpact()),
        ],
      ),
    );
  }

  Widget _footerIcon(IconData icon, String label, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      scaleAmount: 0.88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String route, {int extra = 0}) {
    Navigator.pop(context);
    if (extra > 0) {
      Navigator.pushReplacementNamed(context, route);
    } else {
      Navigator.pushNamed(context, route);
    }
  }
}
