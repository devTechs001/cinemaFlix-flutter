import 'package:flutter/material.dart';

/// Design tokens — the single source of truth for brand/base colours.
///
/// Screens and widgets should use these instead of raw `Color(0x...)`
/// literals. They are `static const`, so they work inside const widgets.
/// (Per-theme accents still come from `Theme.of(context).colorScheme`
/// for chrome like the AppBar/bottom nav — see ThemeService.)
class AppColors {
  AppColors._();

  /// CinemaFlix brand red.
  static const brand = Color(0xFFE50914);

  /// App background (scaffold base).
  static const background = Color(0xFF141414);

  /// Raised surface: cards, sheets, dialogs.
  static const surface = Color(0xFF1F1F1F);

  /// Higher surface: chips, inputs, dividers-on-dark, card borders.
  static const surfaceVariant = Color(0xFF2A2A2A);

  /// Alternate deep surface (chat/input bars).
  static const surfaceAlt = Color(0xFF1A1A1A);

  /// Success / granted / positive actions.
  static const success = Color(0xFF43A047);
}

/// Spacing scale (logical pixels).
class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Corner radius scale.
class AppRadius {
  AppRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const pill = 24.0;
}
