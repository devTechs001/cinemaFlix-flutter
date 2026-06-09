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
  bool _dataSaver = false;
  bool _privateAccount = false;
  bool _parentalControls = false;
  bool _socialShare = true;
  bool _autoplayNext = true;
  bool _dolbyAtmos = false;
  bool _backgroundPlay = false;
  bool _gestureControls = true;
  String _streamingQuality = 'Auto';
  String _downloadQuality = 'HD';
  String _contentLanguage = 'English';
  double _cacheSize = 1.2;

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
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _section('Account'),
          _card(children: [
            _settingTile(Icons.person, 'Profile Settings', 'Manage your account', () => Navigator.pushNamed(context, '/main')),
            _settingTile(Icons.lock_outline, 'Privacy & Security', 'Password, 2FA, data', () => Navigator.pushNamed(context, '/recover')),
            _settingTile(Icons.email_outlined, 'Email Preferences', 'Notifications, updates', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email preferences coming soon'), duration: Duration(seconds: 1)),
              );
            }),
            _toggleTile(Icons.visibility_off, 'Private Account', _privateAccount, (v) => setState(() => _privateAccount = v)),
            _toggleTile(Icons.share, 'Social Sharing', _socialShare, (v) => setState(() => _socialShare = v)),
          ]),
          const SizedBox(height: 20),
          _section('Playback'),
          _card(children: [
            _toggleTile(Icons.hd, 'HD Streaming', _hdStreaming, (v) => setState(() => _hdStreaming = v)),
            _toggleTile(Icons.play_circle_outline, 'Auto-Play Trailers', _autoPlay, (v) => setState(() => _autoPlay = v)),
            _toggleTile(Icons.skip_next, 'Auto-Play Next Episode', _autoplayNext, (v) => setState(() => _autoplayNext = v)),
            _toggleTile(Icons.subtitles, 'Subtitles / CC', _subtitles, (v) => setState(() => _subtitles = v)),
            _toggleTile(Icons.surround_sound, 'Dolby Atmos', _dolbyAtmos, (v) => setState(() => _dolbyAtmos = v)),
            _toggleTile(Icons.music_video, 'Background Play', _backgroundPlay, (v) => setState(() => _backgroundPlay = v)),
            _toggleTile(Icons.touch_app, 'Gesture Controls', _gestureControls, (v) => setState(() => _gestureControls = v)),
            _selectTile(Icons.speed, 'Streaming Quality', _streamingQuality, ['Auto', 'SD', 'HD', 'Full HD', '4K UHD'], (v) => setState(() => _streamingQuality = v)),
          ]),
          const SizedBox(height: 20),
          _section('Data & Storage'),
          _card(children: [
            _toggleTile(Icons.wifi, 'Download on Wi-Fi Only', _downloadOnWifi, (v) => setState(() => _downloadOnWifi = v)),
            _toggleTile(Icons.auto_awesome, 'Smart Downloads', _smartDownloads, (v) => setState(() => _smartDownloads = v)),
            _toggleTile(Icons.data_saver_on, 'Data Saver Mode', _dataSaver, (v) => setState(() => _dataSaver = v)),
            _selectTile(Icons.download, 'Download Quality', _downloadQuality, ['SD', 'HD', 'Full HD'], (v) => setState(() => _downloadQuality = v)),
            _settingTile(Icons.download_outlined, 'Manage Downloads', '3 movies downloaded', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloads management'), duration: Duration(seconds: 1)),
              );
            }),
            _cacheTile(),
          ]),
          const SizedBox(height: 20),
          _section('Content'),
          _card(children: [
            _selectTile(Icons.language, 'Content Language', _contentLanguage, ['English', 'Spanish', 'French', 'German', 'Japanese', 'Korean', 'Chinese', 'Hindi', 'Portuguese', 'Arabic'], (v) => setState(() => _contentLanguage = v)),
            _toggleTile(Icons.family_restroom, 'Parental Controls', _parentalControls, (v) => setState(() => _parentalControls = v)),
            _settingTile(Icons.flag_outlined, 'Content Region', 'United States', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Region settings coming soon'), duration: Duration(seconds: 1)),
              );
            }),
          ]),
          const SizedBox(height: 20),
          _section('Permissions'),
          _card(children: [
            _permissionTile(Icons.camera_alt, 'Camera', _mediaService.cameraGranted, _mediaService.requestCamera),
            _permissionTile(Icons.photo_library, 'Photos', _mediaService.photosGranted, _mediaService.requestPhotos),
            _permissionTile(Icons.mic, 'Microphone', _mediaService.microphoneGranted, _mediaService.requestMicrophone),
            _permissionTile(Icons.storage, 'Storage', _mediaService.storageGranted, _mediaService.requestStorage),
            _permissionTile(Icons.contacts, 'Contacts', false, () async {
              await Permission.contacts.request();
              setState(() {});
              return true;
            }),
            _permissionTile(Icons.notifications, 'Notifications', true, () async => true),
          ]),
          const SizedBox(height: 20),
          _section('Notifications'),
          _card(children: [
            _toggleTile(Icons.notifications_outlined, 'Push Notifications', _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
            _settingTile(Icons.movie_outlined, 'Movie Alerts', 'New releases, trending', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Movie alert settings'), duration: Duration(seconds: 1)),
              );
            }),
            _settingTile(Icons.chat_outlined, 'Chat Notifications', 'Messages, replies, mentions', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat notification settings'), duration: Duration(seconds: 1)),
              );
            }),
            _settingTile(Icons.favorite_outline, 'Social Alerts', 'Likes, follows, gifts', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Social alert settings'), duration: Duration(seconds: 1)),
              );
            }),
            _settingTile(Icons.live_tv_outlined, 'Live Stream Alerts', 'When favorite creators go live', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live stream settings'), duration: Duration(seconds: 1)),
              );
            }),
          ]),
          const SizedBox(height: 20),
          _section('Accessibility'),
          _card(children: [
            _toggleTile(Icons.closed_caption, 'Closed Captions', _subtitles, (v) => setState(() => _subtitles = v)),
            _settingTile(Icons.text_fields, 'Font Size', 'Default', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Font size settings'), duration: Duration(seconds: 1)),
              );
            }),
            _settingTile(Icons.palette, 'High Contrast Mode', 'Off', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Accessibility settings'), duration: Duration(seconds: 1)),
              );
            }),
          ]),
          const SizedBox(height: 20),
          _section('App Info'),
          _card(children: [
            _updateTile(),
            _settingTile(Icons.share, 'Share App', 'Share CinemaFlix with friends', _shareApp),
            _settingTile(Icons.download, 'Download Hub', 'Get CinemaFlix for other devices', _showDownloadLinks),
            _settingTile(Icons.storage_outlined, 'Backup & Restore', 'Sync your data across devices', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup & restore'), duration: Duration(seconds: 1)),
              );
            }),
            _infoTile('Version', _version),
            _infoTile('Build', _buildNumber),
            _infoTile('Platform', Theme.of(context).platform.name.toUpperCase()),
            _settingTile(Icons.devices, 'Connected Devices', 'Manage devices & sync', () => Navigator.pushNamed(context, '/devices')),
            _settingTile(Icons.code, 'Developer Options', 'Advanced settings', () => Navigator.pushNamed(context, '/dev-panel')),
            _dangerTile(Icons.delete_forever, 'Delete Account', 'Permanently remove all data', _showDeleteAccountDialog),
          ]),
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text('This will permanently delete your account, watch history, reviews, and all data. This action cannot be undone.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion requested. Check your email to confirm.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
            leading: Icon(update != null ? Icons.system_update_alt : Icons.update, color: update != null ? const Color(0xFFE50914) : Colors.white54, size: 22),
            title: Text(update != null ? 'Update Available: v${update.version}' : 'Check for Updates', style: TextStyle(color: update != null ? const Color(0xFFE50914) : Colors.white, fontSize: 15, fontWeight: update != null ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text(isChecking ? 'Checking for updates...' : (update != null ? 'Tap to view details' : 'Last checked: Today'), style: const TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: isChecking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)) : const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later', style: TextStyle(color: Colors.white38))),
          ElevatedButton(onPressed: () { Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)), child: const Text('Update Now', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _cacheTile() {
    return InteractiveCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/cache-cleaner');
      },
      child: ListTile(
        leading: const Icon(Icons.cleaning_services, color: Colors.white54, size: 22),
        title: const Text('Clear Cache', style: TextStyle(color: Colors.white, fontSize: 15)),
        subtitle: Text('${_cacheSize.toStringAsFixed(1)} GB \u2022 Tap to manage', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
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
      decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
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
        onChanged: (v) { HapticFeedback.lightImpact(); onChanged(v); },
        activeTrackColor: const Color(0xFFE50914),
      ),
    );
  }

  Widget _selectTile(IconData icon, String title, String value, List<String> options, ValueChanged<String> onChanged) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1F1F1F),
          underline: const SizedBox(),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.expand_more, color: Colors.white38, size: 18),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) { if (v != null) { HapticFeedback.selectionClick(); onChanged(v); } },
        ),
      ),
    );
  }

  Widget _permissionTile(IconData icon, String title, bool granted, Future<bool> Function() onRequest) {
    return ListTile(
      leading: Icon(icon, color: granted ? const Color(0xFF43A047) : Colors.white38, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: InteractiveCard(
        onTap: () async { HapticFeedback.lightImpact(); await onRequest(); setState(() {}); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: granted ? const Color(0xFF43A047).withAlpha(30) : const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
          child: Text(granted ? 'Granted' : 'Allow', style: TextStyle(color: granted ? const Color(0xFF43A047) : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _dangerTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: Colors.red, size: 22),
        title: Text(title, style: const TextStyle(color: Colors.red, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.red.withAlpha(120), fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.red, size: 20),
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
