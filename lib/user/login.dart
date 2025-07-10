import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_mate_flutter/api/userApi.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: '用户名'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '密码'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // 登录逻辑
                UserApi().login({
                  'username': _usernameController.text,
                  'password': _passwordController.text,
                }).then((token) {
                  if (token.isNotEmpty) {
                    //把token 保存到SharedPreferences
                    final prefs = SharedPreferences.getInstance();
                    prefs.then((sharedPrefs) {
                      sharedPrefs.setString('token', token);
                    });
                    context.go('/home');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('登录失败，请检查用户名和密码')),
                    );
                  }
                });
              },
              child: const Text('登录'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.push('/register');
              },
              child: const Text('没有账号？去注册'),
            ),
          ],
        ),
      ),
    );
  }
}