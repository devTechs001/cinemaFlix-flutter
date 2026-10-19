import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';
import '../services/globals.dart';
import '../services/creator_service.dart';
import '../widgets/dev_mode_badge.dart';

class DevPanelScreen extends StatefulWidget {
  const DevPanelScreen({super.key});

  @override
  State<DevPanelScreen> createState() => _DevPanelScreenState();
}

class _DevPanelScreenState extends State<DevPanelScreen> {
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    devService.addListener(_onDevChange);
  }

  void _onDevChange() => setState(() {});

  @override
  void dispose() {
    devService.removeListener(_onDevChange);
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Row(
          children: [
            Text('Dev Panel', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            DevModeBadge(),
          ],
        ),
        actions: [
          if (devService.devModeEnabled)
            IconButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                devService.deactivateDevMode();
              },
              icon: const Icon(Icons.lock_outline, color: Colors.white54),
            ),
        ],
      ),
      body: devService.devModeEnabled ? _buildPanel() : _buildAuth(),
    );
  }

  Widget _buildAuth() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFE50914)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            const Text('Developer Access', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Code: admin123 — unlocks all features', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              obscureText: true,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Access Code',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final success = devService.authenticate(_codeController.text);
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid access code'), backgroundColor: Color(0xFFE50914)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Unlock Full Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF7C3AED).withValues(alpha: 0.25), const Color(0xFFE50914).withValues(alpha: 0.15)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user, color: Color(0xFF7C3AED), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  devService.hasFullAccess ? 'Full access active — all screens unlocked' : 'Dev mode on — enable Unlock All for full access',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card('Access Controls', [
          _toggle(Icons.lock_open, 'Unlock All Features', devService.unlockAll, (_) => devService.toggleUnlockAll()),
          _toggle(Icons.fingerprint, 'Bypass Authentication', devService.bypassAuth, (_) => devService.toggleBypassAuth()),
          _toggle(Icons.construction, 'Maintenance Mode', devService.maintenanceMode, (_) => devService.toggleMaintenanceMode()),
          _toggle(Icons.visibility, 'Verbose Logging', devService.verboseLogging, (_) => devService.toggleVerboseLogging()),
          _toggle(Icons.speed, 'Show FPS Counter', devService.showFps, (_) => devService.toggleShowFps()),
        ]),
        const SizedBox(height: 16),
        _card('Quick Navigate', _routeButtons()),
        const SizedBox(height: 16),
        _card('Quick Actions', [
          _action(Icons.movie, 'Enable Creator Mode', () {
            creatorService.enableCreatorMode();
            _showSnack('Creator mode enabled');
          }),
          _action(Icons.home, 'Go to Main App', () => Navigator.pushReplacementNamed(context, '/main')),
          _action(Icons.delete_sweep, 'Clear Event Logs', () {
            devService.clearLogs();
            _showSnack('Logs cleared');
          }),
        ]),
        const SizedBox(height: 16),
        _card('Event Log (${devService.eventLog.length})', [
          if (devService.eventLog.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No events logged', style: TextStyle(color: Colors.white38)))
          else
            ...devService.eventLog.take(20).map((e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(e, style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace')),
            )),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }

  List<Widget> _routeButtons() {
    final routes = [
      ('Live', '/live', Icons.live_tv),
      ('Dating', '/dating', Icons.favorite),
      ('Vault', '/vault', Icons.lock),
      ('Wallet', '/wallet', Icons.diamond),
      ('Creator Hub', '/creator-hub', Icons.videocam),
      ('Shorts', '/shorts', Icons.video_library),
      ('Chat', '/chat', Icons.chat),
      ('Dev Panel', '/dev-panel', Icons.code),
      ('Admin Room', '/admin-dashboard', Icons.shield),
      ('Ecommerce', '/ecommerce', Icons.storefront),
      ('Gaming', '/gaming', Icons.sports_esports),
    ];
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: routes.map((r) {
          return InteractiveCard(
            onTap: () => Navigator.pushNamed(context, r.$2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(r.$3, color: const Color(0xFFE50914), size: 18),
                  const SizedBox(width: 8),
                  Text(r.$1, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ];
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _toggle(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.white54, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: value,
      onChanged: (v) {
        HapticFeedback.lightImpact();
        onChanged(v);
      },
      activeTrackColor: const Color(0xFF7C3AED),
    );
  }

  Widget _action(IconData icon, String title, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: Colors.white54, size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }
}
