import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sample_movies.dart';
import '../widgets/interactive_card.dart';
import 'movie_detail_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with TickerProviderStateMixin {
  bool _locked = true;
  bool _wrongPin = false;
  int _currentTab = 0;
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  late AnimationController _shakeController;
  late AnimationController _unlockController;
  late Animation<double> _shakeAnimation;
  late TabController _tabController;

  final List<Map<String, dynamic>> _secretNotes = [
    {'title': 'Movie Review Draft', 'content': 'The cinematography in Dune: Part Two is absolutely breathtaking. Denis Villeneuve has created a visual masterpiece that rivals the original. The use of practical effects combined with seamless CGI creates a world that feels tangible and real. The sandworm riding sequence alone is worth the price of admission.', 'date': '2024-03-15'},
    {'title': 'Hidden Watchlist', 'content': 'Underrated films to watch:\n1. The Fall (2006)\n2. Moon (2009)\n3. The Man from Nowhere (2010)\n4. A Prophet (2009)\n5. Incendies (2010)', 'date': '2024-02-28'},
    {'title': 'Screening Notes', 'content': 'Attended early screening of the new indie film "Echoes of Tomorrow". The director took a bold approach with nonlinear storytelling. The score by independent artist Luna Wave perfectly complements the ethereal visuals. Will definitely recommend for the film festival circuit.', 'date': '2024-01-20'},
  ];

  final List<SampleMovie> _hiddenGems = [
    SampleMovie(
      id: 'the_fall',
      title: 'The Fall',
      year: '2006',
      rating: '7.9',
      genre: 'Fantasy / Drama',
      description: 'A bedridden patient in a hospital tells a fantastical story to a young girl, weaving a tale of adventure and heroism that parallels his own struggle.',
      cast: 'Lee Pace, Catinca Untaru, Justine Waddell',
      director: 'Tarsem Singh',
      duration: '1h 57m',
      gradientStart: const Color(0xFF1A0A2E),
      gradientEnd: const Color(0xFF2D1B4E),
    ),
    SampleMovie(
      id: 'moon',
      title: 'Moon',
      year: '2009',
      rating: '7.9',
      genre: 'Sci-Fi / Drama',
      description: 'A man on a solitary lunar base begins to suspect his reality is not what it seems when he discovers another identical version of himself.',
      cast: 'Sam Rockwell, Kevin Spacey, Dominique McElligott',
      director: 'Duncan Jones',
      duration: '1h 37m',
      gradientStart: const Color(0xFF0D0D1A),
      gradientEnd: const Color(0xFF1A1A2E),
    ),
    SampleMovie(
      id: 'incendies',
      title: 'Incendies',
      year: '2010',
      rating: '8.3',
      genre: 'Drama / Mystery',
      description: 'Twins journey to the Middle East to uncover their mother\'s secret past, revealing a harrowing story of war, love, and devastating family secrets.',
      cast: 'Lubna Azabal, Mélissa Désormeaux-Poulin, Maxim Gaudette',
      director: 'Denis Villeneuve',
      duration: '2h 11m',
      gradientStart: const Color(0xFF1A0A00),
      gradientEnd: const Color(0xFF2D1B00),
    ),
    SampleMovie(
      id: 'man_from_nowhere',
      title: 'The Man from Nowhere',
      year: '2010',
      rating: '7.8',
      genre: 'Action / Thriller',
      description: 'A quiet pawnshop keeper with a violent past takes on a powerful crime syndicate when a young girl he cares about is kidnapped.',
      cast: 'Won Bin, Kim Sae-ron, Kim Tae-hoon',
      director: 'Lee Jeong-beom',
      duration: '1h 59m',
      gradientStart: const Color(0xFF0D0D0D),
      gradientEnd: const Color(0xFF1A1A1A),
    ),
    SampleMovie(
      id: 'prophet',
      title: 'A Prophet',
      year: '2009',
      rating: '7.8',
      genre: 'Crime / Drama',
      description: 'A young Arab man is sent to a French prison where he becomes a mafia kingpin after learning the ropes of organized crime.',
      cast: 'Tahar Rahim, Niels Arestrup, Adel Bencherif',
      director: 'Jacques Audiard',
      duration: '2h 35m',
      gradientStart: const Color(0xFF1A1A0A),
      gradientEnd: const Color(0xFF2D2D1A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _unlockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _shakeController.dispose();
    _unlockController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onPinDigit(String digit) {
    HapticFeedback.lightImpact();
    if (_pinController.text.length >= 4) return;
    setState(() {
      _pinController.text += digit;
    });
  }

  void _onDelete() {
    HapticFeedback.lightImpact();
    if (_pinController.text.isEmpty) return;
    setState(() {
      _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
    });
  }

  void _unlock() {
    HapticFeedback.mediumImpact();
    if (_pinController.text == '1234') {
      setState(() => _locked = false);
      _unlockController.forward();
    } else {
      setState(() => _wrongPin = true);
      _shakeController.forward(from: 0);
      _pinController.clear();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _wrongPin = false);
      });
    }
  }

  void _lock() {
    HapticFeedback.mediumImpact();
    setState(() {
      _locked = true;
      _pinController.clear();
    });
    _unlockController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _locked ? null : _buildAppBar(),
      body: _locked ? _buildLockScreen() : _buildVaultContent(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D0D0D),
      elevation: 0,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, color: Color(0xFF00C853), size: 20),
          SizedBox(width: 8),
          Text('My Vault', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00C853).withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00C853).withAlpha(60)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF00C853), size: 14),
              SizedBox(width: 4),
              Text('Vault unlocked', style: TextStyle(color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (_currentTab == 1)
          InteractiveCard(
            onTap: _showAddNoteDialog,
            scaleAmount: 0.88,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Color(0xFF00C853), size: 20),
            ),
          ),
        InteractiveCard(
          onTap: _lock,
          scaleAmount: 0.88,
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock, color: Colors.white54, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildLockScreen() {
    return AnimatedBuilder(
      animation: _unlockController,
      builder: (context, child) {
        final scale = 1.0 - (_unlockController.value * 0.05);
        final opacity = 1.0 - (_unlockController.value * 0.3);
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withAlpha(20),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00C853).withAlpha(60), width: 2),
                  ),
                  child: Icon(Icons.lock_outline, color: const Color(0xFF00C853), size: 48),
                ),
                const SizedBox(height: 24),
                const Text('My Vault', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Enter your PIN to unlock', style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00C853).withAlpha(40)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, color: Color(0xFF00C853), size: 12),
                      SizedBox(width: 4),
                      Text('Vault secured', style: TextStyle(color: Color(0xFF00C853), fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_wrongPin ? _shakeAnimation.value * (_shakeAnimation.value > 5 ? -1 : 1) : 0, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < _pinController.text.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? const Color(0xFF00C853) : Colors.transparent,
                          border: Border.all(
                            color: _wrongPin
                                ? const Color(0xFFE50914)
                                : filled
                                    ? const Color(0xFF00C853)
                                    : Colors.white38,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (_wrongPin)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('Incorrect PIN. Try again.', style: TextStyle(color: const Color(0xFFE50914), fontSize: 13)),
                  ),
                const SizedBox(height: 40),
                _buildPinPad(),
                const SizedBox(height: 24),
                InteractiveCard(
                  onTap: _pinController.text.length == 4 ? _unlock : null,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _pinController.text.length == 4
                          ? const Color(0xFF00C853)
                          : const Color(0xFF00C853).withAlpha(40),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('Unlock', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [1, 2, 3].map((n) => _pinButton('$n')).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [4, 5, 6].map((n) => _pinButton('$n')).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [7, 8, 9].map((n) => _pinButton('$n')).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72),
            _pinButton('0'),
            _deleteButton(),
          ],
        ),
      ],
    );
  }

  Widget _pinButton(String digit) {
    return InteractiveCard(
      onTap: () => _onPinDigit(digit),
      scaleAmount: 0.9,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Center(
          child: Text(digit, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _deleteButton() {
    return InteractiveCard(
      onTap: _onDelete,
      scaleAmount: 0.9,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: const Center(
          child: Icon(Icons.backspace_outlined, color: Colors.white54, size: 24),
        ),
      ),
    );
  }

  Widget _buildVaultContent() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00C853),
          indicatorWeight: 3,
          labelColor: const Color(0xFF00C853),
          unselectedLabelColor: Colors.white38,
          onTap: (i) => setState(() => _currentTab = i),
          tabs: const [
            Tab(icon: Icon(Icons.bookmark_outline), text: 'Watchlist'),
            Tab(icon: Icon(Icons.article_outlined), text: 'Notes'),
            Tab(icon: Icon(Icons.diamond_outlined), text: 'Gems'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPrivateWatchlist(),
              _buildSecretNotes(),
              _buildHiddenGems(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateWatchlist() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: sampleMovies.length,
        itemBuilder: (context, index) {
          final movie = sampleMovies[index];
          return InteractiveCard(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [movie.gradientStart, movie.gradientEnd],
                ),
                border: Border.all(color: const Color(0xFF00C853).withAlpha(40)),
                boxShadow: [
                  BoxShadow(
                    color: movie.gradientStart.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withAlpha(20),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(Icons.movie_filter_outlined, color: const Color(0xFF00C853).withAlpha(120), size: 24),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      movie.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(movie.rating, style: const TextStyle(color: Colors.amber, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(movie.year, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('PRIVATE', style: TextStyle(color: const Color(0xFF00C853).withAlpha(180), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecretNotes() {
    return Column(
      children: [
        if (_secretNotes.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add_outlined, color: Colors.white.withAlpha(30), size: 64),
                  const SizedBox(height: 16),
                  Text('No secret notes yet', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 16)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _secretNotes.length,
              itemBuilder: (context, index) => _buildNoteCard(index),
            ),
          ),
      ],
    );
  }

  Widget _buildNoteCard(int index) {
    final note = _secretNotes[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InteractiveCard(
        onTap: () {
          HapticFeedback.lightImpact();
          _showNoteDetail(note);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00C853).withAlpha(25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_outline, color: Color(0xFF00C853), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      note['content'].toString().replaceAll('\n', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(note['date'], style: TextStyle(color: Colors.white.withAlpha(50), fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withAlpha(40)),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteDetail(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFF00C853), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(note['title'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  InteractiveCard(
                    onTap: () => Navigator.pop(ctx),
                    scaleAmount: 0.85,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white38, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(note['date'], style: TextStyle(color: Colors.white.withAlpha(50), fontSize: 12)),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF2A2A2A)),
              const SizedBox(height: 12),
              Text(note['content'], style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.note_add_outlined, color: Color(0xFF00C853), size: 22),
                  const SizedBox(width: 10),
                  const Text('New Secret Note', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  InteractiveCard(
                    onTap: () => Navigator.pop(ctx),
                    scaleAmount: 0.85,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white38, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Note title',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0D0D0D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 5,
                minLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Write your secret note...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0D0D0D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: InteractiveCard(
                  onTap: () {
                    if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
                    HapticFeedback.mediumImpact();
                    final now = DateTime.now();
                    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                    setState(() {
                      _secretNotes.insert(0, {
                        'title': titleController.text.trim(),
                        'content': contentController.text.trim(),
                        'date': dateStr,
                      });
                    });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('Save Note', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHiddenGems() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('RARE FINDS', style: TextStyle(color: Color(0xFF00C853), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
            const SizedBox(width: 12),
            Text('Curated hidden cinema', style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 13)),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 340,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _hiddenGems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final gem = _hiddenGems[index];
              return InteractiveCard(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: gem)),
                  );
                },
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [gem.gradientStart, gem.gradientEnd],
                    ),
                    border: Border.all(color: const Color(0xFF00C853).withAlpha(50)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withAlpha(30),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withAlpha(40),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.diamond, color: Color(0xFF00C853), size: 12),
                                const SizedBox(width: 4),
                                Text('GEM', style: TextStyle(color: const Color(0xFF00C853), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(60),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 12),
                                const SizedBox(width: 3),
                                Text(gem.rating, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withAlpha(15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(Icons.movie_filter_outlined, color: const Color(0xFF00C853).withAlpha(100), size: 24),
                      ),
                      const SizedBox(height: 12),
                      Text(gem.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(gem.genre, style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.white.withAlpha(80), size: 12),
                          const SizedBox(width: 4),
                          Text(gem.duration, style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 11)),
                          const SizedBox(width: 8),
                          Text(gem.year, style: TextStyle(color: Colors.white.withAlpha(60), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00C853).withAlpha(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: const Color(0xFF00C853), size: 20),
                  const SizedBox(width: 8),
                  const Text('Why Hidden Gems?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'These are underrated masterpieces that deserve more attention. '
                'Curated by our team of cinema enthusiasts who dig deep to find '
                'extraordinary films that flew under the radar.',
                style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
