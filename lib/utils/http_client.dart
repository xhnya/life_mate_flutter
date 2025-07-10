// lib/utils/http_client.dart
import 'package:dio/dio.dart';
import 'package:life_mate_flutter/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  late final Dio _dio;

  // 单例模式
  factory HttpClient() => _instance;

  HttpClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));

    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 获取token并添加到请求头
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // token过期，清除本地存储
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          // 可以在这里添加重定向到登录页的逻辑
        }
        return handler.next(e);
      },
    ));

    // 添加日志拦截器，方便调试
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  // 封装GET请求
  Future<T> get<T>(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 封装POST请求
  Future<T> post<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 封装PUT请求
  Future<T> put<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 封装DELETE请求
  Future<T> delete<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 统一错误处理
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return Exception('连接超时');
        case DioExceptionType.sendTimeout:
          return Exception('请求超时');
        case DioExceptionType.receiveTimeout:
          return Exception('响应超时');
        case DioExceptionType.badResponse:
          return Exception('服务器错误: ${error.response?.statusCode}');
        case DioExceptionType.cancel:
          return Exception('请求取消');
        default:
          return Exception('网络错误: ${error.message}');
      }
    } else {
      return Exception('未知错误: $error');
    }
  }


}