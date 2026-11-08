import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Persistent sidebar for desktop (Linux/keyboard-driven) builds.
///
/// Mirrors the five main tabs of [MainShell] and adds quick links to
/// pushed destinations — replacing the bottom bar + drawer on desktop.
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
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
                Text(
                  'CinemaFlix',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < _tabs.length; i++)
            _SidebarItem(
              icon: _tabs[i].$2,
              fallbackIcon: _tabs[i].$1,
              label: _tabs[i].$3,
              selected: currentIndex == i,
              onTap: () => onNavigate(i),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Divider(height: 1, color: AppColors.surfaceVariant),
          ),
          _SidebarItem(
            icon: Icons.explore_rounded,
            fallbackIcon: Icons.explore_outlined,
            label: 'Explore',
            onTap: () => Navigator.pushNamed(context, '/explore'),
          ),
          _SidebarItem(
            icon: Icons.search_rounded,
            fallbackIcon: Icons.search,
            label: 'Search',
            onTap: () => Navigator.pushNamed(context, '/search'),
          ),
          _SidebarItem(
            icon: Icons.history_rounded,
            fallbackIcon: Icons.history,
            label: 'Records',
            onTap: () => Navigator.pushNamed(context, '/records'),
          ),
          _SidebarItem(
            icon: Icons.settings_rounded,
            fallbackIcon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? AppColors.brand.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? icon : fallbackIcon,
                  size: 20,
                  color: selected ? AppColors.brand : Colors.white70,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
