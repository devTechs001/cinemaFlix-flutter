import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../widgets/interactive_card.dart';

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Recovery', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
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
              const SizedBox(height: 24),
              Text(
                _sent ? 'Recovery Email Sent' : 'Reset Your Password',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_emailController.text.trim().isEmpty) return;
                      HapticFeedback.mediumImpact();
                      try {
                        await SupabaseService().auth.resetPasswordForEmail(_emailController.text.trim());
                        setState(() => _sent = true);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: const Color(0xFFE50914)),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Send Recovery Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_emailController.text.isEmpty) {
                      _emailController.text = 'demo@email.com';
                    }
                  },
                  child: const Text('Use demo account', style: TextStyle(color: Colors.white24)),
                ),
              ] else ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Back to Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                InteractiveCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _sent = false);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Send again', style: TextStyle(color: Colors.white38)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
