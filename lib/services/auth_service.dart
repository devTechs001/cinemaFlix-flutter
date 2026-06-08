import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _supabase.auth.onAuthStateChange.listen(_onAuthChange);
  }

  void _onAuthChange(AuthState state) {
    if (state.session?.user != null) {
      _fetchUser(state.session!.user.id);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _fetchUser(String userId) async {
    try {
      final response = await _supabase
          .table('profiles')
          .select()
          .eq('id', userId)
          .single();
      _currentUser = UserModel.fromMap(response);
      notifyListeners();
    } catch (_) {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.auth.signUp(email: email, password: password);
      final user = response.user;
      if (user != null) {
        await _supabase.table('profiles').insert({
          'id': user.id,
          'email': email,
          'username': username,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (updates.isNotEmpty) {
        await _supabase.table('profiles').update(updates).eq('id', _currentUser!.id);
        await _fetchUser(_currentUser!.id);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
