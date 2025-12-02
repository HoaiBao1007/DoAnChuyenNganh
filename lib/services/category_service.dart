import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../models/category.dart';

class CategoryService {
  Future<List<Category>> getCategories() async {
    final http.Response res = await ApiClient.get(
      ApiClient.PRODUCT_API_BASE_URL,
      "/categories",
    );

    if (res.statusCode != 200) {
      throw Exception("Không thể tải danh sách danh mục (${res.statusCode})");
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! List) {
      throw Exception("Dữ liệu danh mục không đúng định dạng");
    }

    return decoded
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
