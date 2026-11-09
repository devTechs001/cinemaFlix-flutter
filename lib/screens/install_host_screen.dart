import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/interactive_card.dart';
import '../services/globals.dart';
import '../services/update_service.dart';

class InstallHostScreen extends StatefulWidget {
  const InstallHostScreen({super.key});

  @override
  State<InstallHostScreen> createState() => _InstallHostScreenState();
}

class _InstallHostScreenState extends State<InstallHostScreen> {
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
    await updateService.checkForUpdates();
    if (mounted) setState(() {});
  }

  Future<void> _download(String label, UpdateAsset asset, {bool install = false}) async {
    HapticFeedback.mediumImpact();
    final path = await updateService.downloadAsset(asset);
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(updateService.error ?? 'Download failed')),
      );
      return;
    }
    notificationService.notifyDownload(
      title: '$label downloaded',
      body: path.split(RegExp(r'[/\\]')).last,
      onTap: () => updateService.installLocalFile(path),
    );
    if (install) {
      final ok = await updateService.installLocalFile(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Opening installer…' : 'Saved to $path')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded ${asset.name}')),
      );
    }
  }

  UpdateAsset _assetFor(String label) {
    final info = updateService.latestUpdate;
    final assets = info?.assets ?? const <UpdateAsset>[];
    bool match(UpdateAsset a, List<String> keys) {
      final n = a.name.toLowerCase();
      return keys.any(n.contains);
    }
    switch (label) {
      case 'Android':
        for (final a in assets) {
          if (a.isApk) return a;
        }
        break;
      case 'iOS':
        for (final a in assets) {
          if (a.isIpa) return a;
        }
        break;
      case 'Windows':
        for (final a in assets) {
          if (a.isExe || match(a, ['windows', '.ps1'])) return a;
        }
        break;
      case 'macOS':
        for (final a in assets) {
          if (a.isMac) return a;
        }
        break;
      case 'Linux':
        for (final a in assets) {
          if (a.isLinux || match(a, ['linux', '.sh'])) return a;
        }
        break;
    }
    return UpdateService.sourceZipAsset;
  }

  Future<void> _shareInstall(String label, String url) async {
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: url));
    await Share.share('Install CinemaFlix ($label)\n$url\n\nSource: ${UpdateService.repoUrl}');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label link copied and ready to share'), duration: const Duration(seconds: 2)),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF141414),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Install & Host',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              centerTitle: true,
            ),
            SliverToBoxAdapter(
              child: _header(),
            ),
            SliverToBoxAdapter(
              child: _section('Installation'),
            ),
            SliverToBoxAdapter(
              child: _installCards(),
            ),
            SliverToBoxAdapter(
              child: _section('Hosting Services'),
            ),
            SliverToBoxAdapter(
              child: _hostingCards(),
            ),
            SliverToBoxAdapter(
              child: _section('Updates'),
            ),
            SliverToBoxAdapter(
              child: _updateCard(),
            ),
            SliverToBoxAdapter(
              child: _versionInfo(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE50914), Color(0xFFB20710)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.dashboard_customize, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CinemaFlix Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share a GitHub build • update from the latest release',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _installCards() {
    return ListenableBuilder(
      listenable: updateService,
      builder: (context, _) {
        return Column(
          children: [
            _installCard(
              Icons.android,
              'Android APK',
              'Download the APK from GitHub and install it on the device',
              'Android',
            ),
            _installCard(
              Icons.apple,
              'iOS / macOS',
              'Download the macOS installer or source build',
              'macOS',
            ),
            _installCard(
              Icons.laptop_windows,
              'Windows',
              'Download the Windows installer script from the latest release',
              'Windows',
            ),
            _installCard(
              Icons.terminal,
              'Linux',
              'Download install-linux.sh and run it to pull the latest build',
              'Linux',
            ),
            _installCard(
              Icons.folder,
              'Source zip',
              'Direct download of the main branch (always available)',
              'Source',
            ),
            if (updateService.isDownloading) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: updateService.updateProgress == 0 ? null : updateService.updateProgress,
                        backgroundColor: Colors.white10,
                        color: const Color(0xFFE50914),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Downloading… ${(updateService.updateProgress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _installCard(IconData icon, String title, String description, String label) {
    final asset = _assetFor(label);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFE50914), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(description, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(asset.name, style: const TextStyle(color: Color(0xFFE50914), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: updateService.isDownloading ? null : () => _download(label, asset),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: updateService.isDownloading ? null : () => _download(label, asset, install: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.build, size: 16),
                  label: const Text('Install', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              IconButton(
                tooltip: 'Share link',
                onPressed: () => _shareInstall(label, asset.url),
                icon: const Icon(Icons.share, color: Colors.white54, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hostingCards() {
    return Column(
      children: [
        _hostingCard(
          Icons.cloud_outlined,
          'Cloud Hosting',
          'Pre-configured hosted backend. Zero maintenance, auto-scaling, and 99.9% uptime SLA.',
          Icons.arrow_forward_ios,
        ),
        _hostingCard(
          Icons.developer_mode,
          'Self-Hosted',
          'Deploy with Docker on your own infrastructure. Full control over your data and stack.',
          Icons.arrow_forward_ios,
        ),
        _hostingCard(
          Icons.business_center_outlined,
          'Enterprise',
          'Dedicated infrastructure with custom integration, white-labeling, and priority support.',
          Icons.arrow_forward_ios,
        ),
      ],
    );
  }

  Widget _hostingCard(IconData icon, String title, String description, IconData trailing) {
    return InteractiveCard(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white54, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(trailing, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _updateCard() {
    return ListenableBuilder(
      listenable: updateService,
      builder: (context, _) {
        final isChecking = updateService.isChecking;
        final autoUpdate = updateService.autoUpdate;
        final lastChecked = updateService.lastChecked;
        final progress = updateService.updateProgress;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.update, color: Color(0xFFE50914), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Auto-Update',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: autoUpdate,
                    onChanged: (v) {
                      HapticFeedback.lightImpact();
                      updateService.autoUpdate = v;
                    },
                    activeTrackColor: const Color(0xFFE50914),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    autoUpdate ? Icons.check_circle : Icons.error_outline,
                    size: 14,
                    color: autoUpdate ? const Color(0xFF43A047) : Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    autoUpdate ? 'Automatic updates enabled' : 'Manual updates only',
                    style: TextStyle(
                      color: autoUpdate ? const Color(0xFF43A047) : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (lastChecked != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.white24),
                    const SizedBox(width: 6),
                    Text(
                      'Last checked: ${_formatTime(lastChecked)}',
                      style: const TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              if (isChecking) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withAlpha(15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Checking for updates... ${(progress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ] else ...[
                InteractiveCard(
                  onTap: () async {
                    if (isChecking) return;
                    HapticFeedback.mediumImpact();
                    final hasUpdate = await updateService.checkForUpdates();
                    if (hasUpdate && mounted) {
                      notificationService.notifyUpdate(
                        version: updateService.latestUpdate?.version ?? '',
                        onTap: _showUpdateDialog,
                      );
                      _showUpdateDialog();
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Your app is up to date!'), duration: Duration(seconds: 2)),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Check Now',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
              if (updateService.latestUpdate != null && !isChecking) ...[
                const SizedBox(height: 10),
                InteractiveCard(
                  onTap: _showUpdateDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE50914).withAlpha(80)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.system_update_alt, color: Color(0xFFE50914), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Update v${updateService.latestUpdate!.version} Available',
                            style: const TextStyle(color: Color(0xFFE50914), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
            onPressed: () async {
              Navigator.pop(context);
              final ok = await updateService.downloadAndInstall();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Opening installer…' : (updateService.error ?? 'Download failed')),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            child: const Text('Download & install', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _versionInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Current Version',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Text(
            'v$_version ($_buildNumber)',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
