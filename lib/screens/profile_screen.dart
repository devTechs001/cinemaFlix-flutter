import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/globals.dart';
import '../services/sound_service.dart' show SoundEvent;
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
  int _sectionIndex = 0; // pinned section nav: Overview/Library/Activity/Account
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _websiteController;
  late final TextEditingController _locationController;
  String _selectedLanguage = 'English';
  String _avatarEmoji = '';

  int _userLevel = 12;
  double _xpProgress = 0.65;
  final List<SampleMovie> _continueWatching = sampleMovies.take(4).toList();

  final List<Map<String, dynamic>> _badges = [
    {'icon': Icons.movie, 'label': 'Film Buff', 'unlocked': true, 'desc': 'Watch 50 movies'},
    {'icon': Icons.star, 'label': 'Top Critic', 'unlocked': true, 'desc': 'Write 10 reviews'},
    {'icon': Icons.favorite, 'label': 'Romantic', 'unlocked': true, 'desc': 'Watch 20 romance films'},
    {'icon': Icons.whatshot, 'label': 'Trending', 'unlocked': true, 'desc': 'Get 100 likes'},
    {'icon': Icons.emoji_events, 'label': 'Champion', 'unlocked': false, 'desc': 'Win a contest'},
    {'icon': Icons.explore, 'label': 'Explorer', 'unlocked': false, 'desc': 'Browse 30 genres'},
    {'icon': Icons.group, 'label': 'Social', 'unlocked': true, 'desc': 'Follow 10 friends'},
    {'icon': Icons.video_library, 'label': 'Collector', 'unlocked': false, 'desc': 'Save 50 movies'},
    {'icon': Icons.chat, 'label': 'Talker', 'unlocked': false, 'desc': 'Send 100 messages'},
    {'icon': Icons.diamond, 'label': 'Big Spender', 'unlocked': false, 'desc': 'Spend 1000 diamonds'},
    {'icon': Icons.share, 'label': 'Influencer', 'unlocked': false, 'desc': 'Share 10 movies'},
    {'icon': Icons.nights_stay, 'label': 'Night Owl', 'unlocked': false, 'desc': 'Watch after midnight'},
  ];

  final List<Map<String, dynamic>> _suggestedFriends = [
    {'name': 'Sarah J.', 'avatar': '🎬', 'common': '12 mutual movies'},
    {'name': 'Mike R.', 'avatar': '🎮', 'common': '8 mutual movies'},
    {'name': 'Emma W.', 'avatar': '🎨', 'common': '5 mutual movies'},
    {'name': 'Alex K.', 'avatar': '📚', 'common': '15 mutual movies'},
  ];

  final List<Map<String, dynamic>> _recentActivity = [
    {'type': 'watched', 'text': 'Watched Dune: Part Two', 'time': '2h ago', 'icon': Icons.check_circle},
    {'type': 'review', 'text': 'Reviewed Oppenheimer ★★★★★', 'time': '4h ago', 'icon': Icons.rate_review},
    {'type': 'liked', 'text': 'Liked a post in Social Feed', 'time': '6h ago', 'icon': Icons.favorite},
    {'type': 'gift', 'text': 'Sent Gift Card to Lisa', 'time': '1d ago', 'icon': Icons.card_giftcard},
    {'type': 'badge', 'text': 'Unlocked Film Buff badge!', 'time': '2d ago', 'icon': Icons.emoji_events},
  ];

  final _ratingDistribution = [12, 25, 38, 52, 45];

  final List<SampleMovie> _favoriteMovies = sampleMovies.take(4).toList();
  final List<SampleMovie> _watchlistMovies = sampleMovies.skip(2).take(6).toList();

  final List<Map<String, dynamic>> _sampleReviews = [
    {'movie': sampleMovies[0], 'rating': 4.5, 'content': 'Absolutely stunning visual masterpiece. Denis Villeneuve outdid himself with the scale and emotion.', 'date': '2 weeks ago'},
    {'movie': sampleMovies[1], 'rating': 5.0, 'content': 'A gripping and intense character study. Cillian Murphy delivers a career-defining performance.', 'date': '1 month ago'},
    {'movie': sampleMovies[4], 'rating': 4.0, 'content': 'Anya Taylor-Joy commands every scene. Prequel done right with incredible action set pieces.', 'date': '3 months ago'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: authService.currentUser?.username ?? 'Cinema Fan');
    _bioController = TextEditingController(text: 'Movie enthusiast 🎬 | 100+ films watched');
    _websiteController = TextEditingController(text: '');
    _locationController = TextEditingController(text: '');
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
    _websiteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showAvatarPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Change Profile Picture', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _avatarOption(Icons.camera_alt, 'Camera', () {
                  Navigator.pop(ctx);
                  setState(() => _avatarEmoji = '📸');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera opened'), duration: Duration(seconds: 1)),
                  );
                }),
                _avatarOption(Icons.photo_library, 'Gallery', () {
                  Navigator.pop(ctx);
                  setState(() => _avatarEmoji = '🖼️');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo selected'), duration: Duration(seconds: 1)),
                  );
                }),
                _avatarOption(Icons.emoji_emotions, 'Avatar', () {
                  Navigator.pop(ctx);
                  setState(() => _avatarEmoji = '😎');
                }),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _avatarOption(Icons.delete_outline, 'Remove', () {
                  Navigator.pop(ctx);
                  setState(() => _avatarEmoji = '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile picture removed'), duration: Duration(seconds: 1)),
                  );
                }),
                const SizedBox(width: 52),
                const SizedBox(width: 52),
                const SizedBox(width: 52),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _avatarOption(IconData icon, String label, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      scaleAmount: 0.88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white70, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    HapticFeedback.lightImpact();
    const languages = ['English', 'Español', 'Français', 'Deutsch', 'Italiano', 'Português', '日本語', '한국어', '中文', 'Русский'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 32, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select Language', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: languages.length,
              itemBuilder: (_, i) {
                final lang = languages[i];
                final isSelected = lang == _selectedLanguage;
                return ListTile(
                  title: Text(lang, style: TextStyle(color: isSelected ? const Color(0xFFE50914) : Colors.white)),
                  trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFE50914)) : null,
                  onTap: () {
                    setState(() => _selectedLanguage = lang);
                    Navigator.pop(ctx);
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Language changed to $lang'), duration: const Duration(seconds: 1)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (guestService.isGuest || authService.currentUser == null) {
      return _buildGuestProfile();
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              InteractiveCard(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _toggleEdit();
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
            // Modern pinned section nav — stays visible while scrolling.
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _buildSectionNavBar(),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoverBanner(),
                _buildProfileHeader(),
                const SizedBox(height: 16),
                _buildSectionBody(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pinned section nav bar: Overview · Library · Activity · Account.
  Widget _buildSectionNavBar() {
    const labels = ['Overview', 'Library', 'Activity', 'Account'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _sectionIndex = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _sectionIndex == i
                            ? const Color(0xFFE50914)
                            : const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _sectionIndex == i
                              ? const Color(0xFFE50914)
                              : const Color(0xFF2A2A2A),
                        ),
                      ),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _sectionIndex == i ? Colors.white : Colors.white60,
                          fontSize: 12.5,
                          fontWeight:
                              _sectionIndex == i ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The four section bodies — same content as the old single scroll,
  /// grouped behind the nav bar for a cleaner, modern profile.
  Widget _buildSectionBody() {
    switch (_sectionIndex) {
      case 1: // Library
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Favorites'),
            const SizedBox(height: 8),
            _buildFavoritesGrid(),
            const SizedBox(height: 28),
            _buildSectionTitle('Watchlists'),
            const SizedBox(height: 8),
            _buildWatchlists(),
            const SizedBox(height: 28),
            _buildSectionTitle('Reviews by You'),
            _buildReviewsByYou(),
            const SizedBox(height: 28),
            _buildSectionTitle('Lists'),
            const SizedBox(height: 8),
            _buildLists(),
            const SizedBox(height: 28),
            _buildFooter(),
          ],
        );
      case 2: // Activity
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Friend Suggestions'),
            const SizedBox(height: 8),
            _buildFriendSuggestions(),
            const SizedBox(height: 28),
            _buildSectionTitle('Recent Activity'),
            const SizedBox(height: 8),
            _buildRecentActivity(),
            const SizedBox(height: 28),
            _buildSectionTitle('Your Activity'),
            const SizedBox(height: 8),
            ..._buildWatchedListTiles(),
            const SizedBox(height: 28),
            _buildFooter(),
          ],
        );
      case 3: // Account
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 8),
            _buildSectionTitle('Account'),
            _buildMenuTile(Icons.videocam_outlined, 'Creator Hub', 'Manage your content & earnings', () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, '/creator-hub');
            }),
            if (featureFlagsService.isEnabled('ecommerce'))
              _buildMenuTile(Icons.storefront, 'Marketplace', 'Shop & sell — admin-approved', () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/ecommerce');
              }),
            _buildMenuTile(Icons.account_balance_wallet, 'Wallet', 'Diamonds & points', () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/wallet');
            }),
            if (featureFlagsService.isEnabled('live'))
              _buildMenuTile(Icons.live_tv_rounded, 'Live Rooms', 'Host & watch together', () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/live');
              }),
            _buildMenuTile(Icons.lock_outline, 'Vault', 'Private collection', () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/vault');
            }),
            _buildMenuTile(Icons.group_work, 'Watch Party', 'Sync watches with friends', () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/watch-party', arguments: {'movieId': '', 'movieTitle': 'Watch Party'});
            }),
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
            _buildMenuTile(Icons.language, 'Language', _selectedLanguage, _showLanguagePicker),
            _buildMenuTile(Icons.favorite_border, 'Dating Profile', 'Find movie matches', () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, '/dating');
            }),
            _buildMenuTile(Icons.person_add_outlined, 'Invite Friends', 'Share with friends', () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite link copied!'), duration: Duration(seconds: 1)),
              );
            }),
            _buildMenuTile(Icons.help_outline, 'Help & Support', 'FAQs & contact', () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support'), duration: Duration(seconds: 1)),
              );
            }),
            if (authService.currentUser?.isAdmin ?? false)
              _buildMenuTile(Icons.admin_panel_settings_outlined, 'Dev Panel', 'Developer options', () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(context, '/dev-panel');
              }),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            _buildMenuTile(Icons.logout, 'Sign Out', '', () {
              HapticFeedback.heavyImpact();
              showDialog(context: context, builder: (_) => _buildSignOutDialog(context));
            }, isDanger: true),
            const SizedBox(height: 8),
            _buildFooter(),
          ],
        );
      default: // Overview
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAchievementBadges(),
            const SizedBox(height: 20),
            _buildAnimatedStatRow(),
            const SizedBox(height: 20),
            _buildLevelBar(),
            const SizedBox(height: 24),
            _buildSectionTitle('Continue Watching'),
            const SizedBox(height: 8),
            _buildContinueWatching(),
            const SizedBox(height: 28),
            _buildSectionTitle('Rating Distribution'),
            const SizedBox(height: 8),
            _buildRatingChart(),
            const SizedBox(height: 28),
            _buildFooter(),
          ],
        );
    }
  }

  /// "Your Activity" watched-movie tiles (moved from the old flat list).
  List<Widget> _buildWatchedListTiles() {
    final movies = sampleMovies.take(3).toList();
    return List.generate(
      movies.length,
      (i) {
        final movie = movies[i];
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
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const SizedBox(height: 4),
        const AppLogo(size: 32, showText: false),
        const SizedBox(height: 6),
        const Text('CinemaFlix v1.0', style: TextStyle(color: Colors.white24, fontSize: 12)),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildCoverBanner() {
    return Container(
      height: 172,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE50914),
            Color(0xFFB3123B),
            Color(0xFF5B21B6),
            Color(0xFF141414),
          ],
          stops: [0.0, 0.42, 0.82, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -46, right: -24,
            child: Container(
              width: 170, height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withAlpha(30), Colors.white.withAlpha(0)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -34, left: -18,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFF7C3AED).withAlpha(70), Colors.transparent],
                ),
              ),
            ),
          ),
          // subtle film-strip dots
          Positioned(
            bottom: 14, right: 16,
            child: Row(
              children: [
                for (var i = 0; i < 6; i++)
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(i.isEven ? 70 : 30),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final joinDate = authService.currentUser?.createdAt ?? DateTime.now();
    final joinDateStr = '${joinDate.month}/${joinDate.year}';

    return Transform.translate(
      offset: const Offset(0, -52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 3,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(colors: [Color(0xFFE50914), Color(0xFF7C3AED), Color(0xFF25F4EE)]),
                ),
              ),
              const SizedBox(height: 14),
              Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFE50914).withValues(alpha: 0.35), blurRadius: 18),
                  ],
                ),
                child: CircleAvatar(
                  radius: 51,
                  backgroundColor: const Color(0xFF2A2A2A),
                  child: _avatarEmoji.isNotEmpty
                      ? Text(_avatarEmoji, style: const TextStyle(fontSize: 40))
                      : (_isEditing
                          ? IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white38, size: 28),
                              onPressed: _showAvatarPicker,
                            )
                          : const Icon(Icons.person, size: 48, color: Color(0xFFE50914))),
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
          const SizedBox(height: 14),
          // TikTok-style flat stats — the signature of the new profile card.
          InkWell(
            onTap: () => _showFollowersSheet(),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFollowerCount('186', 'Following'),
                  Container(width: 1, height: 26, color: Colors.white12),
                  _buildFollowerCount('248', 'Followers'),
                  Container(width: 1, height: 26, color: Colors.white12),
                  _buildFollowerCount('1.2M', 'Likes'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
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
          else ...[
            Text(
              '@${_handleSlug()}',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 3),
            Text(
              _nameController.text,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_bioController.text, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _websiteController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Website',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE50914))),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _locationController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Location',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE50914))),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text('Joined $joinDateStr', style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
            if (_locationController.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.white38, size: 14),
                  const SizedBox(width: 4),
                  Text(_locationController.text, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            ],
            if (_websiteController.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link, color: Colors.white38, size: 14),
                  const SizedBox(width: 4),
                  Text(_websiteController.text, style: const TextStyle(color: Color(0xFFE50914), fontSize: 13)),
                ],
              ),
            ],
          ],
          const SizedBox(height: 16),
          // TikTok-style action row: wide primary pill + compact icon squares.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Row(
            children: [
              Expanded(
                child: InteractiveCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _toggleEdit();
                  },
                  scaleAmount: 0.94,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isEditing ? const Color(0xFFE50914) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isEditing ? 'Save' : 'Edit profile',
                      style: TextStyle(
                        color: _isEditing ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _squareAction(Icons.person_add_outlined, 'Add friends', () {
                HapticFeedback.lightImpact();
                _showFollowersSheet();
              }),
              const SizedBox(width: 8),
              _squareAction(Icons.share, 'Share', () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share link copied!'), duration: Duration(seconds: 1)),
                );
              }),
              const SizedBox(width: 8),
              _squareAction(Icons.qr_code, 'QR code', () {
                HapticFeedback.lightImpact();
                showDialog(
                  context: context,
                  builder: (_) => _buildQRDialog(context),
                );
              }),
            ],
          ),
          ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _squareAction(IconData icon, String tooltip, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      scaleAmount: 0.9,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: Colors.white70, size: 19),
        ),
      ),
    );
  }

  Future<void> _toggleEdit() async {
    if (_isEditing && authService.currentUser != null) {
      await authService.updateProfile(username: _nameController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), duration: Duration(seconds: 1)),
      );
    }
    if (!mounted) return;
    setState(() => _isEditing = !_isEditing);
  }

  String _handleSlug() {
    final raw = _nameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');
    return raw.isEmpty ? 'cinemaflix' : raw;
  }

  Widget _buildAnimatedStatRow() {
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
            _buildAnimatedStatItem(Icons.visibility, 'Watched', 34),
            _buildDivider(),
            _buildAnimatedStatItem(Icons.bookmark, 'Watchlist', 12),
            _buildDivider(),
            _buildAnimatedStatItem(Icons.star, 'Reviews', 8),
            _buildDivider(),
            _buildAnimatedStatItem(Icons.favorite, 'Favorites', 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStatItem(IconData icon, String label, int target) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFE50914), size: 20),
        const SizedBox(height: 6),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: target),
          duration: const Duration(milliseconds: 1200),
          builder: (_, value, _) => Text(
            '$value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: Colors.white12);
  }

  Widget _buildAchievementBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text('Achievements', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _badges.length,
            itemBuilder: (_, i) {
              final badge = _badges[i];
              final unlocked = badge['unlocked'] as bool;
              return Container(
                width: 72,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: unlocked ? const Color(0xFFE50914).withAlpha(25) : Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: unlocked ? const Color(0xFFE50914).withAlpha(80) : Colors.white10,
                        ),
                      ),
                      child: Icon(
                        badge['icon'] as IconData,
                        color: unlocked ? const Color(0xFFE50914) : Colors.white24,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      badge['label'] as String,
                      style: TextStyle(
                        color: unlocked ? Colors.white70 : Colors.white24,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: _favoriteMovies.length,
        itemBuilder: (_, i) {
          final movie = _favoriteMovies[i];
          return InteractiveCard(
            onTap: () => Navigator.pushNamed(context, '/movie-detail', arguments: movie),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [movie.gradientStart, movie.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 10),
                            const SizedBox(width: 2),
                            Text(movie.rating, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWatchlists() {
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _watchlistMovies.length,
        itemBuilder: (_, i) {
          final movie = _watchlistMovies[i];
          return InteractiveCard(
            onTap: () => Navigator.pushNamed(context, '/movie-detail', arguments: movie),
            child: Container(
              width: 120,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [movie.gradientStart, movie.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${movie.genre.split('/')[0].trim()} • ${movie.year}',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.add_circle_outline, color: Color(0xFFE50914), size: 14),
                            const SizedBox(width: 4),
                            Text('In Watchlist', style: const TextStyle(color: Color(0xFFE50914), fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsByYou() {
    return Column(
      children: _sampleReviews.map((review) {
        final movie = review['movie'] as SampleMovie;
        final rating = review['rating'] as double;
        final content = review['content'] as String;
        final date = review['date'] as String;
        return InteractiveCard(
          onTap: () => Navigator.pushNamed(context, '/movie-detail', arguments: movie),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [movie.gradientStart, movie.gradientEnd]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.rate_review_outlined, color: Colors.white38, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                          ),
                          Row(
                            children: List.generate(5, (star) {
                              return Icon(
                                star < rating.round() ? Icons.star : Icons.star_border,
                                color: star < rating.round() ? Colors.amber : Colors.white24,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(date, style: const TextStyle(color: Colors.white24, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLists() {
    final lists = [
      {'title': 'Favorites', 'icon': Icons.favorite, 'count': '12 movies', 'color': const Color(0xFFE50914)},
      {'title': 'Watch Later', 'icon': Icons.bookmark, 'count': '8 movies', 'color': const Color(0xFF43A047)},
      {'title': 'Top Picks', 'icon': Icons.emoji_events, 'count': '5 movies', 'color': const Color(0xFFFFB300)},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: lists.map((list) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InteractiveCard(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${list['title']} list'), duration: const Duration(seconds: 1)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(list['icon'] as IconData, color: list['color'] as Color, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        list['title'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        list['count'] as String,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFollowerCount(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.05, letterSpacing: -0.3)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGuestProfile() {
    final features = [
      {'icon': Icons.favorite, 'title': 'Favorites', 'desc': 'Save movies you love'},
      {'icon': Icons.bookmark, 'title': 'Watchlists', 'desc': 'Plan what to watch next'},
      {'icon': Icons.rate_review, 'title': 'Reviews', 'desc': 'Share your thoughts'},
      {'icon': Icons.group, 'title': 'Community', 'desc': 'Join discussions'},
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914).withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, size: 80, color: Color(0xFFE50914)),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Join CinemaFlix',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create an account to save your favorites, watch on multiple devices, and join the community discussion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pushNamed(context, '/auth');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sign In / Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Watch free content'), duration: Duration(seconds: 1)),
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Watch Free', style: TextStyle(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("What you're missing:", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 12),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE50914).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(f['icon'] as IconData, color: const Color(0xFFE50914), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(f['desc'] as String, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  child: const Text('App Settings', style: TextStyle(color: Colors.white38)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
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
      onTap: () {
        soundService.play(SoundEvent.navigation);
        onTap();
      },
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

  Widget _buildQRDialog(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Profile QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2, color: Colors.black, size: 160),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Scan to view my profile', style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
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

  void _showFollowersSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 8), width: 32, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const Padding(padding: EdgeInsets.all(16), child: Text('248 Followers', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (_, i) => ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFF2A2A2A), child: Text(['🎬', '🎮', '🎨', '📚', '🎵', '🏀', '✈️', '📸', '🧠', '🎭'][i], style: const TextStyle(fontSize: 20))),
                  title: Text(['Sarah J.', 'Mike R.', 'Emma W.', 'Alex K.', 'Chris P.', 'Jordan L.', 'Taylor S.', 'Morgan B.', 'Casey D.', 'Riley M.'][i], style: const TextStyle(color: Colors.white)),
                  subtitle: Text(['Follows you', 'Mutual friend', 'Follows you', '', 'Mutual friend', '', 'Follows you', 'Mutual friend', '', ''][i], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFFE50914).withAlpha(30), const Color(0xFF7B1FA2).withAlpha(20)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE50914).withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE50914), Color(0xFF7B1FA2)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text('$_userLevel', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level $_userLevel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _xpProgress,
                      backgroundColor: Colors.white.withAlpha(15),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${(_xpProgress * 1000).toInt()}/1000 XP to Level ${_userLevel + 1}', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueWatching() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _continueWatching.length,
        itemBuilder: (_, i) {
          final movie = _continueWatching[i];
          final progress = [0.75, 0.30, 0.90, 0.45][i];
          return InteractiveCard(
            onTap: () => Navigator.pushNamed(context, '/movie-detail', arguments: movie),
            child: Container(
              width: 130,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [movie.gradientStart, movie.gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(movie.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.play_circle_fill, color: Color(0xFFE50914), size: 14),
                            const SizedBox(width: 4),
                            Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withAlpha(20),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingChart() {
    final labels = ['★', '★★', '★★★', '★★★★', '★★★★★'];
    final maxVal = _ratingDistribution.reduce((a, b) => a > b ? a : b).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: List.generate(5, (i) {
            final barIdx = 4 - i;
            final val = _ratingDistribution[barIdx];
            final fraction = maxVal > 0 ? val / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Text(labels[barIdx], style: const TextStyle(color: Colors.amber, fontSize: 12))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: Colors.white.withAlpha(10),
                        valueColor: AlwaysStoppedAnimation<Color>(i == 4 ? const Color(0xFFE50914) : i == 3 ? const Color(0xFFE50914).withAlpha(180) : const Color(0xFFE50914).withAlpha(100)),
                        minHeight: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 30, child: Text('$val', style: const TextStyle(color: Colors.white54, fontSize: 12))),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFriendSuggestions() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _suggestedFriends.length,
        itemBuilder: (_, i) {
          final friend = _suggestedFriends[i];
          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Text(friend['avatar'] as String, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(friend['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(friend['common'] as String, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: _recentActivity.map((a) {
            final Color iconColor;
            switch (a['type'] as String) {
              case 'watched': iconColor = const Color(0xFFE50914); break;
              case 'review': iconColor = Colors.amber; break;
              case 'liked': iconColor = Colors.pink; break;
              case 'gift': iconColor = const Color(0xFF10B981); break;
              case 'badge': iconColor = const Color(0xFFFFD700); break;
              default: iconColor = Colors.white38;
            }
            return ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: iconColor.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                child: Icon(a['icon'] as IconData, color: iconColor, size: 18),
              ),
              title: Text(a['text'] as String, style: const TextStyle(color: Colors.white, fontSize: 14)),
              trailing: Text(a['time'] as String, style: const TextStyle(color: Colors.white24, fontSize: 12)),
            );
          }).toList(),
        ),
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
