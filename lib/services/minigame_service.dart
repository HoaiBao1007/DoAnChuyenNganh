// lib/services/minigame_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../models/minigame_history.dart';

class MinigameService {
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }

  /// POST /minigame/daily-reward/{userId}
  Future<String> claimDailyReward() async {
    final userId = await _getUserId();
    if (userId == null) {
      throw Exception("Bạn chưa đăng nhập");
    }

    final http.Response res = await ApiClient.post(
      ApiClient.MINIGAME_API_BASE_URL,
      "/minigame/daily-reward/$userId",
      {}, // body rỗng, backend sẽ bỏ qua
      withAuth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Lỗi nhận thưởng đăng nhập [${res.statusCode}]");
    }

    // Backend trả plain text: "Nhận quà đăng nhập thành công! +10 điểm"
    return res.body.toString();
  }

  /// POST /minigame/spin/{userId}
  Future<String> spinWheel() async {
    final userId = await _getUserId();
    if (userId == null) {
      throw Exception("Bạn chưa đăng nhập");
    }

    final http.Response res = await ApiClient.post(
      ApiClient.MINIGAME_API_BASE_URL,
      "/minigame/spin/$userId",
      {},
      withAuth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Lỗi quay vòng quay [${res.statusCode}]");
    }

    // Ví dụ: "🎉 Chúc mừng! Bạn nhận được 20 điểm!"
    return res.body.toString();
  }

  /// GET /minigame/history/{userId}
  Future<List<MinigameHistory>> getHistory() async {
    final userId = await _getUserId();
    if (userId == null) {
      throw Exception("Bạn chưa đăng nhập");
    }

    final res = await ApiClient.get(
      ApiClient.MINIGAME_API_BASE_URL,
      "/minigame/history/$userId",
      withAuth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Lỗi tải lịch sử minigame [${res.statusCode}]");
    }

    // API trả về mảng JSON []
    final List<dynamic> list = jsonDecode(res.body);
    return list
        .map((e) => MinigameHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 🔥 ĐỔI ĐIỂM LẤY VOUCHER
  /// POST /minigame/api/v1/rewards/{userId}/redeem?code=SALE10
  Future<void> redeemVoucher({required String code}) async {
    final userId = await _getUserId();
    if (userId == null) {
      throw Exception("Bạn chưa đăng nhập");
    }

    final http.Response res = await ApiClient.post(
      ApiClient.MINIGAME_API_BASE_URL,
      "/minigame/api/v1/rewards/$userId/redeem?code=$code",
      {}, // body rỗng
      withAuth: true,
    );

    final status = res.statusCode;
    final body = res.body.toString();
    print("REDEEM VOUCHER RES[$status] ← $body");

    if (status >= 200 && status < 300) {
      // Backend trả "1" => coi như thành công
      return;
    }

    if (status == 500) {
      // Backend dùng 500 khi thiếu điểm
      throw Exception("Bạn không đủ điểm để đổi voucher này.");
    }

    throw Exception("Lỗi đổi voucher [$status]: $body");
  }
}
