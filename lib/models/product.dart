class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool active;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.active,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String? raw = json["imageUrl"];

    // Normalize URL — xử lý tất cả các trường hợp
    String? finalUrl;
    if (raw != null && raw.isNotEmpty) {
      if (raw.startsWith("http")) {
        finalUrl = raw;   // backend đã trả full URL
      } else {
        finalUrl = "http://192.168.110.18:8081$raw"; // backend trả path
      }
    }

    return Product(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      price: (json["price"] as num).toDouble(),
      imageUrl: finalUrl,
      active: json["active"] ?? true,
    );
  }
}
