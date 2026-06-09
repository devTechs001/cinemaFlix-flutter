import 'package:flutter/foundation.dart';

class GiftItem {
  final String id;
  final String name;
  final String description;
  final double priceUSD;
  final String icon;
  final bool isPopular;
  final String category;
  final int diamondCost;
  final int pointCost;
  final List<String> currencies;

  const GiftItem({
    required this.id,
    required this.name,
    required this.description,
    required this.priceUSD,
    required this.icon,
    this.isPopular = false,
    required this.category,
    this.diamondCost = 0,
    this.pointCost = 0,
    this.currencies = const ['USD', 'EUR', 'GBP', 'CAD', 'AUD'],
  });
}

class GiftHistory {
  final String id;
  final String recipient;
  final String itemName;
  final double price;
  final String currency;
  final DateTime date;
  final bool delivered;
  final int diamondsSpent;
  final int pointsSpent;

  const GiftHistory({
    required this.id,
    required this.recipient,
    required this.itemName,
    required this.price,
    required this.date,
    required this.delivered,
    this.currency = 'USD',
    this.diamondsSpent = 0,
    this.pointsSpent = 0,
  });
}

class GiftingService extends ChangeNotifier {
  final List<GiftItem> _availableGifts = [
    const GiftItem(id: 'g1', name: '1 Month Premium', description: 'Full cinema access for 30 days', priceUSD: 9.99, icon: '⭐', isPopular: true, category: 'Premium Plans', diamondCost: 100, pointCost: 1000),
    const GiftItem(id: 'g2', name: '3 Months Premium', description: 'Best value - save 20% on 3 months', priceUSD: 24.99, icon: '🌟', isPopular: true, category: 'Premium Plans', diamondCost: 250, pointCost: 2500),
    const GiftItem(id: 'g3', name: '12 Months Premium', description: 'Full year unlimited access - save 40%', priceUSD: 79.99, icon: '👑', category: 'Premium Plans', diamondCost: 800, pointCost: 8000),
    const GiftItem(id: 'g4', name: 'Movie Rental Pass', description: 'Rent 5 movies for friends to watch', priceUSD: 14.99, icon: '🎬', category: 'Movie Passes', diamondCost: 150, pointCost: 1500),
    const GiftItem(id: 'g5', name: 'Family Movie Pack', description: 'Rent 10 movies for the whole family', priceUSD: 24.99, icon: '👨‍👩‍👧‍👦', category: 'Movie Passes', diamondCost: 250, pointCost: 2500),
    const GiftItem(id: 'g6', name: 'Premiere Access', description: 'Early access to new releases for 30 days', priceUSD: 12.99, icon: '🎟️', isPopular: true, category: 'Movie Passes', diamondCost: 130, pointCost: 1300),
    const GiftItem(id: 'g7', name: 'HD Streaming Pass', description: 'Unlock 4K UHD streaming for 30 days', priceUSD: 5.99, icon: '📺', category: 'Streaming', diamondCost: 60, pointCost: 600),
    const GiftItem(id: 'g8', name: 'Ad-Free Experience', description: 'Remove all ads for 3 months', priceUSD: 3.99, icon: '🚫', category: 'Streaming', diamondCost: 40, pointCost: 400),
    const GiftItem(id: 'g9', name: 'Offline Download Pass', description: 'Download 20 movies for offline viewing', priceUSD: 7.99, icon: '📥', category: 'Streaming', diamondCost: 80, pointCost: 800),
    const GiftItem(id: 'g10', name: 'Multi-Screen Access', description: 'Watch on 4 devices simultaneously', priceUSD: 9.99, icon: '🖥️', category: 'Streaming', diamondCost: 100, pointCost: 1000),
    const GiftItem(id: 'g11', name: 'Virtual Movie Ticket', description: 'Send a virtual ticket to a friend', priceUSD: 4.99, icon: '🎫', isPopular: true, category: 'Virtual Items', diamondCost: 50, pointCost: 500),
    const GiftItem(id: 'g12', name: 'Cinema Snack Pack', description: 'Popcorn + drink voucher for movie night', priceUSD: 8.99, icon: '🍿', category: 'Virtual Items', diamondCost: 90, pointCost: 900),
    const GiftItem(id: 'g13', name: 'Digital Movie Poster', description: 'Exclusive digital poster of any film', priceUSD: 3.99, icon: '🖼️', category: 'Virtual Items', diamondCost: 40, pointCost: 400),
    const GiftItem(id: 'g14', name: 'Custom Avatar Frame', description: 'Exclusive CinemaFlix avatar border', priceUSD: 2.99, icon: '🖌️', category: 'Virtual Items', diamondCost: 30, pointCost: 300),
    const GiftItem(id: 'g15', name: 'Super Chat Highlight', description: 'Pin your message in live streams for 1h', priceUSD: 5.99, icon: '💬', category: 'Social', diamondCost: 60, pointCost: 600),
    const GiftItem(id: 'g16', name: 'Fan Badge', description: 'Exclusive badge on your profile for 30 days', priceUSD: 2.99, icon: '🏅', category: 'Social', diamondCost: 30, pointCost: 300),
    const GiftItem(id: 'g17', name: 'Shoutout Boost', description: 'Get a shoutout on the live stream', priceUSD: 9.99, icon: '📢', category: 'Social', diamondCost: 100, pointCost: 1000),
    const GiftItem(id: 'g18', name: 'Reaction Pack', description: 'Unlock 20 exclusive emoji reactions', priceUSD: 1.99, icon: '😎', category: 'Social', diamondCost: 20, pointCost: 200),
    const GiftItem(id: 'g19', name: 'Profile Spotlight', description: 'Featured profile on the explore page for 24h', priceUSD: 14.99, icon: '🔦', category: 'Social', diamondCost: 150, pointCost: 1500),
    const GiftItem(id: 'g20', name: 'Diamond Booster Pack', description: 'Get 500 bonus diamonds instantly', priceUSD: 4.99, icon: '💎', isPopular: true, category: 'Diamonds', diamondCost: 0, pointCost: 500),
    const GiftItem(id: 'g21', name: 'Diamond Mega Pack', description: 'Get 2000 bonus diamonds instantly', priceUSD: 14.99, icon: '🔷', category: 'Diamonds', diamondCost: 0, pointCost: 1500),
    const GiftItem(id: 'g22', name: 'Diamond Ultra Pack', description: 'Get 5000 bonus diamonds instantly', priceUSD: 29.99, icon: '💠', category: 'Diamonds', diamondCost: 0, pointCost: 3000),
    const GiftItem(id: 'g23', name: 'Limited: Director\'s Cut', description: 'Exclusive director\'s commentary for 10 movies', priceUSD: 19.99, icon: '🎥', category: 'Limited Edition', diamondCost: 200, pointCost: 2000),
    const GiftItem(id: 'g24', name: 'Limited: Retro Night', description: 'Classic movie marathon pack (8 films)', priceUSD: 14.99, icon: '📽️', category: 'Limited Edition', diamondCost: 150, pointCost: 1500),
    const GiftItem(id: 'g25', name: 'Limited: Horror Bundle', description: '10 horror classics for Halloween season', priceUSD: 17.99, icon: '👻', category: 'Limited Edition', diamondCost: 180, pointCost: 1800),
    const GiftItem(id: 'g26', name: 'Limited: Sci-Fi Marathon', description: '12 sci-fi epics for binge weekend', priceUSD: 19.99, icon: '🛸', category: 'Limited Edition', diamondCost: 200, pointCost: 2000),
    const GiftItem(id: 'g27', name: 'Gift Card 10', description: 'Store credit for any purchase', priceUSD: 10.00, icon: '💳', category: 'Gift Cards', diamondCost: 100, pointCost: 1000),
    const GiftItem(id: 'g28', name: 'Gift Card 25', description: 'Store credit for any purchase', priceUSD: 25.00, icon: '💳', category: 'Gift Cards', isPopular: true, diamondCost: 250, pointCost: 2500),
    const GiftItem(id: 'g29', name: 'Gift Card 50', description: 'Store credit for any purchase', priceUSD: 50.00, icon: '💳', category: 'Gift Cards', diamondCost: 500, pointCost: 5000),
    const GiftItem(id: 'g30', name: 'Gift Card 100', description: 'Store credit - the ultimate gift', priceUSD: 100.00, icon: '💎', category: 'Gift Cards', diamondCost: 1000, pointCost: 10000),
    const GiftItem(id: 'g31', name: 'VIP Movie Date', description: '2 tickets + dinner voucher for a movie date', priceUSD: 39.99, icon: '💑', isPopular: true, category: 'Premium Plans', diamondCost: 400, pointCost: 4000),
    const GiftItem(id: 'g32', name: 'CinemaFlix Merch Box', description: 'Limited edition merch bundle (hat + tee + poster)', priceUSD: 49.99, icon: '🧢', category: 'Limited Edition', diamondCost: 500, pointCost: 5000),
    const GiftItem(id: 'g33', name: 'Personalized Video Message', description: 'Get a custom video message from your fave creator', priceUSD: 14.99, icon: '🎙️', category: 'Social', diamondCost: 150, pointCost: 1500),
    const GiftItem(id: 'g34', name: 'Yearbook Shoutout', description: 'Your name featured in the CinemaFlix yearbook', priceUSD: 7.99, icon: '📖', category: 'Social', diamondCost: 80, pointCost: 800),
    const GiftItem(id: 'g35', name: 'VIP Badge', description: 'Exclusive VIP badge for 90 days with gold trim', priceUSD: 5.99, icon: '🏆', category: 'Social', diamondCost: 60, pointCost: 600),
    const GiftItem(id: 'g36', name: 'Private Watch Party', description: 'Host a private screening for up to 10 friends', priceUSD: 19.99, icon: '🎉', isPopular: true, category: 'Movie Passes', diamondCost: 200, pointCost: 2000),
    const GiftItem(id: 'g37', name: 'Ad-Free Forever', description: 'Lifetime ad-free viewing experience', priceUSD: 49.99, icon: '🚫', category: 'Streaming', diamondCost: 500, pointCost: 5000),
    const GiftItem(id: 'g38', name: 'Diamond Royale Pack', description: 'Get 10000 diamonds in a single purchase', priceUSD: 49.99, icon: '👑', category: 'Diamonds', diamondCost: 0, pointCost: 10000),
    const GiftItem(id: 'g39', name: 'Creator Collab Pass', description: 'Get access to collab with creators on the platform', priceUSD: 24.99, icon: '🤝', category: 'Creator Tools', diamondCost: 250, pointCost: 2500),
    const GiftItem(id: 'g40', name: 'Analytics Pro', description: 'Unlock advanced analytics for your creator channel', priceUSD: 14.99, icon: '📊', category: 'Creator Tools', diamondCost: 150, pointCost: 1500),
    const GiftItem(id: 'g41', name: 'Priority Support', description: '24/7 priority customer support for 1 year', priceUSD: 29.99, icon: '🎧', category: 'Premium Plans', diamondCost: 300, pointCost: 3000),
    const GiftItem(id: 'g42', name: 'Soundtrack Bundle', description: 'Download 10 original movie soundtracks', priceUSD: 12.99, icon: '🎵', category: 'Virtual Items', diamondCost: 130, pointCost: 1300),
    const GiftItem(id: 'g43', name: 'Movie Quiz Pass', description: 'Unlock all premium movie trivia quizzes', priceUSD: 3.99, icon: '🧩', category: 'Virtual Items', diamondCost: 40, pointCost: 400),
    const GiftItem(id: 'g44', name: 'Early Access Pass', description: 'Watch new releases 48 hours before everyone', priceUSD: 9.99, icon: '⏱️', isPopular: true, category: 'Streaming', diamondCost: 100, pointCost: 1000),
    const GiftItem(id: 'g45', name: '4K Ultra Bundle', description: 'Unlimited 4K UHD streaming for 6 months', priceUSD: 34.99, icon: '📺', category: 'Streaming', diamondCost: 350, pointCost: 3500),
  ];

