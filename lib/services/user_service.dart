// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

class UserService {
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }

  /// Cập nhật name, email, password theo API:
  /// PUT /user/users/{userId}
  /// Body JSON: { "password": "...", "name": "...", "email": "..." }
  Future<void> updateProfile({
    required String name,
    required String email,
    String? password, // có thể null / rỗng -> không đổi
  }) async {
    final userId = await _getUserId();
    if (userId == null) {
      throw Exception("Không tìm thấy userId. Vui lòng đăng nhập lại.");
    }

    // chỉ gửi field có giá trị
    final Map<String, dynamic> body = {
      "name": name.trim(),
      "email": email.trim(),
    };
    if (password != null && password.trim().isNotEmpty) {
      body["password"] = password.trim();
    }

    final http.Response res = await ApiClient.put(
      ApiClient.USER_API_BASE_URL,          // "http://192.168.1.2:8080"
      "/user/users/$userId",
      body,
      withAuth: true,
    );

    final status = res.statusCode;
    final raw = res.body;
    print("UPDATE PROFILE RES[$status] ← $raw");

    if (status < 200 || status >= 300) {
      throw Exception("Lỗi cập nhật tài khoản [$status]");
    }

    // parse lại để lưu name/email mới vào SharedPreferences (nếu muốn)
    try {
      final data = jsonDecode(raw);
      final result = data["result"];
      if (result is Map<String, dynamic>) {
        final prefs = await SharedPreferences.getInstance();
        if (result["email"] != null) {
          prefs.setString("email", result["email"].toString());
        }
        if (result["name"] != null) {
          prefs.setString("name", result["name"].toString());
        }
      }
    } catch (_) {
      // parse lỗi cũng không sao, vì API đã trả 200
    }
  }
}
