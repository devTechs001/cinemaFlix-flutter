import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cinemaflix/widgets/interactive_card.dart';
import 'package:cinemaflix/services/gifting_service.dart';
import 'package:cinemaflix/services/wallet_service.dart';

class GiftingScreen extends StatefulWidget {
  const GiftingScreen({super.key});

  @override
  State<GiftingScreen> createState() => _GiftingScreenState();
}

class _GiftingScreenState extends State<GiftingScreen> with SingleTickerProviderStateMixin {
  final _giftingService = GiftingService();
  final _emailController = TextEditingController();
  int _selectedGift = 0;
  String _selectedCategory = 'All';
  String _selectedCurrency = 'USD';
  bool _useDiamonds = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<GiftItem> get _filteredGifts {
    final all = _giftingService.availableGifts;
    if (_selectedCategory == 'All') return all;
    return all.where((g) => g.category == _selectedCategory).toList();
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
            title: const Text('Gifting', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/wallet'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE50914).withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 4),
                        Text('${walletService.diamonds}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFE50914),
              indicatorWeight: 3,
              labelColor: const Color(0xFFE50914),
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(icon: Icon(Icons.card_giftcard_outlined), text: 'Gifts'),
                Tab(icon: Icon(Icons.star_outline), text: 'Points'),
                Tab(icon: Icon(Icons.history), text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildGiftTab(),
              _buildPointsTab(),
              _buildHistoryTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', ..._giftingService.categories];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final selected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategory = cat;
                  _selectedGift = 0;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(cat, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrencyRow() {
    const currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'INR', 'BRL', 'NGN'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(8)),
            child: DropdownButton<String>(
              value: _selectedCurrency,
              dropdownColor: const Color(0xFF1F1F1F),
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              icon: const Icon(Icons.expand_more, color: Colors.white38, size: 18),
              items: currencies.map((c) => DropdownMenuItem(value: c, child: Text('${_giftingService.currencySymbol(c)}$c'))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCurrency = v);
              },
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Text('Pay with: ', style: TextStyle(color: Colors.white38, fontSize: 12)),
              InkWell(
                onTap: () => setState(() => _useDiamonds = true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _useDiamonds ? const Color(0xFFFFD700).withAlpha(25) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _useDiamonds ? const Color(0xFFFFD700).withAlpha(80) : Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      Text('Diamonds', style: TextStyle(color: _useDiamonds ? const Color(0xFFFFD700) : Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _useDiamonds = false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: !_useDiamonds ? const Color(0xFF10B981).withAlpha(25) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: !_useDiamonds ? const Color(0xFF10B981).withAlpha(80) : Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_money, color: !_useDiamonds ? const Color(0xFF10B981) : Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text('Cash', style: TextStyle(color: !_useDiamonds ? const Color(0xFF10B981) : Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGiftTab() {
    final gifts = _filteredGifts;
    return Column(
      children: [
        _buildCategoryChips(),
        _buildCurrencyRow(),
        const SizedBox(height: 4),
        Expanded(
          child: gifts.isEmpty
              ? Center(child: Text('No gifts in this category', style: TextStyle(color: Colors.white.withAlpha(80))))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: gifts.length + 3,
                  itemBuilder: (context, i) {
                    if (i == 0) return _buildHeader(gifts.length);
                    if (i == gifts.length + 1) return _buildSendSection();
                    if (i == gifts.length + 2) return const SizedBox(height: 40);
                    final gift = gifts[i - 1];
                    final idx = _giftingService.availableGifts.indexOf(gift);
                    return _buildGiftCard(gift, idx);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFE50914).withAlpha(40), const Color(0xFF7B1FA2).withAlpha(40)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Color(0xFFE50914), size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Send a Gift', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('$count gifts available in $_selectedCategory', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftCard(GiftItem gift, int index) {
    final selected = _selectedGift == index;
    final price = _giftingService.priceInCurrency(gift.priceUSD, _selectedCurrency);
    final symbol = _giftingService.currencySymbol(_selectedCurrency);
    final canAffordDiamond = walletService.diamonds >= gift.diamondCost;
    final canAffordPoints = walletService.points >= gift.pointCost;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InteractiveCard(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedGift = index);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE50914).withAlpha(20) : const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? const Color(0xFFE50914) : Colors.white10, width: selected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(gift.icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(gift.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                            if (gift.isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(10)),
                                child: const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(gift.description, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_useDiamonds)
                    Row(
                      children: [
                        Text('💎 ${gift.diamondCost}', style: TextStyle(color: canAffordDiamond ? const Color(0xFFFFD700) : const Color(0xFFE50914), fontSize: 16, fontWeight: FontWeight.bold)),
                        if (gift.pointCost > 0) ...[
                          const SizedBox(width: 12),
                          Text('or ${gift.pointCost} pts', style: TextStyle(color: canAffordPoints ? const Color(0xFF10B981) : Colors.white38, fontSize: 12)),
                        ],
                      ],
                    )
                  else
                    Text('$symbol${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)} $_selectedCurrency', style: const TextStyle(color: const Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold)),
                  if (!_useDiamonds)
                    Text('💎 ${gift.diamondCost}', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Send To', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Friend\'s email address',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        const Text('Or choose from contacts', style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _sendGift,
            icon: const Icon(Icons.send, color: Colors.white),
            label: const Text('Send Gift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  void _sendGift() {
    if (_emailController.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final gift = _giftingService.availableGifts[_selectedGift];

    if (_useDiamonds) {
      if (walletService.diamonds < gift.diamondCost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Not enough diamonds! Tap the diamond icon to buy more.'), backgroundColor: const Color(0xFFE50914), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      walletService.sendGift(gift.diamondCost, gift.name, _emailController.text.trim());
    }

    _giftingService.sendGift(_emailController.text.trim(), gift, currency: _selectedCurrency, useDiamonds: _useDiamonds);
    walletService.addPoints(10, 'Sent gift: ${gift.name}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎁 ${gift.name} sent to ${_emailController.text.trim()}!'),
        backgroundColor: const Color(0xFF43A047),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _emailController.clear();
  }

  Widget _buildPointsTab() {
    final pointsGifts = _giftingService.pointsGifts();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF10B981).withAlpha(40), const Color(0xFF059669).withAlpha(40)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${walletService.points} Points', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Earn points by engaging on the app', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Redeem with Points', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ...pointsGifts.map((gift) {
          final canAfford = walletService.points >= gift.pointCost;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InteractiveCard(
              onTap: canAfford
                  ? () {
                      HapticFeedback.lightImpact();
                      _redeemWithPoints(gift);
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: canAfford ? const Color(0xFF10B981).withAlpha(50) : Colors.white10),
                ),
                child: Row(
                  children: [
                    Text(gift.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(gift.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(gift.description, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${gift.pointCost} pts', style: TextStyle(color: canAfford ? const Color(0xFFFFD700) : const Color(0xFFE50914), fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(canAfford ? 'Available' : 'Need ${gift.pointCost - walletService.points} more', style: TextStyle(color: canAfford ? const Color(0xFF10B981) : Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  void _redeemWithPoints(GiftItem gift) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Redeem with Points', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(gift.icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(gift.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${gift.pointCost} points', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Balance: ${walletService.points} pts', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _giftingService.sendGift(_emailController.text.trim().isEmpty ? 'self@cinemaflix.app' : _emailController.text.trim(), gift, currency: 'PTS', usePoints: true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Redeemed ${gift.name} for ${gift.pointCost} points!'), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Redeem', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final history = _giftingService.giftHistory;
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_outlined, color: Colors.white.withAlpha(40), size: 80),
            const SizedBox(height: 16),
            Text('No gift history yet', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, i) {
        final h = history[i];
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
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: h.delivered ? const Color(0xFF43A047).withAlpha(30) : const Color(0xFFFF8F00).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  h.delivered ? Icons.check_circle : Icons.schedule,
                  color: h.delivered ? const Color(0xFF43A047) : const Color(0xFFFF8F00),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.itemName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('To: ${h.recipient}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (h.diamondsSpent > 0)
                    Text('💎 ${h.diamondsSpent}', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14))
                  else if (h.pointsSpent > 0)
                    Text('${h.pointsSpent} pts', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14))
                  else
                    Text('${h.currency} ${h.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(h.delivered ? 'Delivered' : 'Pending', style: TextStyle(color: h.delivered ? const Color(0xFF43A047) : const Color(0xFFFF8F00), fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
