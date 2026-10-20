import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';
import '../errors/api_exception.dart';
import 'local_storage_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return ApiClient(storage);
});

class ApiClient {
  final LocalStorageService _storage;
  late final Dio _dio;

  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Dynamic baseUrl update in case user changes it
    options.baseUrl = ApiEndpoints.baseUrl;

    // Attach Bearer token if not already explicitly provided
    if (!options.headers.containsKey('Authorization')) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;

    // Handle 401 Unauthorized token refresh
    if (response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh-token') &&
        !err.requestOptions.path.contains('/auth/login') &&
        !err.requestOptions.path.contains('/auth/register')) {
      final newAccessToken = await _handleTokenRefresh();

      if (newAccessToken != null) {
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newAccessToken';

        try {
          final clonedResponse = await _dio.fetch(options);
          return handler.resolve(clonedResponse);
        } catch (retryError) {
          if (retryError is DioException) {
            return handler.reject(retryError);
          }
        }
      }
    }

    // Convert Dio error into clean, user-friendly ApiException
    final appException = _parseError(err);
    final enrichedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: appException,
      message: appException.messageToShow,
    );

    return handler.reject(enrichedError);
  }

  Future<String?> _handleTokenRefresh() async {
    if (_isRefreshing) {
      final completer = Completer<String?>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _storage.clearAuth();
        _drainQueue(null);
        return null;
      }

      final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      final res = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final data = res.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        final tokenData = data['data'] as Map<String, dynamic>;
        final newAccess = tokenData['accessToken'] as String?;
        final newRefresh = tokenData['refreshToken'] as String? ?? refreshToken;

        if (newAccess != null && newAccess.isNotEmpty) {
          await _storage.saveAuthTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          _drainQueue(newAccess);
          return newAccess;
        }
      }

      await _storage.clearAuth();
      _drainQueue(null);
      return null;
    } catch (_) {
      await _storage.clearAuth();
      _drainQueue(null);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  void _drainQueue(String? token) {
    for (final completer in _refreshQueue) {
      completer.complete(token);
    }
    _refreshQueue.clear();
  }

  ApiException _parseError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return ApiException.timeout();
    }

    if (err.type == DioExceptionType.connectionError) {
      return ApiException.networkError(err.message);
    }

    final data = err.response?.data;
    if (data is Map<String, dynamic>) {
      return ApiException.fromResponse(data, statusCode: err.response?.statusCode);
    }

    return ApiException(
      statusCode: err.response?.statusCode,
      message: err.message ?? 'Unknown error occurred.',
      messageToShow: 'Something went wrong. Please try again.',
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _extractData(response);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _extractData(response);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _extractData(response);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _extractData(response);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw _parseError(e);
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _extractData(response);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw _parseError(e);
    }
  }

  Map<String, dynamic> _extractData(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {'data': response.data};
  }
}
