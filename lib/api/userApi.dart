

import '../utils/http_client.dart';

class UserApi {
  // 单例模式
  static final UserApi _instance = UserApi._internal();
  final HttpClient _httpClient;

  // 工厂构造函数，返回单例实例
  factory UserApi() => _instance;

  // 私有构造函数，只在内部使用
  UserApi._internal() : _httpClient = HttpClient();


  // 检查用户是否已登录
  Future<bool> checkLoginStatus() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>('/auth/validate');
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // 检查用户是否已登录
  Future<bool> register(data) async {
    try {
      final response = await _httpClient.post("/auth/account/register", data: data);
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
  // 用户登录
  Future<String> login(data) async {
    try {
      final response = await _httpClient.post("/auth/account/login", data: data);
      return response['data'];
    } catch (e) {
      return "";
    }
  }

}