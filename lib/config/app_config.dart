// lib/config/app_config.dart
class AppConfig {
  static const String devBaseUrl = 'http://10.0.2.2:9000'; // 开发环境(模拟器)
  static const String testBaseUrl = 'http://测试服务器地址';  // 测试环境
  static const String prodBaseUrl = 'http://120.78.0.54:9653'; // 生产环境

  // 根据构建模式或自定义标志获取baseUrl
  static String get baseUrl {
    const String environment = String.fromEnvironment(
        'ENVIRONMENT',
        defaultValue: 'dev'
    );

    switch (environment) {
      case 'prod':
        return prodBaseUrl;
      case 'test':
        return testBaseUrl;
      default:
        return devBaseUrl;
    }
  }
}