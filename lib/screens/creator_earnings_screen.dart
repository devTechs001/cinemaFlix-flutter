import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cinemaflix/services/creator_service.dart';

class CreatorEarningsScreen extends StatefulWidget {
  const CreatorEarningsScreen({super.key});

  @override
  State<CreatorEarningsScreen> createState() => _CreatorEarningsScreenState();
}

class _CreatorEarningsScreenState extends State<CreatorEarningsScreen> {
  @override
  Widget build(BuildContext context) {
    final s = creatorService.stats;
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEarningsHeader(s),
            const SizedBox(height: 20),
            _buildRevenueSources(),
            const SizedBox(height: 20),
            _buildPayoutInfo(),
            const SizedBox(height: 20),
            _buildTransactionHistory(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsHeader(CreatorStats s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withAlpha(60), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text('\$${s.totalEarnings}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('+\$340 this period', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payout requested! Processing...'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSources() {
    final sources = [
      {'name': 'Ad Revenue', 'amount': '\$8,450', 'percent': '68%', 'icon': Icons.play_circle, 'color': const Color(0xFFE50914)},
      {'name': 'Gifting', 'amount': '\$2,340', 'percent': '19%', 'icon': Icons.card_giftcard, 'color': const Color(0xFFFFB300)},
      {'name': 'Subscriptions', 'amount': '\$1,120', 'percent': '9%', 'icon': Icons.star, 'color': const Color(0xFF6366F1)},
      {'name': 'Diamond Sales', 'amount': '\$540', 'percent': '4%', 'icon': Icons.diamond, 'color': const Color(0xFFFFD700)},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Sources', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          ...sources.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: (s['color'] as Color).withAlpha(25), borderRadius: BorderRadius.circular(10)),
                  child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: double.parse((s['percent'] as String).replaceAll('%', '')) / 100,
                          backgroundColor: Colors.white.withAlpha(10),
                          valueColor: AlwaysStoppedAnimation<Color>(s['color'] as Color),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s['amount'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(s['percent'] as String, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPayoutInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payout Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _payoutRow('Payment Method', 'PayPal - sarah@email.com'),
          const Divider(color: Color(0xFF2A2A2A), height: 20),
          _payoutRow('Minimum Payout', '\$50.00'),
          const Divider(color: Color(0xFF2A2A2A), height: 20),
          _payoutRow('Next Payout', 'Available in 3 days'),
          const Divider(color: Color(0xFF2A2A2A), height: 20),
          _payoutRow('Payout Schedule', 'Monthly (1st)'),
        ],
      ),
    );
  }

  Widget _payoutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTransactionHistory() {
    final transactions = [
      {'desc': 'Ad Revenue - June Week 1', 'amount': '+\$240', 'date': 'Jun 7', 'type': 'credit'},
      {'desc': 'Gift from Emma W.', 'amount': '+\$5', 'date': 'Jun 6', 'type': 'gift'},
      {'desc': 'Payout - May', 'amount': '-\$1,240', 'date': 'Jun 1', 'type': 'debit'},
      {'desc': 'Ad Revenue - May Week 4', 'amount': '+\$320', 'date': 'May 31', 'type': 'credit'},
      {'desc': 'Subscription from Mike R.', 'amount': '+\$10', 'date': 'May 28', 'type': 'credit'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ...transactions.map((t) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: t['type'] == 'debit' ? const Color(0xFFE50914).withAlpha(25) : (t['type'] == 'gift' ? const Color(0xFFFFB300).withAlpha(25) : const Color(0xFF10B981).withAlpha(25)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  t['type'] == 'debit' ? Icons.arrow_upward : Icons.arrow_downward,
                  color: t['type'] == 'debit' ? const Color(0xFFE50914) : const Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['desc'] as String, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    Text(t['date'] as String, style: const TextStyle(color: Colors.white24, fontSize: 11)),
                  ],
                ),
              ),
              Text(t['amount'] as String, style: TextStyle(
                color: (t['amount'] as String).startsWith('+') ? const Color(0xFF10B981) : const Color(0xFFE50914),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              )),
            ],
          ),
        )),
      ],
    );
  }
}
