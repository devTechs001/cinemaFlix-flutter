import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/interactive_card.dart';
import '../services/media_service.dart';
import '../services/globals.dart';

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

  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

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
              _settingTile(Icons.person, 'Profile Settings', 'Manage your account', () => Navigator.pushNamed(context, '/main')),
              _settingTile(Icons.lock_outline, 'Privacy & Security', 'Password, data', () => Navigator.pushNamed(context, '/recover')),
              _settingTile(Icons.email_outlined, 'Email Preferences', 'Notifications, updates', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email preferences coming soon'), duration: Duration(seconds: 1)),
                );
              }),
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
              _settingTile(Icons.download_outlined, 'Manage Downloads', '3 movies downloaded', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloads management'), duration: Duration(seconds: 1)),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),
          _section('Notifications'),
          _card(
            children: [
              _toggleTile(Icons.notifications_outlined, 'Push Notifications', _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
              _settingTile(Icons.movie_outlined, 'Movie Alerts', 'New releases, trending', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Movie alerts settings'), duration: Duration(seconds: 1)),
                );
              }),
              _settingTile(Icons.chat_outlined, 'Chat Notifications', 'Messages, replies', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat notification settings'), duration: Duration(seconds: 1)),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),
          _section('App Info'),
          _card(
            children: [
              _updateTile(),
              _settingTile(Icons.share, 'Share App', 'Share CinemaFlix with friends', _shareApp),
              _settingTile(Icons.download, 'Download Hub', 'Get CinemaFlix for other devices', _showDownloadLinks),
              _infoTile('Version', _version),
              _infoTile('Build', _buildNumber),
              _infoTile('Platform', Theme.of(context).platform.name.toUpperCase()),
              _settingTile(Icons.code, 'Developer Options', 'Advanced settings', () => Navigator.pushNamed(context, '/dev-panel')),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _shareApp() {
    HapticFeedback.mediumImpact();
    Share.share(
      '🎬 Watch the latest movies and live streams on CinemaFlix! Download now: https://cinemaflix.app/download',
      subject: 'Join me on CinemaFlix!',
    );
  }

  void _showDownloadLinks() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Download CinemaFlix', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _downloadItem(Icons.android, 'Android APK', 'Download direct installer'),
            _downloadItem(Icons.apple, 'iOS App Store', 'Install from App Store'),
            _downloadItem(Icons.laptop, 'Windows / macOS', 'Desktop version'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _downloadItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Starting $title download...'), duration: const Duration(seconds: 2)),
        );
      },
    );
  }

  Widget _updateTile() {
    return ListenableBuilder(
      listenable: updateService,
      builder: (context, _) {
        final update = updateService.latestUpdate;
        final isChecking = updateService.isChecking;

        return InteractiveCard(
          onTap: () async {
            if (isChecking) return;
            HapticFeedback.mediumImpact();
            final hasUpdate = await updateService.checkForUpdates();
            if (!hasUpdate && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Your app is up to date!'), duration: Duration(seconds: 2)),
              );
            } else if (hasUpdate && mounted) {
              _showUpdateDialog();
            }
          },
          child: ListTile(
            leading: Icon(
              update != null ? Icons.system_update_alt : Icons.update,
              color: update != null ? const Color(0xFFE50914) : Colors.white54,
              size: 22,
            ),
            title: Text(
              update != null ? 'Update Available: v${update.version}' : 'Check for Updates',
              style: TextStyle(
                color: update != null ? const Color(0xFFE50914) : Colors.white,
                fontSize: 15,
                fontWeight: update != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              isChecking ? 'Checking for updates...' : (update != null ? 'Tap to view details' : 'Last checked: Today'),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            trailing: isChecking
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38))
                : const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ),
        );
      },
    );
  }

  void _showUpdateDialog() {
    final update = updateService.latestUpdate;
    if (update == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text('New Update: v${update.version}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Release Notes:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(update.releaseNotes, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading update...'), duration: Duration(seconds: 2)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            child: const Text('Update Now', style: TextStyle(color: Colors.white)),
          ),
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
