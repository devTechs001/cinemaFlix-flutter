import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class Transaction {
  final String id;
  final String type;
  final String description;
  final int amount;
  final DateTime date;
  final String? relatedUserId;

  const Transaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    this.relatedUserId,
  });
}

class WalletService extends ChangeNotifier {
  int _diamonds = 500;
  int _points = 0;
  int _dailyStreak = 3;
  final List<Transaction> _transactions = [
    Transaction(id: 'tx1', type: 'bonus', description: 'Welcome bonus', amount: 500, date: DateTime(2026, 6, 1)),
  ];

  int get diamonds => _diamonds;
  int get points => _points;
  int get dailyStreak => _dailyStreak;
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  bool spendDiamonds(int amount, String description, {String? relatedUserId}) {
    if (_diamonds < amount) return false;
    _diamonds -= amount;
    _mirror('spend', 'diamonds', amount, description);
    _transactions.insert(0, Transaction(
      id: 'tx${DateTime.now().millisecondsSinceEpoch}',
      type: 'spend',
      description: description,
      amount: -amount,
      date: DateTime.now(),
      relatedUserId: relatedUserId,
    ));
    notifyListeners();
    return true;
  }

  void addDiamonds(int amount, String description) {
    _diamonds += amount;
    _mirror('earn', 'diamonds', amount, description);
    _transactions.insert(0, Transaction(
      id: 'tx${DateTime.now().millisecondsSinceEpoch}',
      type: 'purchase',
      description: description,
      amount: amount,
      date: DateTime.now(),
    ));
    notifyListeners();
  }

  void addPoints(int amount, [String description = '']) {
    _points += amount;
    _mirror('earn', 'points', amount, description.isNotEmpty ? description : 'Earned $amount pts');
    _transactions.insert(0, Transaction(
      id: 'tx${DateTime.now().millisecondsSinceEpoch}',
      type: 'earn',
      description: description.isNotEmpty ? description : 'Earned $amount pts',
      amount: amount,
      date: DateTime.now(),
    ));
    notifyListeners();
  }

  void claimDailyBonus() {
    _dailyStreak++;
    addPoints(5, 'Daily check-in (streak: $_dailyStreak)');
  }

  void convertPointsToDiamonds() {
    if (_points < 100) return;
    final earned = _points ~/ 100;
    final used = earned * 100;
    _points -= used;
    _diamonds += earned;
    _transactions.insert(0, Transaction(
      id: 'tx${DateTime.now().millisecondsSinceEpoch}',
      type: 'convert',
      description: 'Converted ${used}pts to $earned diamonds',
      amount: earned,
      date: DateTime.now(),
    ));
    notifyListeners();
  }

  Future<bool> purchaseDiamonds(int amount) async {
    await Future.delayed(const Duration(seconds: 1));
    addDiamonds(amount, 'Purchased $amount diamonds');
    return true;
  }

  bool sendGift(int diamondCost, String giftName, String recipientId) {
    final ok = spendDiamonds(diamondCost, 'Sent $giftName gift', relatedUserId: recipientId);
    if (ok) _mirrorGift(recipientId, 'diamonds', diamondCost, giftName);
    return ok;
  }

  /// Non-destructive backend mirror: the local wallet remains the source of
  /// truth and every transaction is also logged to /api/wallet/:userId/* so
  /// the ecosystem (gifts, points, payments) is wired to the server wallet.
  /// Signed out users skip mirroring silently.
  Future<void> _mirror(String type, String currency, int amount, String note) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return;
      final endpoint = type == 'spend' ? 'spend' : 'earn';
      await http
          .post(
            Uri.parse('${ApiConfig.apiPath('/wallet/$userId')}/$endpoint'),
            headers: {'Content-Type': 'application/json', if (await _token() case final token? when token.isNotEmpty) 'Authorization': 'Bearer $token'},
            body: jsonEncode({'currency': currency, 'amount': amount, 'note': note}),
          )
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('WalletService: backend mirror skipped: $e');
    }
  }

  Future<void> _mirrorGift(String toUserId, String currency, int amount, String giftName) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return;
      await http
          .post(
            Uri.parse('${ApiConfig.apiPath('/wallet/$userId')}/gift'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'toUserId': toUserId, 'currency': currency, 'amount': amount, 'note': giftName}),
          )
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('WalletService: gift mirror skipped: $e');
    }
  }

  Future<String?> _currentUserId() async {
    if (!_isSignedIn()) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('auth_user');
    if (raw == null) return null;
    try {
      return ((jsonDecode(raw) as Map<String, dynamic>)['id'])?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  bool _isSignedIn() => _signedIn;

  /// Auth state is injected by the app shell to avoid a circular dependency
  /// with AuthService. Defaults to false (mirroring disabled) until set.
  static bool _signedIn = false;

  static void setSignedIn(bool value) => _signedIn = value;
}

final walletService = WalletService();
