import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cinemaflix/services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: walletService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF141414),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1F1F1F),
            title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFE50914),
              indicatorWeight: 3,
              labelColor: const Color(0xFFE50914),
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'Balance'),
                Tab(icon: Icon(Icons.diamond_outlined), text: 'Shop'),
                Tab(icon: Icon(Icons.receipt_long_outlined), text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildBalanceTab(),
              _buildShopTab(),
              _buildHistoryTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE50914), Color(0xFFB20710)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFFE50914).withAlpha(60), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                const Icon(Icons.diamond, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text('${walletService.diamonds}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Diamonds', style: TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(1),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Buy Diamonds'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE50914),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Points', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${walletService.points} pts', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                    if (walletService.points >= 100)
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          walletService.convertPointsToDiamonds();
                        },
                        icon: const Icon(Icons.swap_horiz, color: Color(0xFFE50914)),
                        label: const Text('Convert to Diamonds', style: TextStyle(color: Color(0xFFE50914))),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('100 points = 1 diamond', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: Colors.amber.withAlpha(180)),
                    const SizedBox(width: 8),
                    const Text('Earning Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),
                _earnRow(Icons.favorite_outline, 'Like a post', '+1 pt'),
                _earnRow(Icons.chat_bubble_outline, 'Comment on content', '+2 pts'),
                _earnRow(Icons.video_library_outlined, 'Watch a short', '+1 pt'),
                _earnRow(Icons.person_add_outlined, 'Refer a friend', '+50 pts'),
                _earnRow(Icons.star_outline, 'Daily login', '+5 pts'),
                _earnRow(Icons.card_giftcard_outlined, 'Send a gift', '+10 pts'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _earnRow(IconData icon, String label, String reward) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14))),
          Text(reward, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildShopTab() {
    final packages = [
      {'name': 'Starter Pack', 'diamonds': 100, 'price': '\$0.99', 'popular': false, 'color': const Color(0xFF6366F1)},
      {'name': 'Standard Pack', 'diamonds': 500, 'price': '\$4.99', 'popular': true, 'color': const Color(0xFFE50914)},
      {'name': 'Premium Pack', 'diamonds': 1200, 'price': '\$9.99', 'popular': false, 'color': const Color(0xFFF59E0B)},
      {'name': 'Ultra Pack', 'diamonds': 3000, 'price': '\$19.99', 'popular': false, 'color': const Color(0xFF10B981)},
      {'name': 'Mega Pack', 'diamonds': 8000, 'price': '\$49.99', 'popular': false, 'color': const Color(0xFF8B5CF6)},
      {'name': 'Legendary Pack', 'diamonds': 20000, 'price': '\$99.99', 'popular': false, 'color': const Color(0xFFF43F5E)},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, i) {
        final p = packages[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(16),
            border: (p['popular'] as bool) ? Border.all(color: const Color(0xFFE50914), width: 1.5) : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.selectionClick();
              _purchasePackage(p['name'] as String, p['diamonds'] as int, p['price'] as String);
            },
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (p['color'] as Color).withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.diamond, color: p['color'] as Color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16)),
                          if (p['popular'] as bool) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Best', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${p['diamonds']} diamonds', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: (p['popular'] as bool) ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(p['price'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _purchasePackage(String name, int diamonds, String price) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Purchase', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 64),
            const SizedBox(height: 16),
            Text('$name - $diamonds diamonds', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total: $price', style: const TextStyle(color: Color(0xFFE50914), fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await walletService.purchaseDiamonds(diamonds);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Purchased $diamonds diamonds!'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            child: const Text('Purchase', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final txns = walletService.transactions;
    if (txns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, color: Colors.white.withAlpha(40), size: 80),
            const SizedBox(height: 16),
            Text('No transactions yet', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: txns.length,
      itemBuilder: (context, i) {
        final tx = txns[i];
        final isCredit = tx.amount > 0;
        final IconData icon;
        switch (tx.type) {
          case 'purchase':
            icon = Icons.add_circle_outline;
            break;
          case 'spend':
            icon = Icons.card_giftcard_outlined;
            break;
          case 'earn':
            icon = Icons.star_outline;
            break;
          case 'convert':
            icon = Icons.swap_horiz;
            break;
          case 'bonus':
            icon = Icons.celebration_outlined;
            break;
          default:
            icon = Icons.receipt_long_outlined;
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCredit ? const Color(0xFF10B981).withAlpha(25) : const Color(0xFFE50914).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isCredit ? const Color(0xFF10B981) : const Color(0xFFE50914), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.description, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('${tx.date.month}/${tx.date.day}/${tx.date.year}', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 12)),
                  ],
                ),
              ),
              Text(
                isCredit ? '+${tx.amount}' : '${tx.amount}',
                style: TextStyle(
                  color: isCredit ? const Color(0xFF10B981) : const Color(0xFFE50914),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
