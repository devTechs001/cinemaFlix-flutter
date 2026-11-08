import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) => Transform.scale(
                    scale: 1 + (_pulseController.value * 0.08),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFFE50914), Color(0xFFB20710)]),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE50914).withAlpha(80),
                            blurRadius: 30 + (_pulseController.value * 20),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.mark_email_unread_outlined, color: Colors.white, size: 56),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text('Verify Your Email', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Text(
                  'We sent a verification email to',
                  style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(widget.email, style: const TextStyle(color: Color(0xFFE50914), fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Click the link in the email to verify your account and start enjoying CinemaFlix.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Verification email resent!'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Resend Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
                  },
                  child: Text('Back to Sign In', style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 14)),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.withAlpha(200), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Didn\'t receive the email? Check your spam folder or try a different email address.',
                          style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
