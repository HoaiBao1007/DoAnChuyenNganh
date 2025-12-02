// lib/services/cart_service.dart
import 'dart:convert';
import 'package:do_an_chuyen_nganh/api/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_response.dart';

class CartService {
  // Lấy headers có Authorization
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  CartResponse _parseCart(http.Response res) {
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        'Lỗi API giỏ hàng [${res.statusCode}]: ${res.body}',
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return CartResponse.fromJson(data); // CartResponse tự xử lý field result
  }

  // ============= LẤY GIỎ HÀNG HIỆN TẠI =============
  Future<CartResponse> getMyCart() async {
    final headers = await _headers();
    final uri = Uri.parse('${ApiClient.CART_API_BASE_URL}/my-cart');

    print('GET → $uri');
    final res = await http.get(uri, headers: headers);
    print('RES[${res.statusCode}] ← ${res.body}');
    return _parseCart(res);
  }

  // ============= THÊM SẢN PHẨM =============
  Future<CartResponse> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    final headers = await _headers();
    final uri =
    Uri.parse('${ApiClient.CART_API_BASE_URL}/my-cart/items');

    final body = {
      'productId': productId.toString(), // backend dùng String
      'quantity': quantity,
    };

    print('POST → $uri');
    print('BODY → $body');

    final res = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    print('RES[${res.statusCode}] ← ${res.body}');
    return _parseCart(res);
  }

  // ============= CẬP NHẬT SỐ LƯỢNG =============
  // BE đang dùng @RequestParam("quantity") Integer quantity
  // => gửi quantity trên query string, KHÔNG gửi trong body
  Future<CartResponse> updateQuantity({
    required String productId,
    required int quantity,
  }) async {
    final headers = await _headers();

    final uri = Uri.parse(
      '${ApiClient.CART_API_BASE_URL}/my-cart/items/$productId',
    ).replace(queryParameters: {
      'quantity': quantity.toString(),
    });

    print('PUT → $uri');            // chú ý: không có BODY
    final res = await http.put(uri, headers: headers);

    print('RES[${res.statusCode}] ← ${res.body}');
    return _parseCart(res);
  }

  // ============= XOÁ 1 ITEM =============
  Future<CartResponse> removeItem({required String productId}) async {
    final headers = await _headers();
    final uri = Uri.parse(
      '${ApiClient.CART_API_BASE_URL}/my-cart/items/$productId',
    );

    print('DELETE → $uri');
    final res = await http.delete(uri, headers: headers);
    print('RES[${res.statusCode}] ← ${res.body}');
    return _parseCart(res);
  }

  // ============= XOÁ TOÀN BỘ GIỎ =============
  Future<CartResponse> clearCart() async {
    final headers = await _headers();
    final uri = Uri.parse('${ApiClient.CART_API_BASE_URL}/my-cart');

    print('DELETE → $uri');
    final res = await http.delete(uri, headers: headers);
    print('RES[${res.statusCode}] ← ${res.body}');
    return _parseCart(res);
  }
}
