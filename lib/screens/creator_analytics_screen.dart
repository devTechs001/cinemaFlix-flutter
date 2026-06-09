import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cinemaflix/services/creator_service.dart';

class CreatorAnalyticsScreen extends StatefulWidget {
  const CreatorAnalyticsScreen({super.key});

  @override
  State<CreatorAnalyticsScreen> createState() => _CreatorAnalyticsScreenState();
}

class _CreatorAnalyticsScreenState extends State<CreatorAnalyticsScreen> {
  String _range = 'Last 7 days';

  @override
  Widget build(BuildContext context) {
    final s = creatorService.stats;
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            color: const Color(0xFF1F1F1F),
            onSelected: (v) => setState(() => _range = v),
            itemBuilder: (_) => ['Last 7 days', 'Last 30 days', 'Last 90 days', 'All time'].map((r) => PopupMenuItem(
              value: r,
              child: Text(r, style: TextStyle(color: _range == r ? const Color(0xFFE50914) : Colors.white)),
            )).toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_range, style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 13)),
            const SizedBox(height: 16),
            _buildOverviewCards(s),
            const SizedBox(height: 20),
            _buildViewsChart(),
            const SizedBox(height: 20),
            _buildEngagementRow(s),
            const SizedBox(height: 20),
            _buildTopContent(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(CreatorStats s) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard(Icons.visibility, 'Views', '${s.totalViews}', '+${s.viewsToday}', const Color(0xFFE50914))),
            const SizedBox(width: 10),
            Expanded(child: _metricCard(Icons.group, 'Subscribers', '${s.totalSubscribers}', '+${s.subscribersToday}', const Color(0xFF6366F1))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _metricCard(Icons.timer, 'Watch Time', '${s.watchTimeHours}h', '+128h', const Color(0xFF10B981))),
            const SizedBox(width: 10),
            Expanded(child: _metricCard(Icons.attach_money, 'Revenue', '\$${s.totalEarnings}', '+\$340', const Color(0xFFFFB300))),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(IconData icon, String label, String value, String change, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                child: Text(change, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildViewsChart() {
    final data = creatorService.dailyViews;
    final maxViews = data.map((d) => d['views'] as int).reduce((a, b) => a > b ? a : b).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Views', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final fraction = (d['views'] as int) / maxViews;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${d['views']}', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                        const SizedBox(height: 4),
                        Container(
                          height: 120 * fraction,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [const Color(0xFFE50914), const Color(0xFFE50914).withAlpha(100)]),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(d['day'] as String, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
              child: const Text('+12.4% vs last week', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementRow(CreatorStats s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _engagementItem(Icons.favorite, '${s.totalSubscribers ~/ 3}', 'Likes'),
          _engagementItem(Icons.chat_bubble, '${s.totalSubscribers ~/ 8}', 'Comments'),
          _engagementItem(Icons.share, '${s.totalSubscribers ~/ 5}', 'Shares'),
          _engagementItem(Icons.bookmark, '${s.totalSubscribers ~/ 4}', 'Saves'),
        ],
      ),
    );
  }

  Widget _engagementItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFE50914), size: 22),
        const SizedBox(height: 4),
        Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _buildTopContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Performing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ...creatorService.videos.take(4).map((v) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE50914), Color(0xFF7B1FA2)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(v.thumbnail, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${v.views} views', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: v.views > 10000 ? const Color(0xFF10B981).withAlpha(25) : const Color(0xFFFFB300).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${((v.likes / v.views) * 100).toStringAsFixed(1)}%', style: TextStyle(color: v.views > 10000 ? const Color(0xFF10B981) : const Color(0xFFFFB300), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
