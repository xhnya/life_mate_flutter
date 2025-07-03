import 'package:flutter/material.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _messages = [
    '欢迎来到Life Mate！',
    '今日有3条新通知',
    '记得完成每日打卡哦~',
    '明天有活动，别错过！',
    '快去看看新朋友吧！',
  ];
  late List<String> _displayMessages;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _displayMessages = List.from(_messages)..addAll(_messages.take(3));
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      if (_currentIndex < _messages.length) {
        setState(() {
          _currentIndex++;
        });
        _scrollController.animateTo(
          _currentIndex * 28.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      if (_currentIndex == _messages.length) {
        Future.delayed(const Duration(milliseconds: 450), () {
          if (!mounted) return;
          setState(() {
            _currentIndex = 0;
          });
          _scrollController.jumpTo(0);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Widget buildIconCard({required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 64,
        height: 64,
        child: IconButton(
          icon: Icon(icon, color: color, size: 36),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      ),
    );
  }

  Widget buildSmallCard() {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: AspectRatio(
          aspectRatio: 1, // 保证正方形
          child: Center(child: Container()), // 内容留空
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SizedBox(
                  height: 28.0 * 3,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _displayMessages.length,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        height: 28.0,
                        child: Center(
                          child: Text(
                            _displayMessages[index],
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildIconCard(
                    icon: Icons.check_circle,
                    color: Colors.blue,
                    tooltip: '打卡',
                    onPressed: () {},
                  ),
                  buildIconCard(
                    icon: Icons.notifications,
                    color: Colors.orange,
                    tooltip: '通知',
                    onPressed: () {},
                  ),
                  buildIconCard(
                    icon: Icons.people,
                    color: Colors.green,
                    tooltip: '好友',
                    onPressed: () {},
                  ),
                  buildIconCard(
                    icon: Icons.event,
                    color: Colors.purple,
                    tooltip: '活动',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // 两行小卡片
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      buildSmallCard(),
                      const SizedBox(width: 12),
                      buildSmallCard(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      buildSmallCard(),
                      const SizedBox(width: 12),
                      buildSmallCard(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        // 悬浮按钮
        Positioned(
          right: 24,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'add',
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'mic',
                onPressed: () {},
                child: const Icon(Icons.mic),
              ),
            ],
          ),
        ),
      ],
    );
  }
}