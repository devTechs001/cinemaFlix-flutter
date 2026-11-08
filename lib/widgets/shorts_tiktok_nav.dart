import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TikTok-style bottom bar shown while the Shorts tab is active:
/// Home · Discover · Create (+) · Inbox (badge) · Profile.
class ShortsTikTokNav extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onDiscover;
  final VoidCallback onCreate;
  final VoidCallback onProfile;
  final VoidCallback onInbox;
  final int inboxBadge;

  const ShortsTikTokNav({
    super.key,
    required this.onHome,
    required this.onDiscover,
    required this.onCreate,
    required this.onProfile,
    required this.onInbox,
    this.inboxBadge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF101010),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(icon: Icons.home, label: 'Home', onTap: onHome),
              _NavItem(icon: Icons.search_rounded, label: 'Discover', onTap: onDiscover),
              Expanded(child: Center(child: _CreateButton(onTap: onCreate))),
              _NavItem(
                icon: Icons.notifications_none,
                label: 'Inbox',
                badge: inboxBadge,
                onTap: onInbox,
              ),
              _NavItem(icon: Icons.person_outline, label: 'Profile', onTap: onProfile),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: Colors.white70),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 14),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF25F4EE), Color(0xFFFE2C55), Color(0xFFE50914)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.add, size: 20, color: Colors.black),
        ),
      ),
    );
  }
}
