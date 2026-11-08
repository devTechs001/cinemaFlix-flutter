import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/plugin_service.dart';
import '../widgets/interactive_card.dart';

final _pluginService = pluginService;

class PluginsScreen extends StatefulWidget {
  const PluginsScreen({super.key});

  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen> {
  @override
  void initState() {
    super.initState();
    _pluginService.addListener(_onChanged);
  }

  @override
  void dispose() {
    _pluginService.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Plugins & Integrations', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_pluginService.connectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
                  ),
                  child: Text(
                    '${_pluginService.connectedCount} connected',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.extension, color: Color(0xFFE50914), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Connect your apps', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text('Link third-party services to extend CinemaFlix', style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_pluginService.connected.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text('CONNECTED', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ),
            ..._pluginService.connected.map((p) => _buildPluginCard(p)),
            const SizedBox(height: 20),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('AVAILABLE', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ),
          ..._pluginService.available.map((p) => _buildPluginCard(p)),
        ],
      ),
    );
  }

  Widget _buildPluginCard(Plugin plugin) {
    final isConnected = plugin.status == PluginStatus.connected;
    final isConnecting = plugin.status == PluginStatus.connecting;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InteractiveCard(
        onTap: isConnecting
            ? null
            : () {
                HapticFeedback.mediumImpact();
                if (isConnected) {
                  _showDisconnectDialog(plugin);
                } else {
                  _pluginService.connect(plugin.id);
                }
              },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isConnected
                  ? const Color(0xFF10B981).withAlpha(60)
                  : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: plugin.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(plugin.icon, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(plugin.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        if (isConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(plugin.description, style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12)),
                    if (plugin.permissions.isNotEmpty && isConnected) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: plugin.permissions.map((perm) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(perm, style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 10)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isConnecting)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE50914)),
                )
              else if (isConnected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.power_settings_new, color: Color(0xFFE50914), size: 18),
                )
              else
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisconnectDialog(Plugin plugin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(plugin.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text('Disconnect ${plugin.name}?', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'This will revoke all permissions. You can reconnect at any time.',
          style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              _pluginService.disconnect(plugin.id);
              Navigator.pop(ctx);
            },
            child: const Text('Disconnect', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
