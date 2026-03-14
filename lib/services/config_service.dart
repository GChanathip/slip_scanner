import 'package:shared_preferences/shared_preferences.dart';

/// Manages LINE bot credentials and server configuration.
/// Stored via SharedPreferences (macOS: ~/Library/Preferences plist).
class ConfigService {
  static const _keyLineChannelToken = 'line_channel_access_token';
  static const _keyLineChannelSecret = 'line_channel_secret';
  static const _keyServerPort = 'server_port';

  static Future<String?> getLineChannelToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLineChannelToken);
  }

  static Future<void> setLineChannelToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLineChannelToken, token);
  }

  static Future<String?> getLineChannelSecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLineChannelSecret);
  }

  static Future<void> setLineChannelSecret(String secret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLineChannelSecret, secret);
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
