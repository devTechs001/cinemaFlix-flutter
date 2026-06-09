import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  int _step = 0;
  bool _isLoading = false;
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _checkAnimation = CurvedAnimation(parent: _checkController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(_step == 2 ? 'Success' : 'Reset Password', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _step == 0
            ? _buildEmailStep()
            : _step == 1
                ? _buildResetStep()
                : _buildSuccessStep(),
      ),
    );
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_reset, color: Color(0xFFE50914), size: 48),
          const SizedBox(height: 24),
          const Text('Forgot Password?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            'Enter your email and we\'ll send you a reset code.',
            style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 15),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Email address',
              hintStyle: TextStyle(color: Colors.white.withAlpha(60)),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withAlpha(80)),
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send Reset Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter a valid email'), backgroundColor: const Color(0xFFE50914), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _step = 1;
    });
  }

  Widget _buildResetStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_open, color: Color(0xFFE50914), size: 48),
          const SizedBox(height: 24),
          const Text('Set New Password', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            'Enter the code sent to ${_emailController.text.trim()} and your new password.',
            style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 15),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Reset code',
              hintStyle: TextStyle(color: Colors.white.withAlpha(60)),
              prefixIcon: Icon(Icons.pin_outlined, color: Colors.white.withAlpha(80)),
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'New password',
              hintStyle: TextStyle(color: Colors.white.withAlpha(60)),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withAlpha(80)),
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Confirm password',
              hintStyle: TextStyle(color: Colors.white.withAlpha(60)),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withAlpha(80)),
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text.isEmpty || _confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please fill in all fields'), backgroundColor: const Color(0xFFE50914), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Passwords do not match'), backgroundColor: const Color(0xFFE50914), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Password must be at least 6 characters'), backgroundColor: const Color(0xFFE50914), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    _step = 2;
    _checkController.forward();
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _checkAnimation,
              builder: (context, child) => Transform.scale(
                scale: _checkAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withAlpha(30),
                    border: Border.all(color: const Color(0xFF10B981), width: 3),
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF10B981), size: 48),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Password Reset!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              'Your password has been successfully reset. You can now sign in with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
