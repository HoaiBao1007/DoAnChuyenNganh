// lib/services/auth_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

class AuthService {
  static const _tokenKey = "token";
  static const _usernameKey = "username";
  static const _userIdKey = "userId";

  // ==================== LOGIN ====================
  Future<void> login(String username, String password) async {
    final res = await ApiClient.post(
      ApiClient.USER_API_BASE_URL,
      "/user/auth/signin",
      {
        "username": username,
        "password": password,
      },
      withAuth: false,
    );

    print("SIGNIN RES[${res.statusCode}] ← ${res.body}");

    final data = jsonDecode(res.body);

    if (res.statusCode != 200 || data["code"] != 1000) {
      throw Exception(data["message"] ?? "Đăng nhập thất bại");
    }

    final prefs = await SharedPreferences.getInstance();

    // lấy token từ result
    final String token = data["result"]["token"];

    // lưu token + username
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);

    // ⭐ SAU KHI CÓ TOKEN → đi lấy userId thật sự
    await _fetchAndSaveUserId();
  }

  /// Gọi /user/users/myInfo để lấy thông tin user hiện tại và lưu userId (UUID)
  Future<void> _fetchAndSaveUserId() async {
    final res = await ApiClient.get(
      ApiClient.USER_API_BASE_URL,
      "/user/users/myInfo", // nếu backend bạn khác path thì đổi chỗ này
      withAuth: true,
    );

    print("MYINFO RES[${res.statusCode}] ← ${res.body}");

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data["code"] == 1000) {
      final result = data["result"];

      // tuỳ backend: thử lần lượt id / userId / user_id
      final String? userId =
      (result["id"] ?? result["userId"] ?? result["user_id"])?.toString();

      if (userId != null && userId.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userIdKey, userId);
        print("✔ SAVED USER ID = $userId");
      } else {
        print("❌ Không tìm thấy userId trong /myInfo: $result");
      }
    } else {
      print("❌ Lỗi gọi /user/users/myInfo: ${res.statusCode} → ${res.body}");
    }
  }

  // ==================== REGISTER ====================
  Future<void> register(
      String username, String email, String password) async {
    final res = await ApiClient.post(
      ApiClient.USER_API_BASE_URL,
      "/user/users/register",
      {
        "username": username,
        "password": password,
        "email": email,
        "name": username,
        "dob": "1990-01-01",
      },
      withAuth: false,
    );

    final data = jsonDecode(res.body);

    if (data["code"] != 1000) {
      throw Exception(data["message"] ?? "Đăng ký thất bại");
    }
  }

  // ==================== LOGOUT  ====================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
  }

  // Đã đăng nhập chưa?
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  // Lấy username đang đăng nhập
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Lấy token hiện tại
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Lấy userId (UUID) hiện tại
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // =================================================
  //                PROFILE / ACCOUNT
  // =================================================

  /// Model đơn giản cho thông tin user
  /// Bạn có thể mở rộng thêm name, phone... nếu backend trả về.
  UserProfile _parseUserProfile(Map<String, dynamic> json) {
    return UserProfile(
      id: (json["id"] ?? json["userId"] ?? json["user_id"]).toString(),
      username: json["username"]?.toString() ?? "",
      email: json["email"]?.toString(),
      name: json["name"]?.toString(),
    );
  }

  /// Lấy thông tin user đang đăng nhập
  /// GET /user/users/myInfo (Bearer token)
  Future<UserProfile> getMyProfile() async {
    final res = await ApiClient.get(
      ApiClient.USER_API_BASE_URL,
      "/user/users/myInfo",
      withAuth: true,
    );

    print("GET MY PROFILE RES[${res.statusCode}] ← ${res.body}");

    final data = jsonDecode(res.body);

    if (res.statusCode != 200 || data["code"] != 1000) {
      throw Exception(data["message"] ?? "Lỗi lấy thông tin tài khoản");
    }

    final result = data["result"] as Map<String, dynamic>;
    return _parseUserProfile(result);
  }

  /// Cập nhật thông tin tài khoản
  /// PUT /user/users/{userId}
  ///
  /// - Chỉ đổi email: truyền email, currentPassword/newPassword để trống
  /// - Đổi mật khẩu: truyền currentPassword + newPassword
  Future<void> updateAccount({
    required String userId,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    final body = <String, dynamic>{};

    if (email != null && email.isNotEmpty) {
      body["email"] = email;
    }
    if (currentPassword != null && currentPassword.isNotEmpty) {
      // tùy backend, có thể là "oldPassword" → nếu API bạn dùng tên đó thì sửa lại:
      body["currentPassword"] = currentPassword;
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      body["newPassword"] = newPassword;
    }

    final res = await ApiClient.put(
      ApiClient.USER_API_BASE_URL,
      "/user/users/$userId",
      body,
      withAuth: true,
    );

    print("UPDATE ACCOUNT RES[${res.statusCode}] ← ${res.body}");

    final data = jsonDecode(res.body);

    if (res.statusCode != 200 || data["code"] != 1000) {
      throw Exception(data["message"] ?? "Cập nhật tài khoản thất bại");
    }
  }
}

/// Model thông tin user dùng trong FE
class UserProfile {
  final String id;
  final String username;
  final String? email;
  final String? name;

  UserProfile({
    required this.id,
    required this.username,
    this.email,
    this.name,
  });
}
