import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  int _activeIndex = 0;

  int get activeIndex => _activeIndex;
  ThemeData get activeTheme => themes[_activeIndex];

  void setTheme(int index) {
    _activeIndex = index;
    notifyListeners();
  }

  static final List<ThemeData> themes = [
    _buildTheme(0xFFE50914, 0xFF141414, 0xFF1F1F1F, 'Netflix Dark'),
    _buildTheme(0xFF1E88E5, 0xFF0D1117, 0xFF161B22, 'Midnight Blue'),
    _buildTheme(0xFF2E7D32, 0xFF0B1E0B, 0xFF122A12, 'Forest Green'),
    _buildTheme(0xFF7B1FA2, 0xFF1A0D2E, 0xFF241440, 'Royal Purple'),
    _buildTheme(0xFFFF8F00, 0xFF1C1400, 0xFF2A1F00, 'Amber Glow'),
    _buildTheme(0xFFD32F2F, 0xFF1A0A0A, 0xFF2A1010, 'Crimson Red'),
    _buildTheme(0xFF00897B, 0xFF001412, 0xFF00221E, 'Teal Dream'),
    _buildTheme(0xFF5C6BC0, 0xFF0D0D1A, 0xFF15152A, 'Indigo Night'),
    _buildTheme(0xFFFF6F00, 0xFF1A0F00, 0xFF2A1800, 'Orange Burst'),
    _buildTheme(0xFFC62828, 0xFF0A0A0A, 0xFF1A0A0A, 'Dark Ruby'),
    _buildTheme(0xFF00695C, 0xFF002F2A, 0xFF004D44, 'Emerald City'),
    _buildTheme(0xFF4E342E, 0xFF1A120E, 0xFF2A1E18, 'Brown Classic'),
  ];

  static ThemeData _buildTheme(int primary, int scaffold, int surface, String name) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(primary),
      scaffoldBackgroundColor: Color(scaffold),
      colorScheme: ColorScheme.dark(
        primary: Color(primary),
        secondary: Color(primary),
        surface: Color(surface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(scaffold),
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(scaffold),
        selectedItemColor: Color(primary),
        unselectedItemColor: const Color(0xFF808080),
        type: BottomNavigationBarType.fixed,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: Color(scaffold),
      ),
    );
  }
}

final themeService = ThemeService();
