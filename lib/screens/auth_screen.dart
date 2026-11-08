import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/globals.dart';
import '../services/creator_service.dart';
import '../widgets/loading_animation.dart';
import '../widgets/interactive_card.dart';
import '../widgets/dev_mode_badge.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController(text: 'demo@cinemaflix.com');
  final _passwordController = TextEditingController(text: 'demo123');
  final _usernameController = TextEditingController();
  final _creatorCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _lastOtpDevCode;
  late TabController _tabController;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  int _logoTapCount = 0;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _creatorCodeController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _tabController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onLogoTap() {
    _logoTapCount++;
    if (_logoTapCount >= 7) {
      _logoTapCount = 0;
      devService.authenticate('admin123');
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔓 Dev mode unlocked — full access enabled'),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
      setState(() {});
    }
  }

  Future<void> _submitAuth({bool isSignUp = false}) async {
    if (devService.maintenanceMode && !devService.hasFullAccess) {
      _showError('CinemaFlix is under maintenance. Please try again later.');
      return;
    }
    if (isSignUp && _usernameController.text.trim().isEmpty) {
      _showError('Please enter a username');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email');
      return;
    }
    if (_passwordController.text.length < 4) {
      _showError('Password must be at least 4 characters');
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (isSignUp) {
        await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _usernameController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Welcome to CinemaFlix.'),
            backgroundColor: Color(0xFF43A047),
          ),
        );
      } else {
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      if (!mounted) return;
      syncService.signInSync();
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitCreatorLogin() async {
    if (devService.maintenanceMode && !devService.hasFullAccess) {
      _showError('CinemaFlix is under maintenance. Please try again later.');
      return;
    }
    if (_emailController.text.trim().isEmpty || _passwordController.text.length < 4) {
      _showError('Enter creator email and password');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      creatorService.enableCreatorMode();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/creator-hub');
    } catch (_) {
      if (devService.hasFullAccess || _creatorCodeController.text == 'creator') {
        creatorService.enableCreatorMode();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/creator-hub');
        return;
      }
      if (mounted) _showError('Creator login failed. Use demo credentials or code "creator".');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithProvider(String provider, String label) async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : '${provider.toLowerCase()}.user@cinemaflix-demo.com';
      await authService.signInWithProvider(provider, email: email, displayName: usernameOrEmpty());
      if (!mounted) return;
      syncService.signInSync();
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (!mounted) return;
      _showError('$label sign-in failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String usernameOrEmpty() => _usernameController.text.trim();

  Future<void> _startPhoneSignIn() async {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) {
      _showError('Enter a valid phone number, e.g. +254712345678');
      return;
    }
    setState(() => _isLoading = true);
    try {
      _lastOtpDevCode = await authService.requestPhoneOtp(phone);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!mounted) return;
      await _showOtpDialog(phone);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _showOtpDialog(String phone) async {
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Verify your phone', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the 6-digit code sent to $phone', style: const TextStyle(color: Colors.white54, fontSize: 13)),
            if (_lastOtpDevCode != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('(Dev code: $_lastOtpDevCode)', style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 12)),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Verify', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (verified != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await authService.verifyPhoneOtp(phone, _otpController.text.trim(), username: usernameOrEmpty());
      if (!mounted) return;
      syncService.signInSync();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _phoneSignInDialog() {
    _phoneController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sign in with phone', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: '+254712345678',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.phone_android, color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _startPhoneSignIn();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Send verification code', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    HapticFeedback.heavyImpact();
    _shakeController.forward().then((_) => _shakeController.reverse());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE50914)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A0A0E), Color(0xFF141414)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const CinemaLoading(message: 'Authenticating...')
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          const DevModeBadge(),
                          const Spacer(),
                          if (devService.hasFullAccess)
                            TextButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/dev-panel'),
                              icon: const Icon(Icons.settings, size: 18, color: Color(0xFF7C3AED)),
                              label: const Text('Dev Panel', style: TextStyle(color: Color(0xFF7C3AED))),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                              _shakeController.value * 12 * (_shakeController.value < 0.5 ? 1 : -1),
                              0,
                            ),
                            child: child,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: _onLogoTap,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFE50914), Color(0xFF7B1FA2)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE50914).withValues(alpha: 0.35),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.movie_creation_rounded, color: Colors.white, size: 40),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'CinemaFlix',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stream. Create. Connect.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
                              ),
                              const SizedBox(height: 28),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: TabBar(
                                  controller: _tabController,
                                  indicator: BoxDecoration(
                                    color: const Color(0xFFE50914),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  dividerColor: Colors.transparent,
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.white54,
                                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  tabs: const [
                                    Tab(text: 'Sign In'),
                                    Tab(text: 'Sign Up'),
                                    Tab(text: 'Creator'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 380,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildSignInForm(),
                                    _buildSignUpForm(),
                                    _buildCreatorForm(),
                                  ],
                                ),
                              ),
                              _buildSocialRow(),
                              const SizedBox(height: 16),
                              if (devService.hasFullAccess)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
                                    icon: const Icon(Icons.bolt, color: Color(0xFF7C3AED)),
                                    label: const Text('Enter as Dev (skip auth)', style: TextStyle(color: Color(0xFF7C3AED))),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF7C3AED)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                            ],
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

  Widget _buildSignInForm() {
    return Column(
      children: [
        _buildField(Icons.email_outlined, 'Email', _emailController, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _buildField(
          Icons.lock_outline,
          'Password',
          _passwordController,
          obscure: _obscurePassword,
          suffix: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                activeColor: const Color(0xFFE50914),
                side: const BorderSide(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Remember me', style: TextStyle(color: Colors.white38, fontSize: 13)),
            const Spacer(),
            InteractiveCard(
              onTap: () => Navigator.pushNamed(context, '/recover'),
              child: const Text('Forgot?', style: TextStyle(color: Color(0xFFE50914), fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _primaryButton('Sign In', () => _submitAuth()),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            if (devService.maintenanceMode && !devService.hasFullAccess) {
              _showError('Under maintenance.');
              return;
            }
            guestService.startGuestSession();
            Navigator.pushReplacementNamed(context, '/main');
          },
          child: const Text('Continue as Guest', style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      children: [
        _buildField(Icons.person_outline, 'Username', _usernameController),
        const SizedBox(height: 14),
        _buildField(Icons.email_outlined, 'Email', _emailController, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _buildField(
          Icons.lock_outline,
          'Password',
          _passwordController,
          obscure: _obscurePassword,
          suffix: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 24),
        _primaryButton('Create Account', () => _submitAuth(isSignUp: true)),
        const SizedBox(height: 12),
        Text(
          'By signing up you agree to our Terms & Privacy Policy',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCreatorForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF7B1FA2).withValues(alpha: 0.2), const Color(0xFFE50914).withValues(alpha: 0.1)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF7B1FA2).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF7B1FA2).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.videocam, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Creator Studio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Upload shorts, earn diamonds, grow your audience', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildField(Icons.email_outlined, 'Creator email', _emailController, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _buildField(Icons.lock_outline, 'Password', _passwordController, obscure: _obscurePassword),
        const SizedBox(height: 14),
        _buildField(Icons.key_outlined, 'Creator code (optional)', _creatorCodeController),
        const SizedBox(height: 20),
        _primaryButton('Open Creator Dashboard', _submitCreatorLogin, color: const Color(0xFF7B1FA2)),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            creatorService.enableCreatorMode();
            Navigator.pushNamed(context, '/creator-hub');
          },
          child: const Text('Browse Creator Hub without login', style: TextStyle(color: Colors.white38, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildSocialRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
            ),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(Icons.g_mobiledata, 'Google', const Color(0xFF4285F4)),
            const SizedBox(width: 16),
            _socialButton(Icons.apple, 'Apple', Colors.white),
            const SizedBox(width: 16),
            _socialButton(Icons.phone_android, 'Phone', const Color(0xFF10B981)),
          ],
        ),
      ],
    );
  }

  Widget _socialButton(IconData icon, String label, Color color) {
    return InteractiveCard(
      onTap: () {
        HapticFeedback.lightImpact();
        if (label == 'Google') {
          _signInWithProvider('google', label);
        } else if (label == 'Apple') {
          _signInWithProvider('apple', label);
        } else if (label == 'Phone') {
          _phoneSignInDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label sign-in coming soon'), behavior: SnackBarBehavior.floating),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap, {Color color = const Color(0xFFE50914)}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildField(
    IconData icon,
    String hint,
    TextEditingController controller, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white38, size: 22),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