  List<GiftItem> get availableGifts => _availableGifts;

  List<String> get categories {
    final cats = _availableGifts.map((g) => g.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<GiftItem> giftsByCategory(String category) {
    return _availableGifts.where((g) => g.category == category).toList();
  }

  List<GiftItem> get popularGifts => _availableGifts.where((g) => g.isPopular).toList();

  List<GiftItem> giftsByPriceRange(double min, double max) {
    return _availableGifts.where((g) => g.priceUSD >= min && g.priceUSD <= max).toList();
  }

  List<GiftItem> giftsByCurrency(String currency) {
    return _availableGifts.where((g) => g.currencies.contains(currency)).toList();
  }

  List<GiftItem> pointsGifts() {
    return _availableGifts.where((g) => g.pointCost > 0 && g.pointCost <= 10000).toList();
  }

  double priceInCurrency(double priceUSD, String currency) {
    switch (currency) {
      case 'EUR': return (priceUSD * 0.92).roundToDouble();
      case 'GBP': return (priceUSD * 0.79).roundToDouble();
      case 'CAD': return (priceUSD * 1.36).roundToDouble();
      case 'AUD': return (priceUSD * 1.52).roundToDouble();
      case 'JPY': return (priceUSD * 149).roundToDouble();
      case 'INR': return (priceUSD * 83).roundToDouble();
      case 'BRL': return (priceUSD * 5.02).roundToDouble();
      case 'NGN': return (priceUSD * 1550).roundToDouble();
      default: return priceUSD;
    }
  }

  String currencySymbol(String currency) {
    switch (currency) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'CAD': return 'C\$';
      case 'AUD': return 'A\$';
      case 'JPY': return '¥';
      case 'INR': return '₹';
      case 'BRL': return 'R\$';
      case 'NGN': return '₦';
      default: return '\$';
    }
  }

  final List<GiftHistory> _giftHistory = [
    GiftHistory(id: 'h1', recipient: 'sarah@email.com', itemName: '1 Month Premium', price: 9.99, date: DateTime(2026, 6, 1), delivered: true, currency: 'USD'),
    GiftHistory(id: 'h2', recipient: 'mike@email.com', itemName: 'Movie Rental Pass', price: 14.99, date: DateTime(2026, 5, 28), delivered: true, currency: 'USD', diamondsSpent: 150),
    GiftHistory(id: 'h3', recipient: 'emma@email.com', itemName: '3 Months Premium', price: 24.99, date: DateTime(2026, 5, 20), delivered: false, currency: 'USD'),
    GiftHistory(id: 'h4', recipient: 'david@email.com', itemName: 'Gift Card \$25', price: 25.00, date: DateTime(2026, 6, 5), delivered: true, currency: 'USD', diamondsSpent: 250),
    GiftHistory(id: 'h5', recipient: 'lisa@email.com', itemName: 'Virtual Movie Ticket', price: 4.99, date: DateTime(2026, 6, 3), delivered: true, currency: 'EUR', pointsSpent: 500),
  ];

  List<GiftHistory> get giftHistory => _giftHistory;

  Future<bool> sendGift(String recipientEmail, GiftItem gift, {String currency = 'USD', bool useDiamonds = false, bool usePoints = false}) async {
    await Future.delayed(const Duration(seconds: 1));
    _giftHistory.insert(0, GiftHistory(
      id: 'h${DateTime.now().millisecondsSinceEpoch}',
      recipient: recipientEmail,
      itemName: gift.name,
      price: priceInCurrency(gift.priceUSD, currency),
      currency: currency,
      date: DateTime.now(),
      delivered: true,
      diamondsSpent: useDiamonds ? gift.diamondCost : 0,
      pointsSpent: usePoints ? gift.pointCost : 0,
    ));
    notifyListeners();
    return true;
  }
}
