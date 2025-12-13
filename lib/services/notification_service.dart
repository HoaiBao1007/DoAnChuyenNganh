// lib/services/notification_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import 'auth_service.dart';

class NotificationService {
  final String baseUrl = 'http://192.168.110.18:8085';
  final AuthService _authService = AuthService();

  /// Lấy danh sách thông báo của user hiện tại
  Future<List<AppNotification>> getMyNotifications() async {
    final token = await _authService.getToken();
    final userId = await _authService.getUserId();

    print("NotificationService -> token=$token, userId=$userId");

    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập');
    }
    if (userId == null || userId.isEmpty) {
      throw Exception('Không tìm thấy userId, vui lòng đăng nhập lại');
    }

    final uri = Uri.parse('$baseUrl/notifications/$userId');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi lấy thông báo: ${response.statusCode}');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> listJson = data['result'] ?? [];

    return listJson
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }



  /// Đánh dấu 1 thông báo là đã đọc
  Future<void> markAsRead(int notificationId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Chưa đăng nhập');

    final uri = Uri.parse('$baseUrl/notifications/$notificationId/read');

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: '1', // giống như bạn test Postman
    );

    if (response.statusCode != 204) {
      throw Exception('Lỗi đánh dấu đã đọc: ${response.statusCode}');
    }
  }
}
