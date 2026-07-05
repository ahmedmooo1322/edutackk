import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class SessionStore {
  static const _tokenKey = 'auth_token';
  static const _apiBaseUrlKey = 'api_base_url';
  static const _nameKey = 'user_name';
  static const _roleKey = 'user_role';
  static const _emailKey = 'user_email';
  static const _usernameKey = 'user_username';
  static const _languageKey = 'language_code';
  static const _darkModeKey = 'dark_mode';
  static const _adminModeKey = 'admin_preferred_mode';
  static const _cachePrefix = 'api_cache_';

  Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiBaseUrlKey) ?? AppConfig.defaultApiBaseUrl;
  }

  Future<void> setApiBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiBaseUrlKey, value.trim().replaceAll(RegExp(r'/$'), ''));
  }

  Future<String> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'ar';
  }

  Future<void> setLanguageCode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value == 'en' ? 'en' : 'ar');
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
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
    String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (name != null) await prefs.setString(_nameKey, name);
    if (role != null) await prefs.setString(_roleKey, role);
    if (email != null) await prefs.setString(_emailKey, email);
    if (username != null) await prefs.setString(_usernameKey, username);
  }

  Future<String> getAdminPreferredMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminModeKey) == 'normal' ? 'normal' : 'admin';
  }

  Future<void> setAdminPreferredMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminModeKey, value == 'normal' ? 'normal' : 'admin');
  }

  Future<Map<String, String?>> getUserSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey),
      'role': prefs.getString(_roleKey),
      'email': prefs.getString(_emailKey),
      'username': prefs.getString(_usernameKey),
    };
  }

  Future<void> setCache(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cachePrefix$key', value);
  }

  Future<String?> getCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_cachePrefix$key');
  }

  Future<void> clearUserCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
    await clearUserCache();
  }
}
