import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'local_db_service.dart';
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
          .maybeSingle();
      // A missing profile row is not the same as being signed out, but
      // until a row exists we can't build a UserModel. (Tip: create the
      // profile row with a Postgres trigger on auth.users — see REVIEW.md.)
      _currentUser = response == null ? null : UserModel.fromMap(response);
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
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      final user = response.user;
      // Only insert the profile when we actually have a session. With
      // email confirmation enabled there is no session yet and the
      // insert would fail under RLS — use a DB trigger for that case.
      if (user != null && response.session != null) {
        try {
          await _supabase.table('profiles').insert({
            'id': user.id,
            'email': email,
            'username': username,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          // Profile may already exist (e.g. created by a DB trigger).
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await LocalDbService().clearUserData();
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
