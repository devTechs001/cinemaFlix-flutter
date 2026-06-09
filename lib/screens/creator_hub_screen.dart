import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cinemaflix/services/creator_service.dart';
import 'package:cinemaflix/widgets/interactive_card.dart';

class CreatorHubScreen extends StatefulWidget {
  const CreatorHubScreen({super.key});

  @override
  State<CreatorHubScreen> createState() => _CreatorHubScreenState();
}

class _CreatorHubScreenState extends State<CreatorHubScreen> {
  @override
  Widget build(BuildContext context) {
    if (!creatorService.isCreator) return _buildOnboarding();

    return ListenableBuilder(
      listenable: creatorService,
      builder: (context, _) {
        final s = creatorService.stats;
        return Scaffold(
          backgroundColor: const Color(0xFF141414),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1F1F1F),
            title: const Text('Creator Hub', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                onPressed: () => Navigator.pushNamed(context, '/creator-analytics'),
                tooltip: 'Analytics',
              ),
              IconButton(
                icon: const Icon(Icons.attach_money_outlined),
                onPressed: () => Navigator.pushNamed(context, '/creator-earnings'),
                tooltip: 'Earnings',
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(s),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildRecentComments(),
                const SizedBox(height: 20),
                _buildContentList(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOnboarding() {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Creator Hub', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE50914), Color(0xFF7B1FA2)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFFE50914).withAlpha(60), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: const Icon(Icons.videocam, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 32),
              const Text('Become a Creator', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Text(
                'Upload movie reviews, analysis, shorts, and build your audience. Earn diamonds and real money from your content.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 8),
              Text('2,891 creators • 45K+ daily views', style: TextStyle(color: const Color(0xFFE50914), fontSize: 13)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    creatorService.enableCreatorMode();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Enable Creator Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Not now', style: TextStyle(color: Colors.white.withAlpha(80))),
              ),
              const SizedBox(height: 32),
              _benefitItem(Icons.visibility, 'Get discovered', 'Reach thousands of movie fans'),
              _benefitItem(Icons.attach_money, 'Earn revenue', 'Diamonds & real money from views'),
              _benefitItem(Icons.analytics, 'Track performance', 'Detailed analytics dashboard'),
              _benefitItem(Icons.group, 'Build community', 'Engage with your audience'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefitItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFFE50914), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                Text(desc, style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(CreatorStats s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE50914), Color(0xFFB20710)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFFE50914).withAlpha(60), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem('${s.totalViews}', 'Total Views', Icons.visibility),
              _statItem('${s.totalSubscribers}', 'Subscribers', Icons.group),
              _statItem('${s.totalVideos}', 'Videos', Icons.videocam),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem('+${s.viewsToday}', 'Today', Icons.trending_up),
              _statItem('+${s.subscribersToday}', 'New Subs', Icons.person_add),
              _statItem('\$${s.totalEarnings}', 'Earnings', Icons.attach_money),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.add_circle, 'label': 'Upload', 'color': const Color(0xFFE50914), 'route': '/creator-upload'},
      {'icon': Icons.video_library, 'label': 'Content', 'color': const Color(0xFF7B1FA2), 'route': '/creator-content'},
      {'icon': Icons.analytics, 'label': 'Analytics', 'color': const Color(0xFFFFB300), 'route': '/creator-analytics'},
      {'icon': Icons.attach_money, 'label': 'Earnings', 'color': const Color(0xFF10B981), 'route': '/creator-earnings'},
      {'icon': Icons.person, 'label': 'Channel', 'color': const Color(0xFF6366F1), 'route': null},
      {'icon': Icons.settings, 'label': 'Settings', 'color': Colors.white54, 'route': null},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: actions.map((a) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InteractiveCard(
                onTap: a['route'] != null ? () => Navigator.pushNamed(context, a['route'] as String) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      Icon(a['icon'] as IconData, color: a['color'] as Color, size: 28),
                      const SizedBox(height: 6),
                      Text(a['label'] as String, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentComments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ...creatorService.recentComments.map((c) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c['avatar'] as String, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(c['user'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        Text(c['time'] as String, style: const TextStyle(color: Colors.white24, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(c['text'] as String, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.3)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.favorite_border, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text('${c['likes']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(width: 16),
                        Icon(Icons.reply, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text('Reply', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildContentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Your Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            InteractiveCard(
              onTap: () => Navigator.pushNamed(context, '/creator-content'),
              child: Text('See all', style: TextStyle(color: const Color(0xFFE50914), fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...creatorService.videos.take(3).map((v) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE50914), Color(0xFF7B1FA2)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(v.thumbnail, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${v.views} views', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text('${v.likes} likes', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Text(v.duration, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        )),
      ],
    );
  }
}
