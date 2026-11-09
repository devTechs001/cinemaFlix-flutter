import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/globals.dart';
import '../services/sound_service.dart';

/// Ecommerce marketplace — sellers appear in the nav only after their seller
/// application is approved by an admin (per bugs.txt). Regular users browse
/// approved products and pay with diamonds from the wallet; approved sellers
/// can post products which then flow into the feed/shorts.
class EcommerceScreen extends StatefulWidget {
  const EcommerceScreen({super.key});

  @override
  State<EcommerceScreen> createState() => _EcommerceScreenState();
}

class _EcommerceScreenState extends State<EcommerceScreen> {
  List<Map<String, dynamic>> _products = [];
  String _sellerStatus = 'loading';
  bool _loading = true;
  String? _error;
  final _shopNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _api('/ecommerce/products');
      final status = await _api('/ecommerce/seller/status');
      _products = List<Map<String, dynamic>>.from((products['products'] as List?) ?? []);
      _sellerStatus = ((status['application'] as Map?)?['status'] ?? 'none').toString();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    setState(() => _loading = false);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authService.token != null && authService.token!.isNotEmpty) 'Authorization': 'Bearer ${authService.token}',
        'x-user-id': authService.currentUser?.id ?? 'guest',
      };

  Future<Map<String, dynamic>> _api(String path) async {
    final res = await http.get(Uri.parse(ApiConfig.apiPath(path)), headers: _headers).timeout(const Duration(seconds: 8));
    return _decode(res);
  }

  Future<Map<String, dynamic>> _post(String path, Object body) async {
    final res = await http.post(Uri.parse(ApiConfig.apiPath(path)), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 8));
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final decoded = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) throw Exception(decoded['error'] ?? 'HTTP ${res.statusCode}');
    return decoded;
  }

  Future<void> _applyAsSeller() async {
    final shopName = _shopNameController.text.trim();
    if (shopName.isEmpty) {
      _showSnack('Enter your shop name');
      return;
    }
    try {
      final result = await _post('/ecommerce/seller/apply', {'shopName': shopName});
      _showSnack(result['message']?.toString() ?? 'Application submitted');
      await _refresh();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _buy(Map<String, dynamic> product) async {
    HapticFeedback.mediumImpact();
    soundService.play(SoundEvent.transaction);
    try {
      final userId = authService.currentUser?.id;
      if (userId == null) {
        _showSnack('Sign in to purchase');
        return;
      }
      final res = await _post('/ecommerce/orders', {'productId': product['id']});
      _showSnack('Purchased ${product['title']} — order ${res['order']?['id'] ?? ''}');
      await _refresh();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Row(children: [
          Icon(Icons.storefront, color: Color(0xFF10B981)),
          SizedBox(width: 8),
          Text('Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          if (_sellerStatus == 'approved')
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Chip(
                avatar: Icon(Icons.verified, color: Color(0xFF10B981), size: 16),
                label: Text('Seller', style: TextStyle(fontSize: 11)),
                backgroundColor: Color(0xFF10B981),
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFE50914).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFE50914), fontSize: 12)),
                    ),
                  const SizedBox(height: 8),
                  if (_sellerStatus != 'approved') _buildSellerCta(),
                  if (_sellerStatus == 'approved') _buildSellerDashboardEntry(),
                  const SizedBox(height: 16),
                  if (_products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('No approved products yet', textAlign: TextAlign.center, style: TextStyle(color: Colors.white24)),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.75),
                      itemCount: _products.length,
                      itemBuilder: (context, i) => _productCard(_products[i]),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSellerCta() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF10B981).withValues(alpha: 0.15), const Color(0xFF10B981).withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Become a Seller', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            _sellerStatus == 'none'
                ? 'Apply to open a shop. Sellers appear in the nav only after admin approval.'
                : _sellerStatus == 'pending'
                    ? 'Your application is pending admin approval.'
                    : 'Application was not approved.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (_sellerStatus == 'none') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _shopNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Your shop name',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyAsSeller,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text('Apply for seller account', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSellerDashboardEntry() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: Color(0xFF10B981), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Approved seller — manage listings, stock & approvals in your dashboard.',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/seller-dashboard'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final priceCents = (product['priceCents'] as num?)?.toInt() ?? 0;
    final diamonds = (priceCents / 10).ceil();
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Center(child: Icon(Icons.shopping_bag, color: Color(0xFF10B981), size: 40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${product['title']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('◆ $diamonds · stock ${product['stock']}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _buy(product),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE50914), padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    child: const Text('Buy'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }
}
