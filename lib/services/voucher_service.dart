// lib/services/voucher_service.dart

import 'dart:convert';
import 'package:do_an_chuyen_nganh/models/VoucherResponse.dart';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';


class VoucherService {
  /// Lấy danh sách voucher có thể dùng của 1 user
  Future<List<VoucherResponse>> getAvailableVouchers(String userId) async {
    final http.Response res = await ApiClient.get(
      ApiClient.VOUCHER_API_BASE_URL,
      // ⚠ Nếu base URL của bạn đã là http://host:8089/voucher
      // thì path chỉ cần '/vouchers/user/$userId/available'
      "/voucher/vouchers/user/$userId/available",
      withAuth: true,
    );

    final status = res.statusCode;
    final body = res.body;
    print("GET AVAILABLE VOUCHERS RES[$status] ← $body");

    if (status < 200 || status >= 300) {
      throw Exception("Lỗi tải voucher [$status]");
    }

    final List<dynamic> list = jsonDecode(body);
    return list
        .map((e) => VoucherResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
