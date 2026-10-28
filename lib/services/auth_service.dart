import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_client.dart';

class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['user_id'] as int,
        fullName: j['full_name'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String,
        role: j['role'] as String,
      );
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _storage = const FlutterSecureStorage();
  final ApiClient _api = ApiClient();

  /// Client bersama (membawa token login) untuk service lain.
  ApiClient get api => _api;

  AppUser? currentUser;

  Future<AppUser> login({
    required String identifier,
    required String password,
  }) async {
    final res = await _api.post('/auth/login', {
      'identifier': identifier.trim(),
      'password': password,
    });
    return _saveSession(res);
  }

  Future<AppUser> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await _api.post('/auth/register', {
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
      'accept_terms': true,
    });
    return _saveSession(res);
  }

  Future<String> forgotPassword(String identifier) async {
    final res = await _api.post('/auth/forgot-password', {'identifier': identifier.trim()});
    return (res['message'] as String?) ?? 'Instruksi pemulihan telah dikirim.';
  }

  Future<String> resetPassword({
    required String identifier,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await _api.post('/auth/reset-password', {
      'identifier': identifier.trim(),
      'code': code.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return (res['message'] as String?) ?? 'Kata sandi berhasil diubah.';
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', {});
    } catch (_) {
      // tetap keluar secara lokal walau request gagal
    }
    await _storage.delete(key: 'token');
    _api.token = null;
    currentUser = null;
  }

  Future<AppUser> _saveSession(Map<String, dynamic> res) async {
    final token = res['token'] as String;
    await _storage.write(key: 'token', value: token);
    _api.token = token;
    currentUser = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    return currentUser!;
  }
}