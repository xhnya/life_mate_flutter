import 'package:flutter/material.dart';
import 'package:life_mate_flutter/ledger/Category.dart';
import 'package:life_mate_flutter/api/ledgerApi.dart';
import 'package:life_mate_flutter/utils/http_client.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LedgerApi _ledgerApi = LedgerApi(HttpClient());
  List<Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _ledgerApi.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Category> get _incomeCategories => _categories.where((c) => c.categoryType == 'income').toList();
  List<Category> get _expenseCategories => _categories.where((c) => c.categoryType == 'expense').toList();

  void _addCategory(String categoryType, {int? parentId, Category? parentCategory}) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        isIncome: categoryType == 'income',
        onSave: (name, icon, color) async {
          final newCategory = Category(
            id: 0,
            userId: 1,
            parentId: parentId,
            categoryName: name,
            categoryType: categoryType,
            createdTime: DateTime.now(),
            updatedTime: DateTime.now(),
            icon: icon,
            color: color,
          );

          final success = await _ledgerApi.insertCategory(newCategory);
          if (success) {
            _loadCategories();
          }
        },
      ),
    );
  }

  void _editCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        isIncome: category.categoryType == 'income',
        initialName: category.categoryName,
        initialIcon: category.icon,
        initialColor: category.color,
        onSave: (name, icon, color) async {
          category.categoryName = name;
          category.icon = icon;
          category.color = color;
          category.updatedTime = DateTime.now();

          final success = await _ledgerApi.updateCategory(category);
          if (success) {
            _loadCategories();
          }
        },
      ),
    );
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
            category.subCategories.isNotEmpty
                ? '删除"${category.categoryName}"将同时删除其包含的${category.subCategories.length}个子分类，确定要删除吗？'
                : '确定要删除"${category.categoryName}"吗？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // 如果有子分类，需要先删除子分类
              if (category.subCategories.isNotEmpty) {
                for (var subCategory in category.subCategories) {
                  await _ledgerApi.deleteCategory(subCategory.id);
                }
              }

              final success = await _ledgerApi.deleteCategory(category.id);
              if (success) {
                _loadCategories();
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '支出分类'),
            Tab(text: '收入分类'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(_expenseCategories, 'expense'),
          _buildCategoryList(_incomeCategories, 'income'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCategory(
          _tabController.index == 1 ? 'income' : 'expense',
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, String categoryType) {
    return categories.isEmpty
        ? Center(
      child: Text(categoryType == 'income' ? '没有收入分类，点击右下角添加' : '没有支出分类，点击右下角添加'),
    )
        : ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryTile(category, categoryType);
      },
    );
  }

  Widget _buildCategoryTile(Category category, String categoryType) {
    if (category.subCategories.isNotEmpty) {
      // 有子分类，使用ExpansionTile
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: category.color,
            child: Icon(category.icon, color: Colors.white),
          ),
          title: Text(category.categoryName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editCategory(category),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteCategory(category),
              ),
            ],
          ),
          children: [
            ...category.subCategories.map((subCategory) => ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              leading: CircleAvatar(
                backgroundColor: subCategory.color,
                child: Icon(subCategory.icon, color: Colors.white),
              ),
              title: Text(subCategory.categoryName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editCategory(subCategory),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteCategory(subCategory),
                  ),
                ],
              ),
            )),
            // 添加子分类的按钮
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.add, color: Colors.grey),
              ),
              title: const Text('添加子分类'),
              onTap: () => _addCategory(categoryType, parentId: category.id, parentCategory: category),
            ),
          ],
        ),
      );
    } else {
      // 无子分类，使用普通ListTile
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: category.color,
            child: Icon(category.icon, color: Colors.white),
          ),
          title: Text(category.categoryName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editCategory(category),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteCategory(category),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _addCategory(categoryType, parentId: category.id, parentCategory: category),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class CategoryDialog extends StatefulWidget {
  final bool isIncome;
  final String? initialName;
  final IconData? initialIcon;
  final Color? initialColor;
  final Function(String name, IconData icon, Color color) onSave;

  const CategoryDialog({
    super.key,
    required this.isIncome,
    this.initialName,
    this.initialIcon,
    this.initialColor,
    required this.onSave,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;

  final List<IconData> _commonIcons = [
    Icons.restaurant, Icons.shopping_bag, Icons.directions_bus,
    Icons.home, Icons.medical_services, Icons.school, Icons.sports_basketball,
    Icons.work, Icons.card_giftcard, Icons.attach_money, Icons.savings,
  ];

  final List<Color> _commonColors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedIcon = widget.initialIcon ?? _commonIcons.first;
    _selectedColor = widget.initialColor ?? _commonColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ?
      '添加${widget.isIncome ? "收入" : "支出"}分类' : '编辑分类'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '分类名称',
                hintText: '请输入分类名称',
              ),
            ),
            const SizedBox(height: 16),
            const Text('选择图标'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonIcons.map((icon) {
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: CircleAvatar(
                    backgroundColor: _selectedIcon == icon ?
                    _selectedColor : Colors.grey.shade200,
                    child: Icon(icon, color: _selectedIcon == icon ?
                    Colors.white : Colors.black),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('选择颜色'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonColors.map((color) {
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  child: CircleAvatar(
                    backgroundColor: color,
                    child: _selectedColor == color ?
                    const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              widget.onSave(_nameController.text.trim(), _selectedIcon, _selectedColor);
              Navigator.pop(context);
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}