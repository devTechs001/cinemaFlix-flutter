import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Walks ancestor [Scaffold]s until one that actually has a drawer.
///
/// Home / Feed / Profile / Shorts each own a nested [Scaffold] without a
/// drawer; the drawer lives on [MainShell] / [PersistentNav]. Calling
/// `Scaffold.of(context).openDrawer()` from those screens is a no-op.
void openParentDrawer(BuildContext context) {
  HapticFeedback.lightImpact();
  var ctx = context;
  for (var i = 0; i < 8; i++) {
    final state = ctx.findAncestorStateOfType<ScaffoldState>();
    if (state == null) return;
    if (state.hasDrawer) {
      state.openDrawer();
      return;
    }
    ctx = state.context;
  }
}

/// Restyled top bar: tappable hamburger that opens the parent drawer,
/// CinemaFlix wordmark, and a hairline under the bar.
class CinemaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showMenu;
  final bool brandTitle;
  final List<Widget>? actions;
  final Widget? leading;

  const CinemaAppBar({
    super.key,
    this.title = 'CinemaFlix',
    this.showMenu = true,
    this.brandTitle = false,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0F0F0F),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      leadingWidth: (showMenu || leading != null) ? 56 : 0,
      leading: leading ??
          (showMenu
              ? IconButton(
                  tooltip: 'Menu',
                  onPressed: () => openParentDrawer(context),
                  icon: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(Icons.menu, color: Colors.white, size: 20),
                  ),
                )
              : null),
      titleSpacing: 4,
      title: brandTitle
          ? const Text(
              'CinemaFlix',
              style: TextStyle(
                color: Color(0xFFE50914),
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.4,
              ),
            )
          : Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
      actions: actions,
    );
  }
}

/// Compact square action used in [CinemaAppBar.actions].
class CinemaAppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool badge;

  const CinemaAppBarIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (badge)
            const Positioned(
              right: -1,
              top: -1,
              child: SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFE50914),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
