import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_result.dart';
import '../models/job_status.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient(this._sessionStore);

  final SessionStore _sessionStore;

  Future<Map<String, String>> _headers({bool auth = false, String? adminKey}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _sessionStore.getToken();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }
    if (adminKey != null && adminKey.isNotEmpty) headers['x-admin-api-key'] = adminKey;
    return headers;
  }

  Future<Uri> _uri(String path) async {
    final base = await _sessionStore.getApiBaseUrl();
    return Uri.parse('$base$path');
  }

  Future<String?> absoluteUrl(String? url) async {
    final value = url?.trim();
    if (value == null || value.isEmpty || value == 'null') return null;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    final base = await _sessionStore.getApiBaseUrl();
    if (value.startsWith('/')) return '$base$value';
    return '$base/$value';
  }

  Future<ApiResult<Map<String, dynamic>>> health() async {
    try {
      final res = await http.get(await _uri('/health')).timeout(const Duration(seconds: 8));
      return _decodeMap(res);
    } catch (e) {
      return ApiResult.failure('Cannot connect to backend: $e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> verifyAdminKey(String key) async {
    try {
      final res = await http
          .post(await _uri('/api/v1/admin/verify-key'), headers: await _headers(adminKey: key), body: jsonEncode({}))
          .timeout(const Duration(seconds: 10));
      return _decodeMap(res);
    } catch (e) {
      return ApiResult.failure('Admin password check failed: $e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> login({required String email, required String password}) async {
    try {
      final identifier = email.trim();
      final res = await http
          .post(
            await _uri('/api/v1/auth/login'),
            headers: await _headers(),
            body: jsonEncode({'identifier': identifier, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      final decoded = _decodeMap(res);
      if (!decoded.ok) return decoded;
      final data = decoded.data!;
      final token = data['token']?.toString();
      final user = (data['user'] as Map<String, dynamic>?) ?? const {};
      if (token == null || token.isEmpty) return const ApiResult.failure('Login response did not include a token.');
      await _sessionStore.saveLogin(
        token: token,
        name: user['name']?.toString(),
        role: user['role']?.toString(),
        email: user['email']?.toString(),
        username: user['username']?.toString(),
      );
      return decoded;
    } catch (e) {
      return ApiResult.failure('Login failed: $e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> registerStudent({
    required String name,
    required String email,
    required String phone,
    required String countryCode,
    required String educationSystem,
    required String username,
    required String password,
    required String stage,
    required int level,
    String role = 'student',
    List<String> subjects = const [],
  }) async {
    try {
      final res = await http
          .post(
            await _uri('/api/v1/auth/register'),
            headers: await _headers(),
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim(),
              'phone': phone.trim(),
              'country_code': countryCode,
              'education_system': educationSystem,
              'username': username.trim().toLowerCase(),
              'password': password,
              'role': role,
              if (role == 'student') 'stage': stage,
              if (role == 'student') 'level': level,
              if (role == 'teacher') 'subjects': subjects,
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
          username: user['username']?.toString(),
        );
      }
      return decoded;
    } catch (e) {
      return ApiResult.failure('Register failed: $e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> publicAppSettings() async {
    const cacheKey = '/api/v1/app/settings';
    try {
      final res = await http.get(await _uri('/api/v1/app/settings'), headers: await _headers()).timeout(const Duration(seconds: 10));
      final decoded = _decodeMap(res);
      if (decoded.ok && decoded.data != null) await _sessionStore.setCache(cacheKey, jsonEncode(decoded.data));
      if (!decoded.ok) {
        final cached = await _sessionStore.getCache(cacheKey);
        if (cached != null) return ApiResult.success(Map<String, dynamic>.from(jsonDecode(cached) as Map));
      }
      return decoded;
    } catch (e) {
      final cached = await _sessionStore.getCache(cacheKey);
      if (cached != null) return ApiResult.success(Map<String, dynamic>.from(jsonDecode(cached) as Map));
      return const ApiResult.failure('Connection problem. Please try again.');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> me() async => _get('/api/v1/me');
  Future<ApiResult<Map<String, dynamic>>> appVersion() async => _get('/api/v1/app/version');
  Future<ApiResult<Map<String, dynamic>>> requestAccountDeletion(String reason) async => _post('/api/v1/account/delete-request', {'reason': reason});
  Future<ApiResult<Map<String, dynamic>>> studentProfile() async => _get('/api/v1/student/profile');
  Future<ApiResult<Map<String, dynamic>>> subscription() async => _get('/api/v1/student/subscription');
  Future<ApiResult<Map<String, dynamic>>> usage() async => _get('/api/v1/student/usage');

  Future<ApiResult<Map<String, dynamic>>> uploadProfilePhoto(String filePath) {
    return _upload('/api/v1/student/profile/photo', filePath);
  }

  Future<ApiResult<Map<String, dynamic>>> getAiChatHistory({int? before, int limit = 20}) async {
    final qs = before == null ? '?limit=$limit' : '?before=$before&limit=$limit';
    return _get('/api/v1/student/chat/history$qs');
  }

  Future<ApiResult<Map<String, dynamic>>> startStudentChat(String message) async {
    return _post('/api/v1/student/chat', {'message': message});
  }

  Future<ApiResult<JobStatus>> getJob(String jobId) async {
    try {
      final res = await http
          .get(await _uri('/api/v1/jobs/$jobId'), headers: await _headers(auth: true))
          .timeout(const Duration(seconds: 20));
      final decoded = _decodeMap(res);
      if (!decoded.ok) return ApiResult.failure(decoded.error ?? 'Could not load job.');
      return ApiResult.success(JobStatus.fromJson(decoded.data!));
    } catch (e) {
      return const ApiResult.failure('Connection problem. Please try again.');
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

  Future<ApiResult<Map<String, dynamic>>> myLevelRoom() async => _get('/api/v1/community/rooms/my');

  Future<ApiResult<Map<String, dynamic>>> roomMessages(int roomId, {int? before, int limit = 20}) {
    final qs = before == null ? '?limit=$limit' : '?before=$before&limit=$limit';
    return _get('/api/v1/community/rooms/$roomId/messages$qs');
  }

  Future<ApiResult<Map<String, dynamic>>> sendRoomMessage(int roomId, String message) {
    return _post('/api/v1/community/rooms/$roomId/messages', {'message': message});
  }

  Future<ApiResult<Map<String, dynamic>>> uploadRoomAttachment(int roomId, String filePath) {
    return _upload('/api/v1/community/rooms/$roomId/attachments', filePath);
  }

  Future<ApiResult<Map<String, dynamic>>> searchStudents(String q) async {
    return _get('/api/v1/community/students/search?q=${Uri.encodeQueryComponent(q)}');
  }

  Future<ApiResult<Map<String, dynamic>>> sendFriendRequest(int receiverId) {
    return _post('/api/v1/community/friends/request', {'receiver_id': receiverId});
  }

  Future<ApiResult<Map<String, dynamic>>> friendRequests() async => _get('/api/v1/community/friends/requests');
  Future<ApiResult<Map<String, dynamic>>> friends() async => _get('/api/v1/community/friends');

  Future<ApiResult<Map<String, dynamic>>> unfriend(int userId) async => _delete('/api/v1/community/friends/$userId');

  Future<ApiResult<Map<String, dynamic>>> respondFriendRequest(int requestId, String action) {
    return _post('/api/v1/community/friends/requests/$requestId/respond', {'action': action});
  }

  Future<ApiResult<Map<String, dynamic>>> privateConversations() async => _get('/api/v1/community/private/conversations');

  Future<ApiResult<Map<String, dynamic>>> acceptPrivateMessageRequest(int conversationId) {
    return _post('/api/v1/community/private/conversations/$conversationId/accept', {});
  }

  Future<ApiResult<Map<String, dynamic>>> createPrivateConversation(int otherUserId) {
    return _post('/api/v1/community/private/conversations', {'other_user_id': otherUserId});
  }

  Future<ApiResult<Map<String, dynamic>>> privateMessages(int conversationId, {int? before, int limit = 20}) {
    final qs = before == null ? '?limit=$limit' : '?before=$before&limit=$limit';
    return _get('/api/v1/community/private/conversations/$conversationId/messages$qs');
  }

  Future<ApiResult<Map<String, dynamic>>> sendPrivateMessage(int conversationId, String message) {
    return _post('/api/v1/community/private/conversations/$conversationId/messages', {'message': message});
  }

  Future<ApiResult<Map<String, dynamic>>> uploadPrivateAttachment(int conversationId, String filePath) {
    return _upload('/api/v1/community/private/conversations/$conversationId/attachments', filePath);
  }

  Future<ApiResult<Map<String, dynamic>>> reportUser(int userId, String reason, {String context = 'profile', int? contextId}) {
    return _post('/api/v1/community/reports', {
      'reported_id': userId,
      'reason': reason,
      'context': context,
      if (contextId != null) 'context_id': contextId,
    });
  }

  Future<ApiResult<Map<String, dynamic>>> blockUser(int userId) => _post('/api/v1/community/blocks', {'blocked_id': userId});
  Future<ApiResult<Map<String, dynamic>>> blockedUsers() => _get('/api/v1/community/blocks');
  Future<ApiResult<Map<String, dynamic>>> unblockUser(int userId) => _delete('/api/v1/community/blocks/$userId');


  Future<ApiResult<Map<String, dynamic>>> quizzes() async => _get('/api/v1/quizzes');

  Future<ApiResult<Map<String, dynamic>>> quizDetails(int quizId) async => _get('/api/v1/quizzes/$quizId');

  Future<ApiResult<Map<String, dynamic>>> startQuiz(int quizId) async => _post('/api/v1/quizzes/$quizId/start', {});

  Future<ApiResult<Map<String, dynamic>>> submitQuiz(int quizId, List<Map<String, dynamic>> answers) async {
    return _post('/api/v1/quizzes/$quizId/submit', {'answers': answers});
  }

  Future<ApiResult<Map<String, dynamic>>> abandonQuiz(int quizId) async => _post('/api/v1/quizzes/$quizId/abandon', {});

  Future<ApiResult<Map<String, dynamic>>> teacherStudents({String countryCode = 'EG', required String stage, required int level}) async {
    final qs = 'country_code=${Uri.encodeQueryComponent(countryCode)}&stage=${Uri.encodeQueryComponent(stage)}&level=$level';
    return _get('/api/v1/teacher/students?$qs');
  }

  Future<ApiResult<Map<String, dynamic>>> teacherAllStudents() async {
    return _get('/api/v1/teacher/students');
  }


  Future<ApiResult<Map<String, dynamic>>> teacherConnectStudent(String identifier) async {
    return _post('/api/v1/teacher/students/connect', {'identifier': identifier});
  }

  Future<ApiResult<Map<String, dynamic>>> teacherQuizzes({String? status}) async {
    final qs = status == null || status.isEmpty ? '' : '?status=${Uri.encodeQueryComponent(status)}';
    return _get('/api/v1/teacher/quizzes$qs');
  }

  Future<ApiResult<Map<String, dynamic>>> teacherCreateQuiz(Map<String, dynamic> body) async => _post('/api/v1/teacher/quizzes', body);
  Future<ApiResult<Map<String, dynamic>>> teacherDuplicateQuiz(int quizId, {Map<String, dynamic> body = const {}}) async => _post('/api/v1/teacher/quizzes/$quizId/duplicate', body);
  Future<ApiResult<Map<String, dynamic>>> teacherPublishQuiz(int quizId, Map<String, dynamic> body) async => _post('/api/v1/teacher/quizzes/$quizId/publish', body);

  Future<ApiResult<Map<String, dynamic>>> teacherEndQuiz(int quizId) async => _post('/api/v1/teacher/quizzes/$quizId/end', {});

  Future<ApiResult<Map<String, dynamic>>> teacherDeleteQuiz(int quizId) async => _delete('/api/v1/teacher/quizzes/$quizId');

  Future<ApiResult<Map<String, dynamic>>> teacherQuizResults(int quizId) async => _get('/api/v1/teacher/quizzes/$quizId/results');

  Future<ApiResult<Map<String, dynamic>>> teacherDisconnectStudent(int studentId) async => _delete('/api/v1/teacher/students/$studentId');

  Future<ApiResult<Map<String, dynamic>>> teacherGradeAnswer(int quizId, int answerId, Map<String, dynamic> body) async {
    return _patch('/api/v1/teacher/quizzes/$quizId/answers/$answerId/grade', body);
  }

  Future<ApiResult<Map<String, dynamic>>> requestProfileChange(Map<String, dynamic> body) async {
    return _post('/api/v1/profile/change-requests', body);
  }


  Future<ApiResult<Map<String, dynamic>>> adminMe() async => _get('/api/v1/admin/me');
  Future<ApiResult<Map<String, dynamic>>> adminUsers({String q = '', String role = '', String status = '', int limit = 50}) async {
    final params = <String, String>{'limit': '$limit'};
    if (q.trim().isNotEmpty) params['q'] = q.trim();
    if (role.trim().isNotEmpty) params['role'] = role.trim();
    if (status.trim().isNotEmpty) params['status'] = status.trim();
    return _get('/api/v1/admin/users?${Uri(queryParameters: params).query}');
  }
  Future<ApiResult<Map<String, dynamic>>> adminUserDetails(int userId) async => _get('/api/v1/admin/users/$userId');
  Future<ApiResult<Map<String, dynamic>>> adminUpdateUser(int userId, Map<String, dynamic> body) async => _patch('/api/v1/admin/users/$userId', body);
  Future<ApiResult<Map<String, dynamic>>> adminResetUserPassword(int userId, String newPassword, String reason, {bool forceLogout = true}) async {
    return _post('/api/v1/admin/users/$userId/reset-password', {
      'new_password': newPassword,
      'reason': reason,
      'force_logout': forceLogout,
    });
  }
  Future<ApiResult<Map<String, dynamic>>> adminSetUserStatus(int userId, String status, {String reason = ''}) async {
    if (status == 'active') return _post('/api/v1/admin/users/$userId/activate', {'reason': reason});
    if (status == 'suspended') return _post('/api/v1/admin/users/$userId/suspend', {'reason': reason});
    if (status == 'deleted') return _post('/api/v1/admin/users/$userId/ban', {'reason': reason});
    return _patch('/api/v1/admin/users/$userId/status', {'status': status});
  }
  Future<ApiResult<Map<String, dynamic>>> adminReports({String status = ''}) async {
    final qs = status.isEmpty ? '' : '?status=${Uri.encodeQueryComponent(status)}';
    return _get('/api/v1/admin/community/reports$qs');
  }
  Future<ApiResult<Map<String, dynamic>>> adminUserChats(int userId, String reason) async {
    return _get('/api/v1/admin/community/users/$userId/chats?reason=${Uri.encodeQueryComponent(reason)}');
  }
  Future<ApiResult<Map<String, dynamic>>> adminPrivateMessages(int conversationId, String reason) async {
    return _get('/api/v1/admin/community/private/conversations/$conversationId/messages?reason=${Uri.encodeQueryComponent(reason)}');
  }
  Future<ApiResult<Map<String, dynamic>>> adminDeletePrivateMessage(int messageId, String reason) async {
    return _deleteWithBody('/api/v1/admin/community/private/messages/$messageId', {'reason': reason});
  }
  Future<ApiResult<Map<String, dynamic>>> adminAuditLogs() async => _get('/api/v1/admin/audit-logs');
  Future<ApiResult<Map<String, dynamic>>> adminAccountDeletionRequests() async => _get('/api/v1/admin/account-deletion-requests');
  Future<ApiResult<Map<String, dynamic>>> adminReviewAccountDeletion(int requestId, String action, {String notes = ''}) async {
    return _post('/api/v1/admin/account-deletion-requests/$requestId/review', {'action': action, 'admin_notes': notes});
  }

  Future<ApiResult<Map<String, dynamic>>> myProfileChangeRequests() async => _get('/api/v1/profile/change-requests/my');

  Future<ApiResult<Map<String, dynamic>>> _get(String path) async {
    final cacheKey = path;
    try {
      final res = await http.get(await _uri(path), headers: await _headers(auth: true)).timeout(const Duration(seconds: 10));
      final decoded = _decodeMap(res);
      if (decoded.ok && decoded.data != null) await _sessionStore.setCache(cacheKey, jsonEncode(decoded.data));
      if (!decoded.ok) {
        final cached = await _sessionStore.getCache(cacheKey);
        if (cached != null) return ApiResult.success(Map<String, dynamic>.from(jsonDecode(cached) as Map));
      }
      return decoded;
    } catch (e) {
      final cached = await _sessionStore.getCache(cacheKey);
      if (cached != null) return ApiResult.success(Map<String, dynamic>.from(jsonDecode(cached) as Map));
      return const ApiResult.failure('Connection problem. Please try again.');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(await _uri(path), headers: await _headers(auth: true), body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
      return _decodeMap(res);
    } catch (e) {
      return const ApiResult.failure('Connection problem. Please try again.');
    }
  }


  Future<ApiResult<Map<String, dynamic>>> _patch(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .patch(await _uri(path), headers: await _headers(auth: true), body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
      return _decodeMap(res);
    } catch (e) {
      return const ApiResult.failure('Connection problem. Please try again.');
    }
  }


  Future<ApiResult<Map<String, dynamic>>> _delete(String path) async {
    try {
      final res = await http
          .delete(await _uri(path), headers: await _headers(auth: true))
          .timeout(const Duration(seconds: 20));
      return _decodeMap(res);
    } catch (e) {
      return const ApiResult.failure('Connection problem. Please try again.');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> _deleteWithBody(String path, Map<String, dynamic> body) async {
    try {
      final request = http.Request('DELETE', await _uri(path));
      request.headers.addAll(await _headers(auth: true));
      request.body = jsonEncode(body);
      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final res = await http.Response.fromStream(streamed);
      return _decodeMap(res);
    } catch (e) {
      return const ApiResult.failure('Connection problem. Please try again.');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> _upload(String path, String filePath) async {
    try {
      final request = http.MultipartRequest('POST', await _uri(path));
      final token = await _sessionStore.getToken();
      if (token != null && token.isNotEmpty) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      return _decodeMap(res);
    } catch (e) {
      return const ApiResult.failure('Connection problem. Please try again.');
    }
  }

  ApiResult<Map<String, dynamic>> _decodeMap(http.Response res) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
      if (res.statusCode >= 200 && res.statusCode < 300 && map['ok'] != false) return ApiResult.success(map);
      return ApiResult.failure(map['error']?.toString() ?? map['message']?.toString() ?? 'HTTP ${res.statusCode}');
    } catch (_) {
      return ApiResult.failure('Bad response from server: ${res.statusCode}');
    }
  }
}
