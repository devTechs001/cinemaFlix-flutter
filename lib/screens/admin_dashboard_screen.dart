import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/globals.dart';

/// Admin / developer dashboard — the system control room. Everything from
/// bugs.txt "ADMIN/DEV system" lives here: backend stats & monitoring,
/// maintenance mode, user ban controls. Rail-side feature flags plus seller
/// approvals are managed through the same /api/admin endpoints.
///
/// Access requires the admin code (`admin123` by default — configurable via
/// the ADMIN_CODE env var on the backend).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _codeController = TextEditingController();
  bool _unlocked = false;
  bool _loading = false;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _maintenance = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    // Local dev mode unlock — includes offline backends that have no stats yet.
    if (devService.devModeEnabled) {
      _codeController.text = 'admin123';
      _unlocked = true;
      _refresh();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'x-admin-code': _codeController.text,
      };

  Future<Map<String, dynamic>> _api(String path, {String method = 'GET', Object? body}) async {
    final uri = Uri.parse(ApiConfig.apiPath(path));
    final request = switch (method) {
      'GET' => http.get(uri, headers: _headers()),
      'PUT' => http.put(uri, headers: _headers(), body: jsonEncode(body ?? {})),
      _ => throw Exception('Unsupported method'),
    };
    final res = await request.timeout(const Duration(seconds: 10));
    final Map<String, dynamic> decoded = res.body.isEmpty
        ? {}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(decoded['error'] ?? 'HTTP ${res.statusCode}');
    }
    return decoded;
  }

  Future<void> _unlock() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _stats = await _api('/admin/stats');
      _maintenance = _stats['maintenance'] is Map<String, dynamic>? ? _stats['maintenance'] as Map<String, dynamic> : {};
      setState(() => _unlocked = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
    setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    if (!_unlocked) return;
    setState(() => _loading = true);
    try {
      _stats = await _api('/admin/stats');
      final remoteMaintenance = await _api('/admin/maintenance');
      _maintenance = remoteMaintenance;
    } catch (_) {
      // Offline backend — keep last known values.
    }
    setState(() => _loading = false);
  }

  Future<void> _setMaintenance(bool enabled) async {
    try {
      await _api('/admin/maintenance', method: 'PUT', body: {'enabled': enabled});
      if (devService.maintenanceMode != enabled) devService.toggleMaintenanceMode();
      await _refresh();
      if (mounted) _showSnack('Maintenance ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (mounted) _showSnack('Failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _banUser(String id, bool ban) async {
    try {
      await _api('/admin/users/$id/${ban ? 'ban' : 'unban'}', method: 'PUT');
      _showSnack('User ${ban ? 'banned' : 'unbanned'}');
    } catch (e) {
      _showSnack('Failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('System Control Room', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
      ),
      body: !_unlocked ? _buildGate() : _buildDashboard(),
    );
  }

  Widget _buildGate() {
    return Center(
      child: Padding(
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
              child: const Icon(Icons.shield, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Admin Access Required', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Restricted to the system developer.\nControls features, users, monitoring.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              width: 280,
              child: TextField(
                controller: _codeController,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                decoration: const InputDecoration(
                  hintText: 'Admin code',
                  hintStyle: TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Color(0xFF1F1F1F),
                  border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(14))),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFE50914), fontSize: 12)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _unlock,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              child: const Text('Unlock Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_stats.isNotEmpty) return _withStats(_stats);
    return const Center(child: Text('No backend stats available', style: TextStyle(color: Colors.white24)));
  }

  Widget _withStats(Map<String, dynamic> stats) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
            leading: const Icon(Icons.people, color: Colors.teal),
            title: const Text('Ban / unban users', style: TextStyle(color: Colors.white)),
            subtitle: const Text('POST userId to moderation queue (users/:id/ban)', style: const TextStyle(color: Colors.white24, fontSize: 11)),
            onTap: () => _showBanDialog(),
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
    );
  }

  Widget _statGrid(Map<String, dynamic> stats) {
    final items = [
      ('Users', stats['users'] ?? 0, Icons.people),
      ('Wallets', stats['wallets'] ?? 0, Icons.account_balance_wallet),
      ('Ad impressions', stats['adImpressions'] ?? 0, Icons.ad_units),
      ('Ad clicks', stats['adClicks'] ?? 0, Icons.ads_click),
      ('Gaming sessions', stats['gamingSessions'] ?? 0, Icons.sports_esports),
      ('Orders', stats['orders'] ?? 0, Icons.shopping_bag),
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
                child: Row(
                  children: [
                    Icon(it.$3, color: const Color(0xFFE50914), size: 22),
                    const Spacer(),
                    Text('${it.$2}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                  ],
                ),
              ))
          .toList(),
    );
  }

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
                style: const TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
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

  void _showBanDialog() {
    final controller = TextEditingController();
    bool ban = true;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          title: const Text('User moderation', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'userId', hintStyle: TextStyle(color: Colors.white24))),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Ban (off = unban)', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: ban,
                onChanged: (v) => setDialogState(() => ban = v),
                activeTrackColor: const Color(0xFFE50914),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
            TextButton(
              onPressed: () async {
                final id = controller.text.trim();
                if (id.isEmpty) return;
                Navigator.pop(dialogContext);
                await _banUser(id, ban);
              },
              child: const Text('Apply', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }
}
