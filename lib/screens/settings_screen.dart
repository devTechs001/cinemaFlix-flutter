import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/interactive_card.dart';
import '../services/media_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _mediaService = MediaService();
  bool _hdStreaming = true;
  bool _autoPlay = true;
  bool _downloadOnWifi = true;
  bool _subtitles = true;
  bool _notificationsEnabled = true;
  bool _smartDownloads = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _section('Account'),
          _card(
            children: [
              _settingTile(Icons.person, 'Profile Settings', 'Manage your account', () => HapticFeedback.lightImpact()),
              _settingTile(Icons.lock_outline, 'Privacy & Security', 'Password, data', () => Navigator.pushNamed(context, '/recover')),
              _settingTile(Icons.email_outlined, 'Email Preferences', 'Notifications, updates', () => HapticFeedback.lightImpact()),
            ],
          ),
          const SizedBox(height: 20),
          _section('Permissions'),
          _card(
            children: [
              _permissionTile(Icons.camera_alt, 'Camera', _mediaService.cameraGranted, _mediaService.requestCamera),
              _permissionTile(Icons.photo_library, 'Photos', _mediaService.photosGranted, _mediaService.requestPhotos),
              _permissionTile(Icons.mic, 'Microphone', _mediaService.microphoneGranted, _mediaService.requestMicrophone),
              _permissionTile(Icons.storage, 'Storage', _mediaService.storageGranted, _mediaService.requestStorage),
              _permissionTile(Icons.contacts, 'Contacts', false, () async {
                await Permission.contacts.request();
                setState(() {});
                return true;
              }),
            ],
          ),
          const SizedBox(height: 20),
          _section('Playback'),
          _card(
            children: [
              _toggleTile(Icons.hd, 'HD Streaming', _hdStreaming, (v) => setState(() => _hdStreaming = v)),
              _toggleTile(Icons.play_circle_outline, 'Auto-Play Trailers', _autoPlay, (v) => setState(() => _autoPlay = v)),
              _toggleTile(Icons.subtitles, 'Subtitles', _subtitles, (v) => setState(() => _subtitles = v)),
            ],
          ),
          const SizedBox(height: 20),
          _section('Downloads'),
          _card(
            children: [
              _toggleTile(Icons.wifi, 'Download on Wi-Fi Only', _downloadOnWifi, (v) => setState(() => _downloadOnWifi = v)),
              _toggleTile(Icons.auto_awesome, 'Smart Downloads', _smartDownloads, (v) => setState(() => _smartDownloads = v)),
              _settingTile(Icons.download_outlined, 'Manage Downloads', '3 movies downloaded', () => HapticFeedback.lightImpact()),
            ],
          ),
          const SizedBox(height: 20),
          _section('Notifications'),
          _card(
            children: [
              _toggleTile(Icons.notifications_outlined, 'Push Notifications', _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
              _settingTile(Icons.movie_outlined, 'Movie Alerts', 'New releases, trending', () => HapticFeedback.lightImpact()),
              _settingTile(Icons.chat_outlined, 'Chat Notifications', 'Messages, replies', () => HapticFeedback.lightImpact()),
            ],
          ),
          const SizedBox(height: 20),
          _section('About'),
          _card(
            children: [
              _infoTile('Version', '1.0.0'),
              _infoTile('Build', '2024.06.08'),
              _infoTile('Platform', Theme.of(context).platform.name.toUpperCase()),
              _settingTile(Icons.code, 'Developer Options', 'Advanced settings', () => Navigator.pushNamed(context, '/dev-panel')),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: Colors.white54, size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      ),
    );
  }

  Widget _toggleTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
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

  Widget _permissionTile(IconData icon, String title, bool granted, Future<bool> Function() onRequest) {
    return ListTile(
      leading: Icon(icon, color: granted ? const Color(0xFF43A047) : Colors.white38, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: InteractiveCard(
        onTap: () async {
          HapticFeedback.lightImpact();
          await onRequest();
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: granted ? const Color(0xFF43A047).withAlpha(30) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            granted ? 'Granted' : 'Allow',
            style: TextStyle(
              color: granted ? const Color(0xFF43A047) : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}
