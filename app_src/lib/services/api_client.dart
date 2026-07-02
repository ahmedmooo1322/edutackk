import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_result.dart';
import '../models/job_status.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient(this._sessionStore);

  final SessionStore _sessionStore;

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _sessionStore.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Uri> _uri(String path) async {
    final base = await _sessionStore.getApiBaseUrl();
    return Uri.parse('$base$path');
  }

  Future<ApiResult<Map<String, dynamic>>> health() async {
    try {
      final res = await http.get(await _uri('/health')).timeout(const Duration(seconds: 8));
      return _decodeMap(res);
    } catch (e) {
      return ApiResult.failure('Cannot connect to backend: $e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            await _uri('/api/v1/auth/login'),
            headers: await _headers(),
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      final decoded = _decodeMap(res);
      if (!decoded.ok) return decoded;
      final data = decoded.data!;
      final token = data['token']?.toString();
      final user = (data['user'] as Map<String, dynamic>?) ?? const {};
      if (token == null || token.isEmpty) {
        return const ApiResult.failure('Login response did not include a token.');
      }
      await _sessionStore.saveLogin(
        token: token,
        name: user['name']?.toString(),
        role: user['role']?.toString(),
        email: user['email']?.toString(),
      );
      return decoded;
    } catch (e) {
      return ApiResult.failure('Login failed: $e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> registerStudent({
    required String name,
    required String email,
    required String password,
    required String stage,
    required int level,
  }) async {
    try {
      final res = await http
          .post(
            await _uri('/api/v1/auth/register'),
            headers: await _headers(),
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim(),
              'password': password,
              'role': 'student',
              'stage': stage,
              'level': level,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final decoded = _decodeMap(res);
      if (!decoded.ok) return decoded;
      final data = decoded.data!;
      final token = data['token']?.toString();
      final user = (data['user'] as Map<String, dynamic>?) ?? const {};
      if (token != null && token.isNotEmpty) {
        await _sessionStore.saveLogin(
          token: token,
          name: user['name']?.toString(),
          role: user['role']?.toString(),
          email: user['email']?.toString(),
        );
      }
      return decoded;
    } catch (e) {
      return ApiResult.failure('Register failed: $e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> me() async {
    try {
      final res = await http
          .get(await _uri('/api/v1/me'), headers: await _headers(auth: true))
          .timeout(const Duration(seconds: 10));
      return _decodeMap(res);
    } catch (e) {
      return ApiResult.failure('Could not load profile: $e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> startStudentChat(String message) async {
    try {
      final res = await http
          .post(
            await _uri('/api/v1/student/chat'),
            headers: await _headers(auth: true),
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 20));
      return _decodeMap(res);
    } catch (e) {
      return ApiResult.failure('Could not send chat request: $e');
    }
  }

  Future<ApiResult<JobStatus>> getJob(String jobId) async {
    try {
      final res = await http
          .get(await _uri('/api/v1/jobs/$jobId'), headers: await _headers(auth: true))
          .timeout(const Duration(seconds: 10));
      final decoded = _decodeMap(res);
      if (!decoded.ok) return ApiResult.failure(decoded.error ?? 'Could not load job.');
      return ApiResult.success(JobStatus.fromJson(decoded.data!));
    } catch (e) {
      return ApiResult.failure('Could not load job: $e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> logout() async {
    try {
      final res = await http
          .post(await _uri('/api/v1/auth/logout'), headers: await _headers(auth: true))
          .timeout(const Duration(seconds: 10));
      await _sessionStore.clearLogin();
      return _decodeMap(res);
    } catch (e) {
      await _sessionStore.clearLogin();
      return ApiResult.failure('Logged out locally. Server logout failed: $e');
    }
  }

  ApiResult<Map<String, dynamic>> _decodeMap(http.Response res) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
      if (res.statusCode >= 200 && res.statusCode < 300 && map['ok'] != false) {
        return ApiResult.success(map);
      }
      return ApiResult.failure(map['error']?.toString() ?? map['message']?.toString() ?? 'HTTP ${res.statusCode}');
    } catch (e) {
      return ApiResult.failure('Bad response from server: ${res.statusCode}');
    }
  }
}
