import 'package:flutter/foundation.dart';

class GiftItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String icon;
  final bool isPopular;

  const GiftItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    this.isPopular = false,
  });
}

class GiftHistory {
  final String id;
  final String recipient;
  final String itemName;
  final double price;
  final DateTime date;
  final bool delivered;

  const GiftHistory({
    required this.id,
    required this.recipient,
    required this.itemName,
    required this.price,
    required this.date,
    required this.delivered,
  });
}

class GiftingService extends ChangeNotifier {
  final List<GiftItem> _availableGifts = [
    const GiftItem(id: 'g1', name: '1 Month Premium', description: 'Full access for 30 days', price: 9.99, icon: '⭐', isPopular: true),
    const GiftItem(id: 'g2', name: '3 Months Premium', description: 'Best value - save 20%', price: 24.99, icon: '🌟', isPopular: true),
    const GiftItem(id: 'g3', name: '12 Months Premium', description: 'Full year of unlimited access', price: 79.99, icon: '👑'),
    const GiftItem(id: 'g4', name: 'Movie Rental Pass', description: 'Rent 5 movies for friends', price: 14.99, icon: '🎬'),
    const GiftItem(id: 'g5', name: 'HD Streaming Pass', description: 'Unlock 4K streaming for 30 days', price: 5.99, icon: '📺'),
    const GiftItem(id: 'g6', name: 'Ad-Free Experience', description: 'Remove all ads for 3 months', price: 3.99, icon: '🚫'),
  ];

  final List<GiftHistory> _giftHistory = [
    GiftHistory(id: 'h1', recipient: 'sarah@email.com', itemName: '1 Month Premium', price: 9.99, date: DateTime(2026, 6, 1), delivered: true),
    GiftHistory(id: 'h2', recipient: 'mike@email.com', itemName: 'Movie Rental Pass', price: 14.99, date: DateTime(2026, 5, 28), delivered: true),
    GiftHistory(id: 'h3', recipient: 'emma@email.com', itemName: '3 Months Premium', price: 24.99, date: DateTime(2026, 5, 20), delivered: false),
  ];

  List<GiftItem> get availableGifts => _availableGifts;
  List<GiftHistory> get giftHistory => _giftHistory;

  Future<bool> sendGift(String recipientEmail, GiftItem gift) async {
    await Future.delayed(const Duration(seconds: 1));
    _giftHistory.insert(0, GiftHistory(
      id: 'h${DateTime.now().millisecondsSinceEpoch}',
      recipient: recipientEmail,
      itemName: gift.name,
      price: gift.price,
      date: DateTime.now(),
      delivered: true,
    ));
    notifyListeners();
    return true;
  }
}
