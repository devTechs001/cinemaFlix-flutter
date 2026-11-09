import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/globals.dart';

/// Seller dashboard — the approved seller's control room.
///
/// Reachable only after an admin approves the seller application (the
/// backend enforces this too: only approved sellers can post, and this
/// screen loads their own products incl. awaiting-admin items). From here
/// a seller posts products (they go live only once an admin approves
/// them), tracks stock and sees approval status per listing.
class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  bool _loading = true;
  String? _error;
  String _status = 'none';
  String _shopName = '';
  List<Map<String, dynamic>> _products = [];

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _categoryController = TextEditingController(text: 'General');
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authService.token != null && authService.token!.isNotEmpty)
      'Authorization': 'Bearer ${authService.token}',
    'x-user-id': authService.currentUser?.id ?? 'guest',
  };

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http
        .get(Uri.parse(ApiConfig.apiPath(path)), headers: _headers)
        .timeout(const Duration(seconds: 8));
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final decoded = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(decoded['error'] ?? 'HTTP ${res.statusCode}');
    }
    return decoded;
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await _get('/ecommerce/seller/status');
      final mine = await _get('/ecommerce/seller/products');
      final app = status['application'] as Map<String, dynamic>? ?? {};
      _status = (app['status'] ?? 'none').toString();
      _shopName = (app['shopName'] ?? '').toString();
      _products = List<Map<String, dynamic>>.from(
        (mine['products'] as List?) ?? [],
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _postProduct() async {
    final title = _titleController.text.trim();
    final priceDollars = double.tryParse(_priceController.text.trim()) ?? 0;
    if (title.isEmpty || priceDollars <= 0) {
      _showSnack('Enter a title and a price above 0');
      return;
    }
    setState(() => _posting = true);
    try {
      final priceCents = (priceDollars * 100).round();
      final stock = int.tryParse(_stockController.text.trim()) ?? 1;
      final res = await http
          .post(
            Uri.parse(ApiConfig.apiPath('/ecommerce/products')),
            headers: _headers,
            body: jsonEncode({
              'title': title,
              'priceCents': priceCents,
              'stock': stock < 1 ? 1 : stock,
              'category': _categoryController.text.trim().isEmpty
                  ? 'General'
                  : _categoryController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));
      _decode(res);
      _titleController.clear();
      _priceController.clear();
      _stockController.text = '1';
      _showSnack('Product posted — awaiting admin approval');
      await _refresh();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    }
    if (mounted) setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Row(
          children: [
            Icon(Icons.store, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text(
              'Seller Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFE50914),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (_status != 'approved')
                    _buildGate()
                  else ...[
                    _buildShopHeader(),
                    const SizedBox(height: 14),
                    _buildPostCard(),
                    const SizedBox(height: 14),
                    _buildProductsSection(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildGate() {
    final message = switch (_status) {
      'pending' =>
        'Your seller application is pending admin approval. You can post products as soon as an admin approves you.',
      'rejected' =>
        'Your seller application was rejected by an admin. Apply again from the Marketplace with a different shop.',
      _ =>
        'You need an approved seller account to use the dashboard. Apply from the Marketplace — an admin reviews every application.',
    };
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(
            _status == 'rejected' ? Icons.block : Icons.hourglass_top,
            color: _status == 'rejected'
                ? const Color(0xFFE50914)
                : Colors.orange,
            size: 44,
          ),
          const SizedBox(height: 14),
          Text(
            _status == 'pending'
                ? 'Awaiting admin approval'
                : _status == 'rejected'
                ? 'Application rejected'
                : 'Seller account required',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/ecommerce'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            icon: const Icon(Icons.storefront, size: 18),
            label: const Text('Open Marketplace'),
          ),
        ],
      ),
    );
  }

  Widget _buildShopHeader() {
    final approved = _products.where((p) => p['approved'] == true).length;
    final pending = _products
        .where((p) => p['approved'] != true && p['rejected'] != true)
        .length;
    final rejected = _products.where((p) => p['rejected'] == true).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.18),
            const Color(0xFF10B981).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _shopName.isEmpty ? 'My shop' : _shopName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Chip(
                avatar: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 14,
                ),
                label: Text(
                  'Admin approved',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: Color(0xFF10B981),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat('Live', approved, const Color(0xFF10B981)),
              _stat('In review', pending, Colors.orange),
              _stat('Rejected', rejected, const Color(0xFFE50914)),
              _stat('Total', _products.length, Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POST A PRODUCT',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _field(_titleController, 'Product title', Icons.label_outline),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _field(
                  _priceController,
                  'Price (USD)',
                  Icons.attach_money,
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  _stockController,
                  'Stock',
                  Icons.inventory_2_outlined,
                  keyboard: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _field(_categoryController, 'Category', Icons.category_outlined),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _posting ? null : _postProduct,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _posting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add, size: 18),
              label: const Text(
                'Post product (admin review)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'New listings appear in the Marketplace after an admin approves them.',
            style: TextStyle(color: Colors.white30, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white24, size: 18),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MY PRODUCTS',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No products yet — post your first one above',
                  style: TextStyle(color: Colors.white24, fontSize: 13),
                ),
              ),
            )
          else
            ..._products.map(_productRow),
        ],
      ),
    );
  }

  Widget _productRow(Map<String, dynamic> product) {
    final priceCents = (product['priceCents'] as num?)?.toInt() ?? 0;
    final (statusLabel, statusColor, statusIcon) = switch (product) {
      {'rejected': true} => (
        'Rejected by admin',
        const Color(0xFFE50914),
        Icons.cancel,
      ),
      {'approved': true} => (
        'Live in marketplace',
        const Color(0xFF10B981),
        Icons.check_circle,
      ),
      _ => ('Awaiting admin approval', Colors.orange, Icons.hourglass_top),
    };
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_bag_outlined, color: statusColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product['title']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '◆ ${(priceCents / 10).ceil()}  ·  stock ${product['stock'] ?? 0}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}
