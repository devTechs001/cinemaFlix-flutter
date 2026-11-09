import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';

/// Admin system — the full control room for the whole platform.
///
/// ADMIN ONLY: the gate validates the backend `ADMIN_CODE` (printed in the
/// backend console at boot, or set via the `ADMIN_CODE` env var) against a
/// real admin endpoint on unlock. Regular users cannot get past this gate —
/// every request carries `x-admin-code` and the backend answers 403 without
/// it. There is deliberately no local/dev bypass here.
///
/// Tabs:
///  - Overview: platform stats, maintenance mode, announcements
///  - Market:   seller applications + product listings (approve / reject)
///  - Users:    user directory with ban / unban
///  - Features: feature flags — switch whole system features on/off
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _codeController = TextEditingController();
  bool _unlocked = false;
  bool _loading = false;
  int _tab = 0;

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _maintenance = {};
  Map<String, dynamic> _flags = {};
  List<Map<String, dynamic>> _sellers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _users = [];
  String _userQuery = '';
  String? _error;
  bool _marketLoaded = false;
  bool _usersLoaded = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'x-admin-code': _codeController.text,
      };

  Future<Map<String, dynamic>> _api(String path,
      {String method = 'GET', Object? body}) async {
    final uri = Uri.parse(ApiConfig.apiPath(path));
    final request = switch (method) {
      'GET' => http.get(uri, headers: _headers()),
      'PUT' => http.put(uri, headers: _headers(), body: jsonEncode(body ?? {})),
      'POST' => http.post(uri, headers: _headers(), body: jsonEncode(body ?? {})),
      _ => throw Exception('Unsupported method'),
    };
    final res = await request.timeout(const Duration(seconds: 10));
    final Map<String, dynamic> decoded =
        res.body.isEmpty ? {} : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(decoded['error'] ?? 'HTTP ${res.statusCode}');
    }
    return decoded;
  }

  /// Validates the entered code against the backend — the only way in.
  Future<void> _unlock() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _stats = await _api('/admin/stats');
      _maintenance = _stats['maintenance'] is Map<String, dynamic>
          ? _stats['maintenance'] as Map<String, dynamic>
          : {};
      _flags = _stats['featureFlags'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(_stats['featureFlags'] as Map)
          : {};
      setState(() => _unlocked = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
    setState(() => _loading = false);
  }

  void _lock() {
    _codeController.clear();
    setState(() {
      _unlocked = false;
      _tab = 0;
      _marketLoaded = false;
      _usersLoaded = false;
      _sellers = [];
      _products = [];
      _users = [];
      _stats = {};
      _flags = {};
    });
  }

  Future<void> _refresh() async {
    if (!_unlocked) return;
    setState(() => _loading = true);
    try {
      _stats = await _api('/admin/stats');
      _maintenance = await _api('/admin/maintenance');
      _flags = await _api('/admin/feature-flags');
      if (_tab == 1) await _loadMarket();
      if (_tab == 2) await _loadUsers();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMarket() async {
    final sellers = await _api('/admin/sellers');
    final products = await _api('/ecommerce/products?all=true');
    _sellers = List<Map<String, dynamic>>.from((sellers['sellers'] as List?) ?? []);
    _products = List<Map<String, dynamic>>.from((products['products'] as List?) ?? []);
    _marketLoaded = true;
  }

  Future<void> _loadUsers() async {
    final data = await _api('/admin/users');
    _users = List<Map<String, dynamic>>.from((data['users'] as List?) ?? []);
    _usersLoaded = true;
  }

  Future<void> _onTab(int index) async {
    setState(() => _tab = index);
    if (index == 1 && !_marketLoaded) {
      setState(() => _loading = true);
      try {
        await _loadMarket();
        _error = null;
      } catch (e) {
        _error = e.toString().replaceAll('Exception: ', '');
      }
      if (mounted) setState(() => _loading = false);
    }
    if (index == 2 && !_usersLoaded) {
      setState(() => _loading = true);
      try {
        await _loadUsers();
        _error = null;
      } catch (e) {
        _error = e.toString().replaceAll('Exception: ', '');
      }
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setMaintenance(bool enabled) async {
    try {
      await _api('/admin/maintenance', method: 'PUT', body: {'enabled': enabled});
      await _refresh();
      if (mounted) _showSnack('Maintenance ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (mounted) _showSnack('Failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _setFlag(String key, bool value) async {
    final prev = _flags[key];
    setState(() => _flags[key] = value); // optimistic
    try {
      final saved = await _api('/admin/feature-flags', method: 'PUT', body: {key: value});
      setState(() => _flags = Map<String, dynamic>.from(saved));
      _showSnack('$key ${value ? 'enabled' : 'disabled'}');
    } catch (e) {
      setState(() => _flags[key] = prev);
      _showSnack('Failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _decideSeller(String userId, bool approve) async {
    try {
      await _api('/ecommerce/seller/$userId/${approve ? 'approve' : 'reject'}',
          method: 'PUT');
      await _loadMarket();
      setState(() {});
      _showSnack('Seller ${approve ? 'approved' : 'rejected'}');
    } catch (e) {
      _showSnack('Failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _decideProduct(String productId, bool approve) async {
    try {
      await _api('/ecommerce/products/$productId/${approve ? 'approve' : 'reject'}',
          method: 'PUT');
      await _loadMarket();
      setState(() {});
      _showSnack('Product ${approve ? 'approved' : 'rejected'}');
    } catch (e) {
      _showSnack('Failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _banUser(String id, bool ban) async {
    try {
      final res = await _api('/admin/users/$id/${ban ? 'ban' : 'unban'}', method: 'PUT');
      if (res['found'] == false) {
        _showSnack('User not found on this backend');
      } else {
        await _loadUsers();
        setState(() {});
        _showSnack('User ${ban ? 'banned' : 'unbanned'}');
      }
    } catch (e) {
      _showSnack('Failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _announce() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Broadcast announcement', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: 'Title', hintStyle: TextStyle(color: Colors.white24)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bodyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: 'Message', hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(dialogContext);
              try {
                await _api('/admin/announce', method: 'POST',
                    body: {'title': title, 'body': bodyController.text.trim()});
                _showSnack('Announcement broadcast');
              } catch (e) {
                _showSnack('Failed: ${e.toString().replaceAll('Exception: ', '')}');
              }
            },
            child: const Text('Send',
                style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: Row(children: [
          const Icon(Icons.shield, color: Color(0xFFE50914), size: 22),
          const SizedBox(width: 8),
          Text(_unlocked ? 'Admin Control Room' : 'Admin Access',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        actions: [
          if (_unlocked) ...[
            IconButton(
                onPressed: _loading ? null : _refresh,
                icon: const Icon(Icons.refresh, color: Colors.white70)),
            IconButton(
                onPressed: _lock,
                icon: const Icon(Icons.lock_outline, color: Colors.white70)),
          ],
        ],
        bottom: _unlocked
            ? BottomNavigationBar(
                currentIndex: _tab,
                onTap: _onTab,
                type: BottomNavigationBarType.fixed,
                backgroundColor: const Color(0xFF141414),
                selectedItemColor: const Color(0xFFE50914),
                unselectedItemColor: Colors.white38,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
                  BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Market'),
                  BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Users'),
                  BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Features'),
                ],
              )
            : null,
      ),
      body: !_unlocked ? _buildGate() : _buildBody(),
    );
  }

  Widget _buildGate() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE50914), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: const Color(0xFFE50914).withValues(alpha: 0.4), blurRadius: 30)],
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Admin Access Required',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'Admin only. Regular users cannot open this system.\n'
              'Enter the backend ADMIN_CODE (printed in the backend console on boot).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 280,
              child: TextField(
                controller: _codeController,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                onSubmitted: (_) => _unlock(),
                decoration: const InputDecoration(
                  hintText: 'Admin code',
                  hintStyle: TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Color(0xFF1F1F1F),
                  border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(14))),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE50914), fontSize: 12)),
              ),
            ElevatedButton(
              onPressed: _loading ? null : _unlock,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Verify & Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _stats.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }
    return switch (_tab) {
      1 => _buildMarketTab(),
      2 => _buildUsersTab(),
      3 => _buildFeaturesTab(),
      _ => _buildOverviewTab(),
    };
  }

  // ---------------- OVERVIEW ----------------

  Widget _buildOverviewTab() {
    final stats = _stats;
    return RefreshIndicator(
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
                  borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFE50914), fontSize: 12)),
            ),
          _statGrid(stats),
          const SizedBox(height: 16),
          _section('System Controls', [
            SwitchListTile(
              secondary: const Icon(Icons.engineering, color: Colors.orange),
              title: const Text('Maintenance mode', style: TextStyle(color: Colors.white)),
              subtitle: Text(_maintenance['message']?.toString() ?? 'Blocks logins for regular users',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              value: _maintenance['enabled'] == true,
              onChanged: (v) => _setMaintenance(v),
              activeTrackColor: const Color(0xFFE50914),
            ),
            ListTile(
              leading: const Icon(Icons.campaign, color: Color(0xFF7C3AED)),
              title: const Text('Broadcast announcement', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Push a notification to every client',
                  style: TextStyle(color: Colors.white24, fontSize: 11)),
              onTap: _announce,
            ),
            ListTile(
              leading: const Icon(Icons.storage, color: Colors.teal),
              title: const Text('Storage backend', style: TextStyle(color: Colors.white)),
              subtitle: Text('${stats['storage'] ?? '—'}  ·  uptime ${stats['uptimeSec'] ?? '—'}s',
                  style: const TextStyle(color: Colors.white24, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 16),
          _section('Quick Links', [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Dev Panel', '/dev-panel', Icons.code),
                  _chip('Marketplace', '/ecommerce', Icons.storefront),
                  _chip('Wallet', '/wallet', Icons.diamond),
                  _chip('Creator Hub', '/creator-hub', Icons.videocam),
                  _chip('Live', '/live', Icons.live_tv),
                  _chip('Plugins', '/plugins', Icons.extension),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statGrid(Map<String, dynamic> stats) {
    final items = [
      ('Users', stats['users'] ?? 0, Icons.people),
      ('Sellers', stats['sellers'] ?? 0, Icons.storefront),
      ('Products', stats['products'] ?? 0, Icons.inventory_2),
      ('Orders', stats['orders'] ?? 0, Icons.shopping_bag),
      ('Wallets', stats['wallets'] ?? 0, Icons.account_balance_wallet),
      ('Gaming', stats['gamingSessions'] ?? 0, Icons.sports_esports),
      ('Ad impressions', stats['adImpressions'] ?? 0, Icons.ad_units),
      ('Ad clicks', stats['adClicks'] ?? 0, Icons.ads_click),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: items
          .map((it) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                child: Row(children: [
                  Icon(it.$3, color: const Color(0xFFE50914), size: 20),
                  const Spacer(),
                  Text('${it.$2}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ]),
              ))
          .toList(),
    );
  }

  // ---------------- MARKET ----------------

  Widget _buildMarketTab() {
    final pendingSellers = _sellers.where((s) => s['status'] == 'pending').toList();
    final decidedSellers = _sellers.where((s) => s['status'] != 'pending').toList();
    final pendingProducts =
        _products.where((p) => p['approved'] != true && p['rejected'] != true).toList();
    final decidedProducts =
        _products.where((p) => p['approved'] == true || p['rejected'] == true).toList();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loading = true);
        try {
          await _loadMarket();
          _error = null;
        } catch (e) {
          _error = e.toString().replaceAll('Exception: ', '');
        }
        if (mounted) setState(() => _loading = false);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFE50914), fontSize: 12)),
            ),
          _section('Seller applications (${pendingSellers.length} pending)', [
            if (_sellers.isEmpty)
              const _EmptyMsg('No seller applications yet')
            else ...[
              ...pendingSellers.map(_sellerRow),
              if (decidedSellers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('DECIDED', style: _miniLabelStyle()),
                ),
                ...decidedSellers.map(_sellerRow),
              ],
            ],
          ]),
          const SizedBox(height: 16),
          _section('Products (${pendingProducts.length} awaiting review)', [
            if (_products.isEmpty)
              const _EmptyMsg('No products posted yet')
            else ...[
              ...pendingProducts.map(_productRow),
              if (decidedProducts.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('APPROVED / REJECTED', style: _miniLabelStyle()),
                ),
                ...decidedProducts.map(_productRow),
              ],
            ],
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sellerRow(Map<String, dynamic> seller) {
    final status = (seller['status'] ?? 'pending').toString();
    final userId = (seller['userId'] ?? '').toString();
    final (label, color) = switch (status) {
      'approved' => ('Approved', Color(0xFF10B981)),
      'rejected' => ('Rejected', Color(0xFFE50914)),
      _ => ('Pending', Colors.orange),
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(Icons.store, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${seller['shopName'] ?? 'Shop'}  ·  ${seller['category'] ?? 'General'}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            Text('by $userId  ·  $label',
                style: TextStyle(color: color, fontSize: 11)),
          ]),
        ),
        if (status == 'pending') ...[
          IconButton(
            tooltip: 'Approve seller',
            onPressed: () => _decideSeller(userId, true),
            icon: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
          ),
          IconButton(
            tooltip: 'Reject seller',
            onPressed: () => _decideSeller(userId, false),
            icon: const Icon(Icons.cancel, color: Color(0xFFE50914)),
          ),
        ] else
          Chip(
            label: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
            backgroundColor: color,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        IconButton(
          tooltip: 'Remove from list (unban-style clear)',
          onPressed: () => _decideSeller(userId, false),
          icon: const Icon(Icons.more_horiz, color: Colors.white24, size: 18),
        ),
      ]),
    );
  }

  Widget _productRow(Map<String, dynamic> product) {
    final id = (product['id'] ?? '').toString();
    final rejected = product['rejected'] == true;
    final approved = product['approved'] == true;
    final (label, color) = switch ((approved, rejected)) {
      (true, _) => ('Live', Color(0xFF10B981)),
      (_, true) => ('Rejected', Color(0xFFE50914)),
      _ => ('In review', Colors.orange),
    };
    final priceCents = (product['priceCents'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(Icons.shopping_bag_outlined, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${product['title']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            Text('◆ ${(priceCents / 10).ceil()} · stock ${product['stock'] ?? 0} · ${product['postedBy'] ?? 'seller'}  ·  $label',
                style: TextStyle(color: color, fontSize: 11)),
          ]),
        ),
        if (!approved && !rejected) ...[
          IconButton(
            tooltip: 'Approve product',
            onPressed: () => _decideProduct(id, true),
            icon: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
          ),
          IconButton(
            tooltip: 'Reject product',
            onPressed: () => _decideProduct(id, false),
            icon: const Icon(Icons.cancel, color: Color(0xFFE50914)),
          ),
        ] else
          Chip(
            label: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
            backgroundColor: color,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
      ]),
    );
  }

  // ---------------- USERS ----------------

  Widget _buildUsersTab() {
    final query = _userQuery.trim().toLowerCase();
    final visible = query.isEmpty
        ? _users
        : _users
            .where((u) =>
                (u['username'] ?? '').toString().toLowerCase().contains(query) ||
                (u['email'] ?? '').toString().toLowerCase().contains(query) ||
                (u['id'] ?? '').toString().toLowerCase().contains(query))
            .toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: TextField(
          onChanged: (v) => setState(() => _userQuery = v),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 18),
            hintText: 'Search ${_users.length} users (name / email / id)',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF161616),
            isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(
        child: _users.isEmpty
            ? const _EmptyMsg('No users loaded')
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final u = visible[i];
                  final banned = u['banned'] == true;
                  final color = banned ? const Color(0xFFE50914) : Colors.white;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: (banned ? const Color(0xFFE50914) : Colors.white)
                              .withValues(alpha: 0.15)),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        child: Icon(banned ? Icons.block : Icons.person,
                            color: color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${u['username'] ?? 'user'}${banned ? '  ·  BANNED' : ''}',
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${u['email'] ?? ''}  ·  ${u['id'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ]),
                      ),
                      TextButton(
                        onPressed: () => _banUser('${u['id']}', !banned),
                        child: Text(banned ? 'Unban' : 'Ban',
                            style: TextStyle(
                                color: banned ? const Color(0xFF10B981) : const Color(0xFFE50914),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }

  // ---------------- FEATURES ----------------

  static const Map<String, (String, String, IconData)> _flagMeta = {
    'ecommerce': ('Marketplace', 'Products, sellers & orders', Icons.storefront),
    'gaming': ('Gaming', 'Games & tournaments', Icons.sports_esports),
    'ads': ('Ads', 'Ad serving & monetization', Icons.ad_units),
    'dating': ('Dating', 'Dating experiences', Icons.favorite),
    'live': ('Live streaming', 'New live rooms (existing rooms stay up)', Icons.live_tv),
    'shorts': ('Shorts', 'Short-form video feed', Icons.video_library),
    'walletPoints': ('Wallet points', 'Points earning & transfers', Icons.account_balance_wallet),
  };

  Widget _buildFeaturesTab() {
    final flags = _flags;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.35))),
            child: const Text(
              'Switch platform features on or off for everyone. Disabled features return 403 from the backend — this is how removed/retired features are managed.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          _section('Feature flags', [
            for (final entry in _flagMeta.entries)
              SwitchListTile(
                secondary: Icon(entry.$3, color: const Color(0xFFE50914)),
                title: Text(entry.$1, style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(entry.$2, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                value: flags[entry.key] != false, // missing key = enabled by default
                onChanged: (v) => _setFlag(entry.key, v),
                activeTrackColor: const Color(0xFFE50914),
              ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------- shared bits ----------------

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(title.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _chip(String label, String route, IconData icon) {
    return ActionChip(
      backgroundColor: const Color(0xFF1F1F1F),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      avatar: Icon(icon, color: const Color(0xFFE50914), size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      onPressed: () => Navigator.pushNamed(context, route),
    );
  }

  TextStyle _miniLabelStyle() =>
      const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w600);

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }
}

class _EmptyMsg extends StatelessWidget {
  final String text;
  const _EmptyMsg(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white24, fontSize: 13))),
    );
  }
}
