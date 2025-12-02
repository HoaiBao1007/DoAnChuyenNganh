// lib/models/cart_response.dart

class CartItem {
  final int id;
  final String productId;
  final String productName;
  final String? imageUrl;
  final int quantity;
  final double priceAtAddition;
  final double currentPrice;
  final double lineItemTotal;
  final DateTime? addedAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.priceAtAddition,
    required this.currentPrice,
    required this.lineItemTotal,
    required this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: (json['id'] ?? 0) as int,
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      quantity: (json['quantity'] ?? 0) as int,
      priceAtAddition: (json['priceAtAddition'] as num?)?.toDouble() ?? 0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
      lineItemTotal: (json['lineItemTotal'] as num?)?.toDouble() ?? 0,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'].toString())
          : null,
    );
  }
}

class CartResponse {
  final String id;
  final String userId;
  final List<CartItem> items;
  final int totalUniqueItems;
  final int totalQuantity;
  final double grandTotal;

  CartResponse({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalUniqueItems,
    required this.totalQuantity,
    required this.grandTotal,
  });

  // Cho code cũ vẫn dùng được _cart!.totalAmount
  double get totalAmount => grandTotal;

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    // BE trả:
    // { code, message, result: { id, userId, items:[...] ... } }
    final Map<String, dynamic> root;
    final dynamic resultNode = json['result'];
    if (resultNode is Map<String, dynamic>) {
      root = resultNode;
    } else {
      root = json;
    }

    // Không cast thẳng (root['items'] as List) để tránh lỗi Null
    final dynamic itemsNode = root['items'];
    final List<CartItem> items;
    if (itemsNode is List) {
      items = itemsNode
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      items = <CartItem>[];
    }

    // Ép kiểu rõ ràng, luôn trả về kiểu non-null
    final int totalUniqueItems =
        (root['totalUniqueItems'] as num?)?.toInt() ?? items.length;

    final int totalQuantity =
        (root['totalQuantity'] as num?)?.toInt() ??
            items.fold<int>(0, (sum, it) => sum + it.quantity);

    final double grandTotal =
        (root['grandTotal'] as num?)?.toDouble() ??
            items.fold<double>(0.0, (sum, it) => sum + it.lineItemTotal);

    return CartResponse(
      id: (root['id'] ?? '').toString(),
      userId: (root['userId'] ?? '').toString(),
      items: items,
      totalUniqueItems: totalUniqueItems,
      totalQuantity: totalQuantity,
      grandTotal: grandTotal,
    );
  }
}
