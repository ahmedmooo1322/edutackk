import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class SessionStore {
  static const _tokenKey = 'auth_token';
  static const _apiBaseUrlKey = 'api_base_url';
  static const _nameKey = 'user_name';
  static const _roleKey = 'user_role';
  static const _emailKey = 'user_email';

  Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiBaseUrlKey) ?? AppConfig.defaultApiBaseUrl;
  }

  Future<void> setApiBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiBaseUrlKey, value.trim().replaceAll(RegExp(r'/$'), ''));
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveLogin({
    required String token,
    String? name,
    String? role,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (name != null) await prefs.setString(_nameKey, name);
    if (role != null) await prefs.setString(_roleKey, role);
    if (email != null) await prefs.setString(_emailKey, email);
  }

  Future<Map<String, String?>> getUserSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey),
      'role': prefs.getString(_roleKey),
      'email': prefs.getString(_emailKey),
    };
  }

  Future<void> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
  }
}
