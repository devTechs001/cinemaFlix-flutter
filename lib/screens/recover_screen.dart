import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../widgets/interactive_card.dart';

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _sent = false;
  bool _isValid = true;
  bool _isSending = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  late AnimationController _shakeController;
  late AnimationController _checkmarkController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailController.removeListener(_validateEmail);
    _countdownTimer?.cancel();
    _shakeController.dispose();
    _checkmarkController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      _isValid = email.isEmpty || RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
    });
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendRecovery() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValid) {
      _shakeController.reset();
      _shakeController.forward();
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSending = true);

    try {
      await SupabaseService().auth.resetPasswordForEmail(email);
      setState(() => _sent = true);
      _checkmarkController.forward();
      _startCountdown();
    } catch (e) {
      if (mounted) {
        _shakeController.reset();
        _shakeController.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFE50914),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InteractiveCard(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: Listenable.merge([_shakeController, _checkmarkController]),
                builder: (context, _) {
                  final shakeOffset = sin(_shakeController.value * 4 * 3.14159) * 10 * _shakeController.value;
                  return Transform.translate(
                    offset: Offset(shakeOffset, 0),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(parent: _checkmarkController, curve: Curves.elasticOut),
                      ),
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _sent ? Icons.check_circle_outline : Icons.lock_outline,
                          color: _sent ? const Color(0xFF43A047) : const Color(0xFFE50914),
                          size: 44,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _sent ? 'Recovery Email Sent' : 'Reset Your Password',
                  key: ValueKey('title_$_sent'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _sent
                    ? 'Check your email for instructions to reset your password.\nThe link expires in 24 hours.'
                    : 'Enter your email address and we\'ll send you a link to recover your account.',
                style: const TextStyle(color: Colors.white54, height: 1.5), textAlign: TextAlign.center,
              ),
              if (!_sent) ...[
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Your email address',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _isValid ? const Color(0xFFE50914) : Colors.redAccent,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: _emailController.text.isNotEmpty
                        ? Icon(
                            _isValid ? Icons.check_circle : Icons.error,
                            color: _isValid ? const Color(0xFF43A047) : Colors.redAccent,
                            size: 20,
                          )
                        : null,
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                ),
                if (!_isValid) ...[
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Please enter a valid email', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendRecovery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE50914).withAlpha(80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Send Recovery Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_emailController.text.isEmpty) {
                      _emailController.text = 'demo@email.com';
                      _validateEmail();
                    }
                  },
                  child: const Text('Use demo account', style: TextStyle(color: Colors.white24)),
                ),
              ] else ...[
                const SizedBox(height: 24),
                if (_countdown > 0)
                  Text(
                    'Resend available in $_countdown seconds',
                    style: const TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _countdown > 0
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            setState(() => _sent = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE50914).withAlpha(80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _countdown > 0 ? 'Send Again ($_countdown)' : 'Send Again',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InteractiveCard(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Back to Settings', style: TextStyle(color: Colors.white38)),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              Text(
                'Need help? Contact support@cinemaflix.com',
                style: TextStyle(color: Colors.white.withAlpha(40), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double sin(double x) {
    double result = 0;
    double term = x;
    for (int n = 1; n <= 10; n++) {
      result += term;
      term *= -x * x / ((2 * n) * (2 * n + 1));
    }
    return result;
  }
}
