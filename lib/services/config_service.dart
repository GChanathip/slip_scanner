import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages LINE bot credentials and server configuration.
/// Credentials stored in Keychain (macOS) via flutter_secure_storage.
/// Non-sensitive settings stored via SharedPreferences.
class ConfigService {
  static const _storage = FlutterSecureStorage();
  static const _keyLineChannelToken = 'line_channel_access_token';
  static const _keyLineChannelSecret = 'line_channel_secret';
  static const _keyServerPort = 'server_port';

  static Future<String?> getLineChannelToken() async {
    return _storage.read(key: _keyLineChannelToken);
  }

  static Future<void> setLineChannelToken(String token) async {
    await _storage.write(key: _keyLineChannelToken, value: token);
  }

  static Future<String?> getLineChannelSecret() async {
    return _storage.read(key: _keyLineChannelSecret);
  }

  static Future<void> setLineChannelSecret(String secret) async {
    await _storage.write(key: _keyLineChannelSecret, value: secret);
  }

  static Future<int> getServerPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyServerPort) ?? 8080;
  }

  static Future<void> setServerPort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyServerPort, port);
  }

  /// Check if LINE bot is configured (both token and secret are set).
  static Future<bool> isLineConfigured() async {
    final token = await getLineChannelToken();
    final secret = await getLineChannelSecret();
    return token != null &&
        token.isNotEmpty &&
        secret != null &&
        secret.isNotEmpty;
  }
}
