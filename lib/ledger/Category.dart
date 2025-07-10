import 'package:flutter/cupertino.dart';

class Category {
  final int id;
  final int userId;
  final int? parentId;
  String categoryName;
  final String categoryType; // "income" 或 "expense"
  final DateTime createdTime;
  DateTime updatedTime;
  IconData icon;
  Color color;
  List<Category> subCategories;

  Category({
    required this.id,
    required this.userId,
    this.parentId,
    required this.categoryName,
    required this.categoryType,
    required this.createdTime,
    required this.updatedTime,
    required this.icon,
    required this.color,
    this.subCategories = const [],
  });

  // 数据库转换方法
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'parent_id': parentId,
      'category_name': categoryName,
      'category_type': categoryType,
      'created_time': createdTime.toIso8601String(),
      'updated_time': DateTime.now().toIso8601String(),
      'icon_code': icon.codePoint.toString(),
      'color_value': color.value.toString(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      userId: map['user_id'],
      parentId: map['parent_id'],
      categoryName: map['category_name'],
      categoryType: map['category_type'],
      createdTime: DateTime.parse(map['created_time']),
      updatedTime: DateTime.parse(map['updated_time']),
      icon: IconData(int.parse(map['icon_code'] ?? '58136'), fontFamily: 'MaterialIcons'),
      color: Color(int.parse(map['color_value'] ?? '4294198070')),
      subCategories: [],
    );
  }

  // 判断是收入还是支出的辅助方法
  bool get isIncome => categoryType == 'income';
}