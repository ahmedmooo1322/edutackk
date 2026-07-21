import '../../../core/api/api_client.dart';
import '../../../core/api/token_store.dart';
import '../domain/user.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);
  final ApiClient _api; final TokenStore _tokens;
  Future<User?> restore() async { if (await _tokens.accessToken() == null) return null; try { return User.fromJson(await _api.get('/auth/me')); } catch (_) { await _tokens.clear(); return null; } }
  Future<User> login(String email, String password) async { final data = await _api.post('/auth/login', data: {'email': email, 'password': password}); await _tokens.save(access: data['accessToken'] as String, refresh: data['refreshToken'] as String); return User.fromJson(Map<String, dynamic>.from(data['user'] as Map)); }
  Future<User> register(String displayName, String email, String password) async { final data = await _api.post('/auth/register', data: {'displayName': displayName, 'email': email, 'password': password}); await _tokens.save(access: data['accessToken'] as String, refresh: data['refreshToken'] as String); return User.fromJson(Map<String, dynamic>.from(data['user'] as Map)); }
  Future<void> logout() async { final refresh = await _tokens.refreshToken(); if (refresh != null) { try { await _api.post('/auth/logout', data: {'refreshToken': refresh}); } catch (_) {} } await _tokens.clear(); }
}
