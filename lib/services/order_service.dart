// lib/services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../models/create_order_request.dart';
import '../models/order_response.dart';

class OrderService {
  /// Tạo đơn hàng mới dựa trên giỏ hàng hiện tại của user
  Future<OrderResponse> createOrder(CreateOrderRequest req) async {
    final http.Response res = await ApiClient.post(
      ApiClient.ORDER_API_BASE_URL,
      "/orders",
      req.toJson(),
      withAuth: true,
    );

    final status = res.statusCode;
    final body = res.body;
    print("ORDER CREATE RES[$status] ← $body");

    final Map<String, dynamic> json = jsonDecode(body);

    if (status < 200 || status >= 300) {
      final msg = json["message"]?.toString() ?? "Unknown error";
      throw Exception("Lỗi tạo đơn hàng [$status]: $msg");
    }

    // backend bọc trong {code, message, result}
    final data = (json["result"] ?? json) as Map<String, dynamic>;
    return OrderResponse.fromJson(data);
  }

  /// Lấy TẤT CẢ đơn hàng của user (không filter)
  Future<List<OrderResponse>> getMyOrders() async {
    final res = await ApiClient.get(
      ApiClient.ORDER_API_BASE_URL,
      "/orders/my-orders",
      withAuth: true,
    );

    final status = res.statusCode;
    final body = res.body;

    print("GET MY ORDERS RES[$status] ← $body");

    if (status < 200 || status >= 300) {
      throw Exception("Lỗi tải đơn hàng [$status]");
    }

    // API trả về LIST
    final List<dynamic> list = jsonDecode(body);

    return list
        .map((e) => OrderResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
