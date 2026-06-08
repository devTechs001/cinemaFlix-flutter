import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import '../widgets/interactive_card.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  final List<ThemeData> themes = ThemeService.themes;

  final List<Map<String, dynamic>> themeMeta = const [
    {'name': 'Netflix Dark', 'icon': Icons.movie, 'desc': 'Classic cinema red'},
    {'name': 'Midnight Blue', 'icon': Icons.water_drop, 'desc': 'Deep ocean calm'},
    {'name': 'Forest Green', 'icon': Icons.forest, 'desc': 'Natural vibes'},
    {'name': 'Royal Purple', 'icon': Icons.diamond, 'desc': 'Elegant & bold'},
    {'name': 'Amber Glow', 'icon': Icons.light_mode, 'desc': 'Warm sunset'},
    {'name': 'Crimson Red', 'icon': Icons.whatshot, 'desc': 'Intense & fiery'},
    {'name': 'Teal Dream', 'icon': Icons.palette, 'desc': 'Cool & modern'},
    {'name': 'Indigo Night', 'icon': Icons.nightlight, 'desc': 'Deep space'},
    {'name': 'Orange Burst', 'icon': Icons.flare, 'desc': 'Energetic vibe'},
    {'name': 'Dark Ruby', 'icon': Icons.dangerous, 'desc': 'Bold statement'},
    {'name': 'Emerald City', 'icon': Icons.brightness_low, 'desc': 'Rich & vibrant'},
    {'name': 'Brown Classic', 'icon': Icons.coffee, 'desc': 'Vintage feel'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose Your Theme', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('${themes.length} themes available • ${themeMeta[themeService.activeIndex]['name']} active', style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final meta = themeMeta[index];
                final theme = themes[index];
                final active = themeService.activeIndex == index;
                return InteractiveCard(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    themeService.setTheme(index);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: active ? theme.primaryColor : Colors.white10,
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (active)
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          meta['name'],
                          style: TextStyle(
                            color: active ? theme.primaryColor : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          meta['desc'],
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        if (active)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
