import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';
import '../services/gifting_service.dart';

class GiftingScreen extends StatefulWidget {
  const GiftingScreen({super.key});

  @override
  State<GiftingScreen> createState() => _GiftingScreenState();
}

class _GiftingScreenState extends State<GiftingScreen> {
  final _giftingService = GiftingService();
  final _emailController = TextEditingController();
  int _selectedGift = 0;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gifting', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFE50914).withAlpha(40), const Color(0xFF7B1FA2).withAlpha(40)],
                ),
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
                        Text('Give the gift of cinema to your friends', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Choose a Gift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            ...List.generate(_giftingService.availableGifts.length, (i) {
              final gift = _giftingService.availableGifts[i];
              final selected = _selectedGift == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InteractiveCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedGift = i);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFE50914).withAlpha(20) : const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? const Color(0xFFE50914) : Colors.white10,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
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
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE50914),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
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
                        Text('\$${gift.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
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
                onPressed: () {
                  if (_emailController.text.trim().isEmpty) return;
                  HapticFeedback.mediumImpact();
                  final gift = _giftingService.availableGifts[_selectedGift];
                  _giftingService.sendGift(_emailController.text.trim(), gift);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎁 ${gift.name} sent to ${_emailController.text.trim()}!'),
                      backgroundColor: const Color(0xFF43A047),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  _emailController.clear();
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('Send Gift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text('Gift History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            ..._giftingService.giftHistory.map((h) => Container(
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
                      Text('\$${h.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(h.delivered ? 'Delivered' : 'Pending', style: TextStyle(color: h.delivered ? const Color(0xFF43A047) : const Color(0xFFFF8F00), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
