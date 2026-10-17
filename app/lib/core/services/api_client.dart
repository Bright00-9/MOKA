import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thrown for any non-2xx API response, carrying the server's error code/message
/// so screens can show something meaningful instead of "Something went wrong".
class ApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;

  ApiException({required this.statusCode, required this.code, required this.message});

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Set this via --dart-define=API_BASE_URL=https://api.moka.example.com/api
/// at build time. Never hardcode environment-specific URLs in source.
const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:4000/api', // Android emulator -> host machine localhost
);

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) {
        handler.next(_mapError(e));
      },
    ));
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Dio get client => _dio;

  DioException _mapError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      final err = data['error'] as Map;
      return e.copyWith(
        error: ApiException(
          statusCode: e.response?.statusCode,
          code: (err['code'] as String?) ?? 'UNKNOWN',
          message: (err['message'] as String?) ?? 'Something went wrong',
        ),
      );
    }
    return e.copyWith(
      error: ApiException(
        statusCode: e.response?.statusCode,
        code: 'NETWORK_ERROR',
        message: e.message ?? 'Could not reach the server. Check your connection.',
      ),
    );
  }
}
