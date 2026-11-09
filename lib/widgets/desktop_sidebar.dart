import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../services/globals.dart';
import '../services/sound_service.dart' show SoundEvent;
import '../theme/app_tokens.dart';

/// Persistent sidebar for desktop layouts (≥900dp on any platform).
///
/// Mirrors the five main tabs of [MainShell] and adds the complete set of
/// quick links to every pushed destination — replacing the bottom bar +
/// drawer on desktop. Links the admin switched off via feature flags are
/// hidden live.
class DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.dynamic_feed_outlined, Icons.dynamic_feed, 'Feed'),
    (Icons.video_library_outlined, Icons.video_library, 'Shorts'),
    (Icons.chat_outlined, Icons.chat, 'Chat'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  void _go(BuildContext context, String route) {
    HapticFeedback.selectionClick();
    soundService.play(SoundEvent.navigation);
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final flags = featureFlagsService;
    return Container(
      width: 248,
      color: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Icon(Icons.movie_filter_rounded, color: AppColors.brand, size: 26),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CinemaFlix',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < _tabs.length; i++)
            if (_tabs[i].$3 != 'Shorts' || flags.isEnabled('shorts'))
              if (_tabs[i].$3 != 'Chat' || flags.isEnabled('chat'))
                _SidebarItem(
                  icon: _tabs[i].$2,
                  fallbackIcon: _tabs[i].$1,
                  label: _tabs[i].$3,
                  selected: currentIndex == i,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    soundService.play(SoundEvent.navigation);
                    onNavigate(i);
                  },
                ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(height: 1, color: AppColors.surfaceVariant),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              physics: const BouncingScrollPhysics(),
              children: [
                _group(context, 'Discover', [
                  (Icons.explore_rounded, Icons.explore_outlined, 'Explore', '/explore', null),
                  (Icons.search_rounded, Icons.search, 'Search', '/search', null),
                  (Icons.history_rounded, Icons.history, 'Records', '/records', null),
                  (Icons.notifications_rounded, Icons.notifications_none, 'Notifications', '/notifications', null),
                ]),
                _group(context, 'Watch', [
                  (Icons.live_tv_rounded, Icons.live_tv, 'Live', '/live', 'live'),
                  (Icons.storefront, Icons.storefront, 'Marketplace', '/ecommerce', 'ecommerce'),
                  (Icons.sports_esports, Icons.sports_esports, 'Gaming', '/gaming', 'gaming'),
                  (Icons.group_work, Icons.group_work, 'Watch Party', '/watch-party', null),
                  (Icons.folder, Icons.folder, 'Local Media', '/local-media', null),
                ]),
                _group(context, 'Create', [
                  (Icons.videocam, Icons.videocam_outlined, 'Creator Hub', '/creator-hub', null),
                  (Icons.upload, Icons.upload, 'Upload', '/creator-upload', null),
                  (Icons.extension, Icons.extension, 'Plugins', '/plugins', null),
                ]),
                _group(context, 'Money', [
                  (Icons.diamond, Icons.diamond, 'Wallet', '/wallet', null),
                  (Icons.card_giftcard, Icons.card_giftcard_outlined, 'Gifting', '/gifting', null),
                  (Icons.lock, Icons.lock_outline, 'Vault', '/vault', null),
                  (Icons.favorite_rounded, Icons.favorite_border, 'Dating', '/dating', 'dating'),
                ]),
                _group(context, 'System', [
                  (Icons.download, Icons.download_outlined, 'Downloads', '/downloads', null),
                  (Icons.devices, Icons.devices, 'Devices', '/devices', null),
                  (Icons.computer, Icons.computer, 'Install Host', '/install', null),
                  (Icons.cleaning_services, Icons.cleaning_services, 'Cache Cleaner', '/cache-cleaner', null),
                  (Icons.palette_rounded, Icons.palette_outlined, 'Themes', '/themes', null),
                  (Icons.settings_rounded, Icons.settings_outlined, 'Settings', '/settings', null),
                ]),
                if (authService.currentUser?.isAdmin ?? false) ...[
                  _group(context, 'Admin', [
                    (Icons.admin_panel_settings_rounded, Icons.admin_panel_settings_outlined, 'Admin Room', '/admin-dashboard', null),
                    (Icons.code, Icons.code, 'Dev Panel', '/dev-panel', null),
                  ]),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'CinemaFlix · desktop',
              style: TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// A titled group of quick links; hidden entirely when every link in it
  /// is switched off by the admin.
  Widget _group(BuildContext context, String title, List<(IconData, IconData, String, String, String?)> links) {
    final visible = links.where((l) => l.$5 == null || featureFlagsService.isEnabled(l.$5!)).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w600),
            ),
          ),
          for (final l in visible)
            _SidebarItem(
              icon: l.$1,
              fallbackIcon: l.$2,
              label: l.$3,
              onTap: () => _go(context, l.$4),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData fallbackIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.fallbackIcon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected ? AppColors.brand.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(
                  selected ? icon : fallbackIcon,
                  size: 18,
                  color: selected ? AppColors.brand : Colors.white70,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
