import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/globals.dart';
import '../widgets/loading_animation.dart';
import '../widgets/interactive_card.dart';

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
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
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
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSignUp && _usernameController.text.trim().isEmpty) {
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
      if (_isSignUp) {
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
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: _isLoading
            ? const CinemaLoading(message: 'Authenticating...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, _) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeController.value * 12 * (_shakeController.value < 0.5 ? 1 : -1),
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE50914), Color(0xFFB71C1C)],
                                ),
                              ),
                              child: const Icon(Icons.movie_creation_rounded, color: Colors.white, size: 36),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              'CinemaFlix',
                              style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold,
                                color: Color(0xFFE50914), letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              _isSignUp ? 'Create your account' : 'Welcome back',
                              style: const TextStyle(fontSize: 16, color: Colors.white54),
                            ),
                          ),
                          const SizedBox(height: 40),
                          if (_isSignUp) ...[
                            _buildField(Icons.person_outline, 'Username', _usernameController),
                            const SizedBox(height: 16),
                          ],
                          _buildField(Icons.email_outlined, 'Email', _emailController, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildField(Icons.lock_outline, 'Password', _passwordController,
                            obscure: _obscurePassword,
                            suffix: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          if (!_isSignUp) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(
                                  height: 24, width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                    activeColor: const Color(0xFFE50914),
                                    checkColor: Colors.white,
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
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE50914),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: Text(
                                _isSignUp ? 'Create Account' : 'Sign In',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          if (!_isSignUp) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: InteractiveCard(
                                onTap: () {
                                  guestService.startGuestSession();
                                  Navigator.pushReplacementNamed(context, '/main');
                                },
                                child: const Text('Continue as Guest', style: TextStyle(color: Colors.white38, fontSize: 14)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                  if (!_isSignUp) {
                                    _emailController.text = 'demo@cinemaflix.com';
                                    _passwordController.text = 'demo123';
                                  }
                                });
                              },
                              child: Text(
                                _isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Sign Up",
                                style: const TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildField(IconData icon, String hint, TextEditingController controller,
      {bool obscure = false, Widget? suffix, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(14),
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
