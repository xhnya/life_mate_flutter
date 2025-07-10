

import 'package:life_mate_flutter/ledger/Category.dart';
import 'package:life_mate_flutter/utils/http_client.dart';
class LedgerApi {
  final HttpClient _httpClient;

  LedgerApi(this._httpClient);

  // 获取所有分类
  Future<List<Category>> getCategories() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>('/ledger/category/list');
      final List<dynamic> categoriesData = response['data'] ?? [];
      return _buildCategoryHierarchy(categoriesData.map((e) => Category.fromMap(e)).toList());
    } catch (e) {
      return [];
    }
  }

  // 添加分类
  Future<bool> insertCategory(Category category) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/ledger/category/add',
        data: category.toMap(),
      );
      return response['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  // 更新分类
  Future<bool> updateCategory(Category category) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/ledger/category/update',
        data: category.toMap(),
      );
      return response['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  // 删除分类
  Future<bool> deleteCategory(int categoryId) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/ledger/category/delete',
        data: {'id': categoryId},
      );
      return response['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  // 构建分类层次结构
  List<Category> _buildCategoryHierarchy(List<Category> flatCategories) {
    // 父分类列表
    final List<Category> rootCategories = flatCategories
        .where((category) => category.parentId == null)
        .toList();

    // 为每个父分类找到子分类
    for (var parent in rootCategories) {
      parent.subCategories = flatCategories
          .where((category) => category.parentId == parent.id)
          .toList();
    }

    return rootCategories;
  }
}