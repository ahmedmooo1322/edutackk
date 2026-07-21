import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient(this._tokens) : _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl, connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 20), headers: {'Content-Type': 'application/json'}));
  final TokenStore _tokens;
  final Dio _dio;

  Future<Map<String, dynamic>> get(String path) => _request(() => _dio.get(path));
  Future<Map<String, dynamic>> post(String path, {Object? data}) => _request(() => _dio.post(path, data: data));
  Future<Map<String, dynamic>> patch(String path, {Object? data}) => _request(() => _dio.patch(path, data: data));

  Future<Map<String, dynamic>> _request(Future<Response<dynamic>> Function() call) async {
    final token = await _tokens.accessToken();
    if (token != null) _dio.options.headers['Authorization'] = 'Bearer $token'; else _dio.options.headers.remove('Authorization');
    try {
      final response = await call();
      final body = Map<String, dynamic>.from(response.data as Map);
      return Map<String, dynamic>.from(body['data'] as Map? ?? const {});
    } on DioException catch (error) {
      final body = error.response?.data;
      final details = body is Map ? body['error'] : null;
      throw ApiException(details is Map ? (details['message'] as String? ?? 'حدث خطأ في الاتصال') : 'تعذر الاتصال بالخادم', code: details is Map ? details['code'] as String? : null, statusCode: error.response?.statusCode);
    }
  }
}

