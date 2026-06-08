import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';
import '../services/dev_service.dart';

class DevPanelScreen extends StatefulWidget {
  const DevPanelScreen({super.key});

  @override
  State<DevPanelScreen> createState() => _DevPanelScreenState();
}

class _DevPanelScreenState extends State<DevPanelScreen> {
  final _devService = DevService();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _devService.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeController.dispose();
    _devService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Panel', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_devService.devModeEnabled)
            InteractiveCard(
              onTap: () {
                HapticFeedback.heavyImpact();
                _devService.deactivateDevMode();
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.lock_outline, color: Colors.white54),
              ),
            ),
        ],
      ),
      body: _devService.devModeEnabled ? _buildPanel() : _buildAuth(),
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
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Color(0xFFE50914), size: 44),
            ),
            const SizedBox(height: 24),
            const Text('Developer Access', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Enter access code to unlock developer options', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 8),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final success = _devService.authenticate(_codeController.text);
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid access code'), backgroundColor: Color(0xFFE50914)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Unlock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE50914).withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE50914).withAlpha(40)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber, color: Color(0xFFE50914), size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Developer mode active. Use with caution.', style: TextStyle(color: Color(0xFFE50914), fontSize: 13))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _card(
          'System Controls',
          [
            _toggle(Icons.construction, 'Maintenance Mode', _devService.maintenanceMode, (_) => _devService.toggleMaintenanceMode()),
            _toggle(Icons.visibility, 'Verbose Logging', _devService.verboseLogging, (_) => _devService.toggleVerboseLogging()),
            _toggle(Icons.fingerprint, 'Bypass Authentication', _devService.bypassAuth, (_) => _devService.toggleBypassAuth()),
            _toggle(Icons.speed, 'Show FPS Counter', _devService.showFps, (_) => _devService.toggleShowFps()),
          ],
        ),
        const SizedBox(height: 16),
        _card(
          'Quick Actions',
          [
            _action(Icons.refresh, 'Clear Cache', () {
              _devService.toggleMaintenanceMode();
              _devService.toggleMaintenanceMode();
              _showSnack('Cache cleared');
            }),
            _action(Icons.delete_sweep, 'Reset All Data', () {
              _devService.clearLogs();
              _showSnack('Data reset triggered');
            }),
            _action(Icons.wifi_off, 'Simulate Offline', () {
              _devService.toggleMaintenanceMode();
              _showSnack('Maintenance mode toggled');
            }),
            _action(Icons.bug_report, 'Force Crash Test', () {
              HapticFeedback.heavyImpact();
              _showSnack('Crash test initiated (simulated)');
            }),
          ],
        ),
        const SizedBox(height: 16),
        _card(
          'Event Log (${_devService.eventLog.length})',
          [
            if (_devService.eventLog.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No events logged', style: TextStyle(color: Colors.white38)),
              )
            else
              ...List.generate(_devService.eventLog.length, (i) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: i < _devService.eventLog.length - 1
                        ? const Border(bottom: BorderSide(color: Color(0xFF2A2A2A)))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _devService.eventLog[i],
                          style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 8),
            if (_devService.eventLog.isNotEmpty)
              Center(
                child: InteractiveCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _devService.clearLogs();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Clear Logs', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
      ),
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
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Switch(
        value: value,
        onChanged: (v) {
          HapticFeedback.lightImpact();
          onChanged(v);
        },
        activeTrackColor: const Color(0xFFE50914),
      ),
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
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }
}
