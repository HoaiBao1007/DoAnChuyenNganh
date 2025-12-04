// lib/models/order_response.dart

class AddressResponse {
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? postalCode;
  final String country;

  AddressResponse({
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.postalCode,
    required this.country,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) {
    return AddressResponse(
      addressLine1: json['addressLine1']?.toString() ?? '',
      addressLine2: json['addressLine2']?.toString(),
      city: json['city']?.toString() ?? '',
      postalCode: json['postalCode']?.toString(),
      country: json['country']?.toString() ?? '',
    );
  }
}

class OrderItemResponse {
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;
  final String? imageUrl;

  OrderItemResponse({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.imageUrl,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemResponse(
      productId: json['productId'] is int
          ? json['productId'] as int
          : int.tryParse(json['productId'].toString()) ?? 0,
      productName: json['productName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class OrderResponse {
  final int id;
  final String userId;
  final String status;

  /// Tổng tiền trước khi giảm
  final double totalAmount;

  /// Mã voucher sử dụng (có thể null)
  final String? voucherCode;

  /// Số tiền giảm giá
  final double discountAmount;

  /// Tổng tiền cuối cùng phải trả
  final double finalAmount;

  final DateTime? orderDate;
  final AddressResponse? shippingAddress;
  final AddressResponse? billingAddress;
  final String? paymentMethod;
  final List<OrderItemResponse> items;

  OrderResponse({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.voucherCode,
    required this.discountAmount,
    required this.finalAmount,
    required this.orderDate,
    required this.shippingAddress,
    required this.billingAddress,
    required this.paymentMethod,
    required this.items,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    final items = rawItems
        .map((e) => OrderItemResponse.fromJson(e as Map<String, dynamic>))
        .toList();

    return OrderResponse(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['userId']?.toString() ?? '',
      status: (json['status'] ?? json['orderStatus'] ?? '').toString(),

      // totalAmount có thể là totalAmount hoặc totalPrice
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          (json['totalPrice'] as num?)?.toDouble() ??
          0.0,

      // các field mới
      voucherCode: json['voucherCode']?.toString(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ??
          (json['finalPrice'] as num?)?.toDouble() ??
          0.0,

      orderDate: json['orderDate'] != null
          ? DateTime.tryParse(json['orderDate'].toString())
          : null,
      shippingAddress: json['shippingAddress'] != null
          ? AddressResponse.fromJson(
        json['shippingAddress'] as Map<String, dynamic>,
      )
          : null,
      billingAddress: json['billingAddress'] != null
          ? AddressResponse.fromJson(
        json['billingAddress'] as Map<String, dynamic>,
      )
          : null,
      paymentMethod: json['paymentMethod']?.toString(),
      items: items,
    );
  }
}
