import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'HomePage.dart';
import 'LoginChoice.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // 从本地存储获取token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = false;
        });
        return;
      }

      // 发送请求验证token
      try {
        final response = await _dio.get(
          'https://你的服务器地址/api/auth/validate',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );

        setState(() {
          _isLoading = false;
          _isLoggedIn = response.statusCode == 200 && response.data['success'] == true;
        });

        if (!_isLoggedIn) {
          // token无效，清除本地存储
          await prefs.remove('token');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = false;
        });
        print('登录验证失败: $e');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
      print('检查登录状态出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _isLoading
          ? const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      )
          : (_isLoggedIn ? const MyHomePage() : const LoginChoicePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    Center(child: Text('搜索页')),
    Center(child: Text('我的页')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '搜索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}