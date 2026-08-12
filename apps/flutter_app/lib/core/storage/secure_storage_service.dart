import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage (Keychain/Keystore/DPAPI-backed) so a JWT is
/// never kept in plain SharedPreferences (spec §31, §41: "Do not store
/// sensitive credentials in the app bundle" — this covers runtime storage
/// too). Never stores API keys; the app never has any to store, since all
/// LLM/DB access stays server-side.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'auth_access_token';

  Future<void> saveAccessToken(String token) => _storage.write(key: _accessTokenKey, value: token);

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> clearAccessToken() => _storage.delete(key: _accessTokenKey);
}
