import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:life_mate_flutter/api/systemApi.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfilePage extends StatefulWidget {

  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _versionNumber = 'v0.0.0'; // 默认版本号
  String _buildNumber = '0';
  final SystemApi _systemApi = SystemApi();
  @override
  void initState() {
    super.initState();
    _getVersionInfo();
  }
  Future<void> _getVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _versionNumber = 'v${packageInfo.version}';
      // 如果需要构建号，可以添加：+${packageInfo.buildNumber}
      _buildNumber = packageInfo.buildNumber;
    });
  }
  Future<void> _checkForUpdates() async {
    try {
      // 使用SystemApi获取最新版本信息
      final latestVersionData = await _systemApi.getLastVersion();

      if (latestVersionData.isEmpty) {
        throw Exception('获取版本信息失败');
      }

      // 根据接口返回的数据结构获取版本信息
      final String latestBuildNumber = latestVersionData['buildNumber']?.toString() ?? '0';
      final String latestVersion = latestVersionData['version']?.toString() ?? '';

      // 比较构建号(构建号通常是整数，所以转换后比较)
      final int currentBuild = int.parse(_buildNumber);
      final int latestBuild = int.parse(latestBuildNumber);

      if (latestBuild > currentBuild) {
        _showUpdateDialog(latestVersion, latestVersionData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('当前已是最新版本'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('检查更新失败: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showUpdateDialog(String version, Map versionData) {
    // 从版本数据中获取更新日志
    final String changeLog = versionData['changelog'] ?? '暂无更新内容';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发现新版本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('有新版本 v$version 可用，是否立即更新？'),
            const SizedBox(height: 16),
            const Text('更新内容：', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // 使用约束和滚动视图，防止更新日志过长撑破对话框
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(changeLog),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后再说'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final String downloadUrl = versionData['downloadUrl'] ?? '';
              _startDownload(downloadUrl);
            },
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
  }


  Future<bool> _requestStoragePermission() async {
    // Android 13+ (API 33+) 使用更精细的权限
    if (Platform.isAndroid && await DeviceInfoPlugin().androidInfo.then((info) => info.version.sdkInt >= 33)) {
      final status = await [
        Permission.photos,
        Permission.videos,
      ].request();

      return status.values.every((s) => s.isGranted);
    }
    // Android 11-12 (API 30-32)
    else if (Platform.isAndroid && await DeviceInfoPlugin().androidInfo.then((info) => info.version.sdkInt >= 30)) {
      // 对于 Android 11+，需要请求所有文件访问权限
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    // Android 10及以下 (API 29-)
    else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<bool> _canInstallApk() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 26) {
        final status = await Permission.requestInstallPackages.status;
        if (status.isGranted) return true;
        final result = await Permission.requestInstallPackages.request();
        if (result.isGranted) return true;
        // 用 package_info_plus 获取包名
        final packageInfo = await PackageInfo.fromPlatform();
        final intent = AndroidIntent(
          action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
          data: 'package:${packageInfo.packageName}',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
        return false;
      }
    }
    return true;
  }

  /// 开始下载更新
  Future<void> _startDownload(String downloadUrl) async {
    if (downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下载链接不可用'), duration: Duration(seconds: 2)),
      );
      return;
    }

    // 请求存储权限
    if (!await _requestStoragePermission()) {
      // 检查是否永久拒绝了权限
      bool isPermanentlyDenied = false;

      if (Platform.isAndroid && await DeviceInfoPlugin().androidInfo.then((info) => info.version.sdkInt >= 30)) {
        isPermanentlyDenied = await Permission.manageExternalStorage.isPermanentlyDenied;
      } else {
        isPermanentlyDenied = await Permission.storage.isPermanentlyDenied;
      }

      if (isPermanentlyDenied) {
        // 显示引导用户到设置的对话框
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('需要存储权限'),
            content: const Text('请在设置中开启存储权限，否则无法下载更新'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();  // 打开应用设置页面
                },
                child: const Text('去设置'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要存储权限来下载更新'), duration: Duration(seconds: 2)),
        );
      }
      return;
    }

    // 创建一个函数引用，用于更新进度
    void Function(double)? updateProgress;

    // 创建进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        double progress = 0;
        return StatefulBuilder(
          builder: (context, setState) {
            // 保存更新函数引用，供下载回调使用
            updateProgress = (value) {
              setState(() {
                progress = value;
              });
            };

            return AlertDialog(
              title: const Text('正在下载更新'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 10),
                  Text('${(progress * 100).toStringAsFixed(0)}%'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      // 获取应用目录来存储文件 - 使用外部存储而非内部存储
      Directory? externalDir;
      if (Platform.isAndroid) {
        externalDir = await getExternalStorageDirectory();
      } else {
        externalDir = await getApplicationDocumentsDirectory();
      }

      if (externalDir == null) {
        throw Exception('无法获取存储目录');
      }

      String savePath = '${externalDir.path}/update.apk';
      print('下载APK到路径: $savePath');

      // 创建Dio实例
      Dio dio = Dio();

      // 开始下载
      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            if (updateProgress != null) {
              updateProgress!(progress);
            }
          }
        },
      );

      // 下载完成，关闭对话框
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // 检查文件是否存在和大小是否正确
      File file = File(savePath);
      if (!await file.exists()) {
        throw Exception('下载完成，但文件不存在');
      }

      int fileSize = await file.length();
      if (fileSize <= 0) {
        throw Exception('文件大小异常: $fileSize 字节');
      }

      print('APK已下载，大小: ${fileSize}字节');

      // 提示安装
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下载完成，准备安装'), duration: Duration(seconds: 2)),
      );
      if (!await _canInstallApk()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请授权允许安装未知来源应用'), duration: Duration(seconds: 2)),
        );
        return;
      }

      // 延迟一小段时间再打开，确保UI更新完成
      await Future.delayed(const Duration(milliseconds: 500));

      // 打开APK进行安装，并检查返回结果
      final result = await OpenFile.open(savePath);
      if (result.type != ResultType.done) {
        throw Exception('安装失败: ${result.message}');
      }

    } catch (e) {
      // 下载或安装出错，关闭对话框并显示错误
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      print('下载或安装过程中出现错误: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('安装失败: $e'), duration: const Duration(seconds: 3)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildProfileHeader(),
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 16),
                _buildSettingItem(
                  context,
                  '软件更新',
                  Icons.system_update,
                      () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('正在检查更新...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    _checkForUpdates(); // 调用更新检查逻辑
                  },
                  trailing: _buildVersionInfo(),
                ),
                const Divider(),
                _buildSettingItem(
                  context,
                  '账户设置',
                  Icons.person_outline,
                      () {},
                ),
                _buildSettingItem(
                  context,
                  '通知设置',
                  Icons.notifications_none,
                      () {},
                ),
                _buildSettingItem(
                  context,
                  '关于',
                  Icons.info_outline,
                      () {},
                ),
                _buildSettingItem(
                  context,
                  '退出登录',
                  Icons.logout,
                      () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 修改现有方法
  Widget _buildVersionInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _versionNumber,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      color: Colors.blue.shade50,
      child: Center(
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50, color: Colors.white),
              backgroundColor: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              '用户名',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '账号ID: 12345678',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade700),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}