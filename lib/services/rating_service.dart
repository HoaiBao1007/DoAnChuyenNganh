// lib/services/rating_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../models/rating_response.dart';
import '../models/rating_summary.dart';   // ✅ dùng RatingSummary

class RatingService {
  /// POST /products/{productId}/ratings
  Future<void> createRating({
    required int productId,
    required double ratingValue,
    String? comment,
  }) async {
    final body = {
      "ratingValue": ratingValue,
      if (comment != null && comment.trim().isNotEmpty)
        "comment": comment.trim(),
    };

    final http.Response res = await ApiClient.post(
      ApiClient.PRODUCT_API_BASE_URL,
      "/products/$productId/ratings",
      body,
      withAuth: true,
    );

    final status = res.statusCode;
    if (status < 200 || status >= 300) {
      final json = jsonDecode(res.body);
      final msg = json['message']?.toString() ?? 'Unknown error';
      throw Exception("Lỗi gửi đánh giá [$status]: $msg");
    }
  }

  /// GET /products/{productId}/ratings
  Future<List<RatingResponse>> getRatings(int productId) async {
    final res = await ApiClient.get(
      ApiClient.PRODUCT_API_BASE_URL,
      "/products/$productId/ratings",
      withAuth: false,
    );

    final status = res.statusCode;
    if (status < 200 || status >= 300) {
      throw Exception("Lỗi tải danh sách đánh giá [$status]");
    }

    final List<dynamic> list = jsonDecode(res.body);
    return list
        .map((e) => RatingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /products/{productId}/rating-summary
  /// → Trả về model RatingSummary (file rating_summary.dart)
  Future<RatingSummary> getRatingSummary(int productId) async {
    final res = await ApiClient.get(
      ApiClient.PRODUCT_API_BASE_URL,
      "/products/$productId/rating-summary",
      withAuth: false,
    );

    final status = res.statusCode;
    if (status < 200 || status >= 300) {
      throw Exception("Lỗi tải tổng quan đánh giá [$status]");
    }

    final Map<String, dynamic> json = jsonDecode(res.body);
    return RatingSummary.fromJson(json);   // ✅ đúng kiểu
  }

  /// DELETE /products/{productId}/my/{ratingId}
  Future<void> deleteMyRating({
    required int productId,
    required int ratingId,
  }) async {
    final res = await ApiClient.delete(
      ApiClient.PRODUCT_API_BASE_URL,
      "/products/$productId/my/$ratingId",
      withAuth: true,
    );

    final status = res.statusCode;
    if (status < 200 || status >= 300) {
      throw Exception("Lỗi xoá đánh giá [$status]");
    }
  }
}
