import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps FlutterSecureStorage — on iOS this uses Keychain, on Android the
/// EncryptedSharedPreferences backing. Never store the JWT in plain
/// SharedPreferences; it's a bearer credential.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  static Future<String?> readToken() => _storage.read(key: _tokenKey);
  static Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
