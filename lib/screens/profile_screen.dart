import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/globals.dart';
import '../widgets/interactive_card.dart';
import '../widgets/app_logo.dart';
import '../models/sample_movies.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: authService.currentUser?.username ?? 'Cinema Fan');
    _bioController = TextEditingController(text: 'Movie enthusiast 🎬 | 100+ films watched');
    authService.addListener(_onAuthChange);
  }

  void _onAuthChange() {
    if (mounted) {
      setState(() {
        _nameController.text = authService.currentUser?.username ?? 'Cinema Fan';
      });
    }
  }

  @override
  void dispose() {
    authService.removeListener(_onAuthChange);
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          InteractiveCard(
            onTap: () async {
              HapticFeedback.mediumImpact();
              if (_isEditing && authService.currentUser != null) {
                await authService.updateProfile(username: _nameController.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated'), duration: Duration(seconds: 1)),
                );
              }
              setState(() => _isEditing = !_isEditing);
            },
            scaleAmount: 0.88,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(_isEditing ? Icons.check : Icons.edit_outlined, color: Colors.white54),
            ),
          ),
          InteractiveCard(
            onTap: () {
              HapticFeedback.lightImpact();
              showDialog(
                context: context,
                builder: (_) => _buildSettingsDialog(context),
              );
            },
            scaleAmount: 0.88,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.settings_outlined, color: Colors.white54),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xFFE50914).withAlpha(30),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF2A2A2A),
                    child: _isEditing
                        ? IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white38, size: 28),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Camera/gallery picker coming soon'), duration: Duration(seconds: 1)),
                              );
                            },
                          )
                        : const Icon(Icons.person, size: 48, color: Color(0xFFE50914)),
                  ),
                ),
                Positioned(
                  bottom: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF43A047),
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: Color(0xFF141414), width: 2)),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE50914))),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE50914))),
                  ),
                ),
              )
            else
              Text(
                _nameController.text,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            const SizedBox(height: 4),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _bioController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Your bio',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE50914))),
                  ),
                ),
              )
            else
              Text(_bioController.text, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 28),
            _buildSectionTitle('Your Activity'),
            const SizedBox(height: 8),
            ...List.generate(
              sampleMovies.take(3).toList().asMap().entries.length,
              (i) {
                final entry = sampleMovies.take(3).toList().asMap().entries.elementAt(i);
                final movie = entry.value;
                return InteractiveCard(
                  onTap: () => Navigator.pushNamed(context, '/movie-detail', arguments: movie),
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [movie.gradientStart, movie.gradientEnd]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle_outline, color: Colors.white38, size: 22),
                    ),
                    title: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: Text('Watched • ★ ${movie.rating}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (star) {
                        return Icon(
                          star < 4 ? Icons.star : Icons.star_border,
                          color: star < 4 ? Colors.amber : Colors.white24,
                          size: 16,
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 8),
            _buildSectionTitle('Account'),
            _buildMenuTile(Icons.settings_outlined, 'Settings', 'App preferences', () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, '/settings');
            }),
            _buildMenuTile(Icons.palette_outlined, 'Themes', 'Customize look', () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, '/themes');
            }),
            _buildMenuTile(Icons.history_rounded, 'Activity Records', 'Watch history & more', () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, '/records');
            }),
            _buildMenuTile(Icons.card_giftcard_outlined, 'Gifting', 'Send movies to friends', () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, '/gifting');
            }),
            _buildMenuTile(Icons.notifications_outlined, 'Notifications', 'Push & email', () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/notifications');
            }),
            _buildMenuTile(Icons.download_outlined, 'Downloads', '3 movies offline', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloads management'), duration: Duration(seconds: 1)),
              );
            }),
            _buildMenuTile(Icons.language, 'Language', 'English', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon'), duration: Duration(seconds: 1)),
              );
            }),
            _buildMenuTile(Icons.admin_panel_settings_outlined, 'Dev Panel', 'Developer options', () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, '/dev-panel');
            }),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            _buildMenuTile(Icons.logout, 'Sign Out', '', () {
              HapticFeedback.heavyImpact();
              showDialog(context: context, builder: (_) => _buildSignOutDialog(context));
            }, isDanger: true),
            const SizedBox(height: 40),
            const AppLogo(size: 32, showText: false),
            const SizedBox(height: 6),
            const Text('CinemaFlix v1.0', style: TextStyle(color: Colors.white24, fontSize: 12)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(Icons.visibility, 'Watched', '34'),
            _buildDivider(),
            _buildStatItem(Icons.bookmark, 'Watchlist', '12'),
            _buildDivider(),
            _buildStatItem(Icons.star, 'Reviews', '8'),
            _buildDivider(),
            _buildStatItem(Icons.favorite, 'Favorites', '16'),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: Colors.white12);
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFE50914), size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDanger = false}) {
    return InteractiveCard(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: isDanger ? Colors.red : Colors.white54, size: 22),
        title: Text(title, style: TextStyle(color: isDanger ? Colors.red : Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      ),
    );
  }

  Widget _buildSettingsDialog(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            _settingsTile(Icons.wifi, 'Wi-Fi Only Streaming', true),
            _settingsTile(Icons.download, 'Auto-download Watchlist', false),
            _settingsTile(Icons.hd, 'HD Streaming', true),
            _settingsTile(Icons.subtitles, 'Subtitles', true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Switch(
            value: value,
            onChanged: (_) => HapticFeedback.lightImpact(),
            activeThumbColor: const Color(0xFFE50914),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutDialog(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            const Text('Sign Out', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      authService.signOut();
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/auth');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
