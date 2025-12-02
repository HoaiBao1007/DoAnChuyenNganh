class CartItem {
  final int id;
  final String productId;
  final String productName;
  final String? imageUrl;
  final int quantity;
  final double priceAtAddition;
  final double currentPrice;
  final double lineItemTotal;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.priceAtAddition,
    required this.currentPrice,
    required this.lineItemTotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json["id"] ?? 0,
      productId: json["productId"].toString(),
      productName: json["productName"] ?? "",
      imageUrl: json["imageUrl"],
      quantity: json["quantity"] ?? 1,
      priceAtAddition: (json["priceAtAddition"] ?? 0).toDouble(),
      currentPrice: (json["currentPrice"] ?? 0).toDouble(),
      lineItemTotal: (json["lineItemTotal"] ?? 0).toDouble(),
    );
  }
}
