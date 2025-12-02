// lib/models/create_order_request.dart
class AddressRequest {
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? postalCode;
  final String country;

  AddressRequest({
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.postalCode,
    required this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'addressLine1': addressLine1,
      if (addressLine2 != null) 'addressLine2': addressLine2,
      'city': city,
      if (postalCode != null) 'postalCode': postalCode,
      'country': country,
    };
  }
}

/// === ITEMS gửi lên API /orders: [{productId, quantity}, ...] ===
class OrderItemRequest {
  final int productId;
  final int quantity;

  OrderItemRequest({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}

class CreateOrderRequest {
  final AddressRequest shippingAddress;
  final AddressRequest? billingAddress;
  final String paymentMethod;
  final String? voucherCode;
  /// có thể null nếu backend tự lấy sản phẩm từ giỏ hàng
  final List<OrderItemRequest>? items;

  CreateOrderRequest({
    required this.shippingAddress,
    this.billingAddress,
    required this.paymentMethod,
    this.voucherCode,
    this.items,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'shippingAddress': shippingAddress.toJson(),
      if (billingAddress != null) 'billingAddress': billingAddress!.toJson(),
      'paymentMethod': paymentMethod,
    };

    if (voucherCode != null && voucherCode!.isNotEmpty) {
      data['voucherCode'] = voucherCode;
    }

    if (items != null && items!.isNotEmpty) {
      data['items'] = items!.map((e) => e.toJson()).toList();
    }

    return data;
  }
}
