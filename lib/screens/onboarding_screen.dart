import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      icon: Icons.movie_creation_rounded,
      title: 'Welcome to CinemaFlix',
      description: 'Your ultimate movie companion. Discover, track, discuss, and rate your favorite films all in one place.',
      color: const Color(0xFFE50914),
      detail: 'Installation Complete',
      features: ['8K Streaming Ready', 'Offline Downloads', 'Smart Recommendations'],
    ),
    OnboardingStep(
      icon: Icons.explore_outlined,
      title: 'Discover Movies',
      description: 'Browse trending movies, explore genres, and find your next favorite film with personalized picks.',
      color: const Color(0xFF1E88E5),
      detail: 'Smart Discovery',
      features: ['Genre Explorer', 'Trending Now', 'Personalized Picks', 'Advanced Filters'],
    ),
    OnboardingStep(
      icon: Icons.chat_bubble_outline,
      title: 'Join the Community',
      description: 'Chat with fellow movie lovers, share reviews, and discuss your favorite scenes in real-time.',
      color: const Color(0xFF7B1FA2),
      detail: 'Social Features',
      features: ['Real-time Chat', 'Movie Discussions', 'Friend Connections', 'Share Reviews'],
    ),
    OnboardingStep(
      icon: Icons.palette_outlined,
      title: 'Set Up Your Experience',
      description: 'Customize themes, connect with friends, and set your preferences for the ultimate movie experience.',
      color: const Color(0xFFFF8F00),
      detail: 'Almost Done!',
      features: ['Custom Themes', 'Contact Sync', 'Push Notifications', 'HD Streaming'],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage < _steps.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: InteractiveCard(
                    onTap: () => Navigator.pushReplacementNamed(context, '/main'),
                    scaleAmount: 0.92,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Skip', style: TextStyle(color: Colors.white38, fontSize: 15)),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 52),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: step.color.withAlpha(25),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(step.icon, size: 48, color: step.color),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: step.color.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(step.detail, style: TextStyle(color: step.color, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.title,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.description,
                          style: const TextStyle(fontSize: 15, color: Colors.white54, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: step.features.map((f) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, color: step.color, size: 14),
                                  const SizedBox(width: 6),
                                  Text(f, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? const Color(0xFFE50914) : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    if (_currentPage < _steps.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.pushReplacementNamed(context, '/main');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage < _steps.length - 1 ? 'Next' : 'Start Watching',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class OnboardingStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String detail;
  final List<String> features;

  const OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.detail,
    required this.features,
  });
}
