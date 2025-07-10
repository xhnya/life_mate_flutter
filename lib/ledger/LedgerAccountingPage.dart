// lib/pages/accounting_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LegerAccountingPage extends StatelessWidget {
  const LegerAccountingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记账管理'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('分类管理'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/ledgerAccount/categories'),
          ),
          // 其他记账相关选项...
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('账单记录'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/ledgerAccount/records'),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
