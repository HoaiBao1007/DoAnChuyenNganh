// lib/api/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const USER_API_BASE_URL = "http://192.168.1.127:8080";
  static const PRODUCT_API_BASE_URL = "http://192.168.1.127:8081/api/v1";
  static const CART_API_BASE_URL = "http://192.168.1.127:8082/api/v1/carts";
  static const ORDER_API_BASE_URL = "http://192.168.1.127:8083/api/v1";
  static const NOTIFICATION_API_BASE_URL = "http://192.168.1.127:8085";
  static const String VOUCHER_API_BASE_URL = "http://192.168.1.127:8089";
  static const String MINIGAME_API_BASE_URL = "http://192.168.1.127:8087";


  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final headers = <String, String>{
      "Content-Type": "application/json",
      if (withAuth && token != null && token.isNotEmpty)
        "Authorization": "Bearer $token",
    };

    print("withAuth=$withAuth, headers=$headers");
    return headers;
  }

  // ---------------- GET ----------------
  static Future<http.Response> get(
      String baseUrl,
      String path, {
        bool withAuth = true,
      }) async {
    final headers = await _headers(withAuth: withAuth);
    final uri = Uri.parse("$baseUrl$path");

    print("GET → $uri");
    return http.get(uri, headers: headers);
  }

  // GET trả về List<dynamic>
  static Future<List<dynamic>> getList(
      String baseUrl,
      String path, {
        bool withAuth = true,
      }) async {
    final res = await get(baseUrl, path, withAuth: withAuth);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception("GET LIST FAILED [${res.statusCode}] → ${res.body}");
  }

  // GET trả về Map<String, dynamic>
  static Future<Map<String, dynamic>> getJson(
      String baseUrl,
      String path, {
        bool withAuth = true,
      }) async {
    final res = await get(baseUrl, path, withAuth: withAuth);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception("GET JSON FAILED [${res.statusCode}] → ${res.body}");
  }

  // ---------------- POST ----------------
  static Future<http.Response> post(
      String baseUrl,
      String path,
      Map<String, dynamic> body, {
        bool withAuth = true,
      }) async {
    final headers = await _headers(withAuth: withAuth);
    final uri = Uri.parse("$baseUrl$path");

    print("POST → $uri");
    print("BODY → ${jsonEncode(body)}");

    return http.post(uri, headers: headers, body: jsonEncode(body));
  }

  static Future<Map<String, dynamic>> postJson(
      String baseUrl,
      String path,
      Map<String, dynamic> body, {
        bool withAuth = true,
      }) async {
    final res = await post(baseUrl, path, body, withAuth: withAuth);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception("POST FAILED [${res.statusCode}] → ${res.body}");
  }

  // ---------------- PUT ----------------
  static Future<http.Response> put(
      String baseUrl,
      String path,
      Map<String, dynamic>? body, {
        bool withAuth = true,
      }) async {
    final headers = await _headers(withAuth: withAuth);
    final uri = Uri.parse("$baseUrl$path");

    print("PUT → $uri");
    if (body != null) print("BODY → ${jsonEncode(body)}");

    return http.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // ---------------- PATCH ----------------
  static Future<http.Response> patch(
      String baseUrl,
      String path,
      Map<String, dynamic>? body, {
        bool withAuth = true,
      }) async {
    final headers = await _headers(withAuth: withAuth);
    final uri = Uri.parse("$baseUrl$path");

    print("PATCH → $uri");
    if (body != null) print("BODY → ${jsonEncode(body)}");

    return http.patch(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // ---------------- DELETE ----------------
  static Future<http.Response> delete(
      String baseUrl,
      String path, {
        bool withAuth = true,
      }) async {
    final headers = await _headers(withAuth: withAuth);
    final uri = Uri.parse("$baseUrl$path");

    print("DELETE → $uri");
    return http.delete(uri, headers: headers);
  }
}
