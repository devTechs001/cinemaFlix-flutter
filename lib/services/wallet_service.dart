import 'package:flutter/foundation.dart';

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
  final List<Transaction> _transactions = [
    Transaction(id: 'tx1', type: 'bonus', description: 'Welcome bonus', amount: 500, date: DateTime(2026, 6, 1)),
  ];

  int get diamonds => _diamonds;
  int get points => _points;
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  bool spendDiamonds(int amount, String description, {String? relatedUserId}) {
    if (_diamonds < amount) return false;
    _diamonds -= amount;
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
    _transactions.insert(0, Transaction(
      id: 'tx${DateTime.now().millisecondsSinceEpoch}',
      type: 'purchase',
      description: description,
      amount: amount,
      date: DateTime.now(),
    ));
    notifyListeners();
  }

  void addPoints(int amount, String description) {
    _points += amount;
    _transactions.insert(0, Transaction(
      id: 'tx${DateTime.now().millisecondsSinceEpoch}',
      type: 'earn',
      description: description,
      amount: amount,
      date: DateTime.now(),
    ));
    notifyListeners();
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
    return spendDiamonds(diamondCost, 'Sent $giftName gift', relatedUserId: recipientId);
  }
}

final walletService = WalletService();
