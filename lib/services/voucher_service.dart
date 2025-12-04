// lib/services/voucher_service.dart

import 'dart:convert';
import 'package:do_an_chuyen_nganh/models/VoucherResponse.dart';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';

class VoucherService {
  /// ============================================
  /// 1) LẤY TOÀN BỘ VOUCHER (PUBLIC)
  /// ============================================
  Future<List<VoucherResponse>> getAllVouchers() async {
    final http.Response res = await ApiClient.get(
      ApiClient.VOUCHER_API_BASE_URL,
      "/voucher/vouchers",
      withAuth: false, // API bạn cho không cần token
    );

    final status = res.statusCode;
    print("GET ALL VOUCHERS RES[$status] ← ${res.body}");

    if (status < 200 || status >= 300) {
      throw Exception("Lỗi tải danh sách voucher [$status]");
    }

    final List<dynamic> jsonList = jsonDecode(res.body);
    return jsonList
        .map((e) => VoucherResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ============================================
  /// 2) LẤY DANH SÁCH VOUCHER CÓ THỂ DÙNG CỦA USER
  /// ============================================
  Future<List<VoucherResponse>> getAvailableVouchers(String userId) async {
    final http.Response res = await ApiClient.get(
      ApiClient.VOUCHER_API_BASE_URL,
      "/voucher/vouchers/user/$userId/available",
      withAuth: true, // cần token
    );

    final status = res.statusCode;
    print("GET AVAILABLE VOUCHERS RES[$status] ← ${res.body}");

    if (status < 200 || status >= 300) {
      throw Exception("Lỗi tải danh sách voucher khả dụng [$status]");
    }

    final List<dynamic> jsonList = jsonDecode(res.body);
    return jsonList
        .map((e) => VoucherResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
