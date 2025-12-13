// lib/utils/image_url_helper.dart

class ImageUrlHelper {
  // IP + port của product-service trên LAN
  static const String backendHost = "192.168.110.18";
  static const String backendPort = "8081";

  /// Sửa URL ảnh từ /files/... hoặc localhost/... sang IP thật
  static String fix(String? url) {
    if (url == null || url.isEmpty) return '';

    String fixed = url.trim();

    // Nếu chỉ là đường dẫn tương đối: /files/...
    if (fixed.startsWith('/')) {
      fixed = "http://$backendHost:$backendPort$fixed";
    }

    // Nếu backend trả http://localhost:8081/..., 127.0.0.1..., host.docker.internal...
    fixed = fixed
        .replaceAll("localhost", backendHost)
        .replaceAll("127.0.0.1", backendHost)
        .replaceAll("host.docker.internal", backendHost)
    // phòng khi Docker dùng tên service productservice:8081
        .replaceAll("productservice:8081", "$backendHost:$backendPort");

    return fixed;
  }
}
