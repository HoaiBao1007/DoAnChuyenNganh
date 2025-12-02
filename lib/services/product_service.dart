// lib/services/product_service.dart
import 'dart:convert';

import '../api/api_client.dart';
import '../models/product.dart';

class ProductService {
  // =============== HÀM HỖ TRỢ: PARSE LIST PRODUCT TỪ /products ===============
  List<Product> _parsePagedProducts(String body, int statusCode, String ctx) {
    if (body.isEmpty) return [];

    dynamic json;
    try {
      json = jsonDecode(body);
    } catch (_) {
      throw Exception("Phản hồi không hợp lệ khi $ctx (status $statusCode)");
    }

    // Trường hợp có bọc thêm ApiResponse { code, message, result }
    if (json is Map<String, dynamic> && json['code'] != null) {
      if (statusCode != 200 || json['code'] != 1000) {
        throw Exception(json['message'] ?? "Lỗi $ctx (status $statusCode)");
      }
      json = json['result']; // lấy phần result bên trong
    }

    if (json is Map<String, dynamic>) {
      // Chuẩn Spring Page: { content: [ ... ], ... }
      if (json['content'] is List) {
        final list = json['content'] as List<dynamic>;
        return list
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Một số trường hợp backend có thể trả { result: { content: [ ... ] } }
      if (json['result'] is Map<String, dynamic> &&
          (json['result'] as Map<String, dynamic>)['content'] is List) {
        final list =
        (json['result'] as Map<String, dynamic>)['content'] as List<dynamic>;
        return list
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    // Trường hợp trả thẳng list
    if (json is List) {
      return json
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  // =============== HÀM HỖ TRỢ: PARSE LIST PRODUCT TỪ /recommendations ===============
  List<Product> _parseRecommendationProducts(
      String body, int statusCode, String ctx) {
    if (body.isEmpty) return [];

    dynamic json;
    try {
      json = jsonDecode(body);
    } catch (_) {
      throw Exception("Phản hồi không hợp lệ khi $ctx (status $statusCode)");
    }

    if (json is! Map<String, dynamic>) {
      throw Exception("Dữ liệu không đúng định dạng khi $ctx");
    }

    final map = json as Map<String, dynamic>;

    if (map['code'] != null && map['code'] != 1000) {
      throw Exception(map['message'] ?? "Lỗi $ctx (status $statusCode)");
    }

    dynamic result = map['result'];

    // result là list
    if (result is List) {
      return result
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // result là page { content: [...] }
    if (result is Map<String, dynamic> && result['content'] is List) {
      final list = result['content'] as List<dynamic>;
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  // ================== LẤY TẤT CẢ SẢN PHẨM ==================
  Future<List<Product>> getProducts({int page = 0, int size = 20}) async {
    final res = await ApiClient.get(
      ApiClient.PRODUCT_API_BASE_URL,
      "/products?page=$page&size=$size",
      withAuth: false,
    );

    if (res.statusCode == 204) return [];

    return _parsePagedProducts(
      res.body,
      res.statusCode,
      "lấy danh sách sản phẩm",
    );
  }

  // ================== LẤY THEO DANH MỤC ==================
  Future<List<Product>> getProductsByCategory(
      int categoryId, {
        int page = 0,
        int size = 20,
      }) async {
    final res = await ApiClient.get(
      ApiClient.PRODUCT_API_BASE_URL,
      "/products?categoryId=$categoryId&page=$page&size=$size",
      withAuth: false,
    );

    if (res.statusCode == 204) return [];

    return _parsePagedProducts(
      res.body,
      res.statusCode,
      "lấy sản phẩm theo danh mục",
    );
  }

  // ================== GỢI Ý USER (ĐÃ ĐĂNG NHẬP) ==================
  Future<List<Product>> getUserRecommendations({int limit = 12}) async {
    final res = await ApiClient.get(
      ApiClient.PRODUCT_API_BASE_URL,
      "/recommendations/me?limit=$limit",
      withAuth: true,
    );

    if (res.statusCode == 204) return [];

    return _parseRecommendationProducts(
      res.body,
      res.statusCode,
      "lấy gợi ý user",
    );
  }

  // ================== GỢI Ý GUEST ==================
  Future<List<Product>> getGuestRecommendations({int limit = 12}) async {
    final res = await ApiClient.get(
      ApiClient.PRODUCT_API_BASE_URL,
      "/recommendations/guest?limit=$limit",
      withAuth: false,
    );

    if (res.statusCode == 204) return [];

    return _parseRecommendationProducts(
      res.body,
      res.statusCode,
      "lấy gợi ý guest",
    );
  }

  // ================== TÌM KIẾM & LỌC SẢN PHẨM ==================
  ///
  /// GET /api/v1/products
  /// Params:
  ///   q, categoryId, minPrice, maxPrice, page, size, sort
  ///   VD: sort=price,asc / price,desc / name,asc / name,desc
  Future<List<Product>> searchProducts({
    String? query,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    int page = 0,
    int size = 20,
    String? sort,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };

    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if (categoryId != null) {
      params['categoryId'] = categoryId.toString();
    }
    if (minPrice != null) {
      params['minPrice'] = minPrice.toString();
    }
    if (maxPrice != null) {
      params['maxPrice'] = maxPrice.toString();
    }
    if (sort != null && sort.isNotEmpty) {
      params['sort'] = sort;
    }

    // Dùng Uri để encode tiếng Việt chính xác
    final queryString = Uri(queryParameters: params).query;
    final path = "/products?$queryString";

    final res = await ApiClient.get(
      ApiClient.PRODUCT_API_BASE_URL,
      path,
      withAuth: false,
    );

    if (res.statusCode == 204) return [];

    return _parsePagedProducts(
      res.body,
      res.statusCode,
      "tìm sản phẩm",
    );
  }
}
