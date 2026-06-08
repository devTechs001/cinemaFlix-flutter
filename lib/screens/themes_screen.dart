import 'package:flutter/material.dart';

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  final List<Map<String, dynamic>> themes = const [
    {'name': 'Netflix Dark', 'primary': Color(0xFFE50914), 'bg': Color(0xFF141414)},
    {'name': 'Midnight Blue', 'primary': Color(0xFF1E88E5), 'bg': Color(0xFF0D1117)},
    {'name': 'Forest', 'primary': Color(0xFF2E7D32), 'bg': Color(0xFF0B1E0B)},
    {'name': 'Royal Purple', 'primary': Color(0xFF7B1FA2), 'bg': Color(0xFF1A0D2E)},
    {'name': 'Amber Glow', 'primary': Color(0xFFFF8F00), 'bg': Color(0xFF1C1400)},
    {'name': 'Crimson', 'primary': Color(0xFFD32F2F), 'bg': Color(0xFF1A0A0A)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Theme',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Customize the look and feel of your app',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final theme = themes[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: theme['bg'],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: index == 0 ? const Color(0xFFE50914) : Colors.white12,
                        width: index == 0 ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme['primary'],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          theme['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (index == 0)
                          const Text(
                            'Active',
                            style: TextStyle(color: Color(0xFFE50914), fontSize: 12),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
