class OrderItemResponse {
  final String productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final double subtotal;

  OrderItemResponse({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemResponse(
      productId: json["productId"],
      productName: json["productName"],
      imageUrl: json["imageUrl"],
      quantity: json["quantity"],
      subtotal: (json["subtotal"] as num).toDouble(),
    );
  }
}
