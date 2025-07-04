import 'package:flutter/material.dart';
import 'package:life_mate_flutter/register.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomePage.dart';
import 'login.dart';

class LoginChoicePage extends StatefulWidget {
  const LoginChoicePage({super.key});

  @override
  State<LoginChoicePage> createState() => _LoginChoicePageState();
}

class _LoginChoicePageState extends State<LoginChoicePage> {
  final Dio _dio = Dio();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      // 从本地存储获取token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 发送请求验证token
      final response = await _dio.get(
        'https://你的服务器地址/api/auth/validate',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // 已登录，跳转到主页
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        // token无效，清除本地存储
        await prefs.remove('token');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      // 发生错误，可能是网络问题
      print('登录验证失败: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 应用图标/Logo
              const Icon(
                Icons.favorite,
                size: 100,
                color: Colors.deepPurple,
              ),

              const SizedBox(height: 32),

              // 应用名称
              const Text(
                'Life Mate',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 64),

              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('登录', style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 16),

              // 注册按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                  ),
                  child: const Text('注册', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}