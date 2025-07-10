import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_mate_flutter/ledger/LedgerAccountingPage.dart';
import 'package:life_mate_flutter/ledger/ledger_category_management_page.dart';
import 'package:life_mate_flutter/main.dart';
import 'package:life_mate_flutter/profile/profile_page.dart';
import 'package:life_mate_flutter/user/LoginChoice.dart';
import 'package:life_mate_flutter/user/login.dart';
import 'package:life_mate_flutter/user/register.dart';
import 'package:shared_preferences/shared_preferences.dart';



class AppRouter {
  // 根导航器键
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // 检查登录状态
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    // 这里可以加入更详细的token验证逻辑
    return token != null;
  }

  // 路由守卫
  static Future<String?> _authRedirect(BuildContext context, GoRouterState state) async {
    final isLoggedIn = await isUserLoggedIn();

    // 需要登录权限的页面
    final isAuthRequired = state.matchedLocation.startsWith('/home');

    // 已登录用户访问登录页面时重定向到首页
    if ((state.matchedLocation == '/' || state.matchedLocation == '/login') &&
        isLoggedIn) {
      return '/home';
    }

    // 未登录用户访问需要权限的页面时重定向到登录页面
    if (isAuthRequired && !isLoggedIn) {
      return '/login';
    }

    return null;
  }

  // 路由配置
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: _authRedirect,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginChoicePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginChoicePage(),
      ),
      GoRoute(
        path: '/loginForm',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MyHomePage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/ledgerAccount',
        builder: (context, state) => const LegerAccountingPage(),
      ),
      // 在路由配置中添加
      GoRoute(
        path: '/ledgerAccount/categories',
        builder: (context, state) => const CategoryManagementPage(),
      ),
    ],
  );
}