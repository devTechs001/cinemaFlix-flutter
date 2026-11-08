import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_config.dart';
import 'wallet_service.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _token;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get token => _token;

  AuthService() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    final savedUser = prefs.getString('auth_user');
    if (savedToken != null && savedUser != null) {
      _token = savedToken;
      _currentUser = UserModel.fromJson(jsonDecode(savedUser) as Map<String, dynamic>);
      WalletService.setSignedIn(true); // restored session also mirrors the wallet
      notifyListeners();
    }
  }

  Future<void> _saveSession(String token, UserModel user) async {
    _token = token;
    _currentUser = user;
    WalletService.setSignedIn(true); // enable backend wallet mirroring
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user', jsonEncode(user.toJson()));
    notifyListeners();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      // NOTE: the old hard-coded developer backdoor (devtechs842/pass123) was
      // removed — developer access now goes exclusively through the Dev Panel
      // access code (admin/developer system). Auth is always validated by the
      // backend below.
      final response = await http.post(
        Uri.parse(ApiConfig.apiPath('/auth/login')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>;
        final user = UserModel(
          id: userData['id'] as String,
          email: userData['email'] as String? ?? email,
          username: userData['username'] as String? ?? 'Cinema Fan',
          avatarUrl: userData['avatarUrl'] as String?,
          createdAt: DateTime.tryParse(userData['createdAt'] as String? ?? '') ?? DateTime.now(),
        );
        final token = userData['token'] as String? ?? '';
        await _saveSession(token, user);
      } else {
        throw Exception('Login failed (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('AuthService: signIn failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.apiPath('/auth/register')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'username': username}),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>;
        final user = UserModel(
          id: userData['id'] as String,
          email: userData['email'] as String? ?? email,
          username: userData['username'] as String? ?? username,
          avatarUrl: userData['avatarUrl'] as String?,
          createdAt: DateTime.tryParse(userData['createdAt'] as String? ?? '') ?? DateTime.now(),
        );
        final token = userData['token'] as String? ?? '';
        await _saveSession(token, user);
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(body['error'] ?? 'Registration failed');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// OAuth sign-in (Google/Apple/...). The backend upserts a user for the
  /// provider email and returns a session token.
  Future<void> signInWithProvider(String provider, {required String email, String? displayName}) async {
    if (provider != 'google' && provider != 'apple') {
      throw Exception('Unsupported OAuth provider: $provider');
    }
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.apiPath('/auth/oauth/$provider')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'displayName': displayName}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('OAuth sign-in failed (${response.statusCode})');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final userData = data['user'] as Map<String, dynamic>;
      final user = UserModel(
        id: userData['id'] as String,
        email: userData['email'] as String? ?? email,
        username: userData['username'] as String? ?? (displayName ?? 'Cinema Fan'),
        avatarUrl: userData['avatarUrl'] as String?,
        createdAt: DateTime.tryParse(userData['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
      await _saveSession(userData['token'] as String? ?? '', user);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Phone auth step 1 — request an OTP for the E.164 phone number.
  Future<String?> requestPhoneOtp(String phone) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.apiPath('/auth/phone/request-otp')),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to send OTP');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['devCode'] as String?; // shown only in dev mode
  }

  /// Phone auth step 2 — verify the OTP and open a session.
  Future<void> verifyPhoneOtp(String phone, String code, {String? username}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.apiPath('/auth/phone/verify-otp')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone, 'code': code, 'username': username}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(body['error'] ?? 'OTP verification failed');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final userData = data['user'] as Map<String, dynamic>;
      final user = UserModel(
        id: userData['id'] as String,
        email: userData['email'] as String? ?? phone,
        username: userData['username'] as String? ?? 'Cinema Fan',
        createdAt: DateTime.tryParse(userData['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
      await _saveSession(userData['token'] as String? ?? '', user);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _token = null;
    _currentUser = null;
    WalletService.setSignedIn(false); // stop backend wallet mirroring
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    notifyListeners();
  }

  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    if (_currentUser == null) return;
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.apiPath('/users/${_currentUser!.id}')),
        headers: _headers,
        body: jsonEncode({if (username != null) 'username': username}),
      );
      if (response.statusCode == 200) {
        await _saveSession(_token!, _currentUser!.copyWith(username: username));
      }
    } catch (e) {
      debugPrint('AuthService: updateProfile failed: $e');
    }
  }
}
