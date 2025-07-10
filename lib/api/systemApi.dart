

import 'package:life_mate_flutter/utils/http_client.dart';

class SystemApi {
  // 单例模式
  static final SystemApi _instance = SystemApi._internal();
  final HttpClient _httpClient;

  // 工厂构造函数，返回单例实例
  factory SystemApi() => _instance;

  // 私有构造函数，只在内部使用
  SystemApi._internal() : _httpClient = HttpClient();


  // 检查用户是否已登录
  Future<Map> getLastVersion() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
          '/sys/appVersion/latestVersion');
      return response['data'] ?? '';
    } catch (e) {
      return {};
    }
  }
}