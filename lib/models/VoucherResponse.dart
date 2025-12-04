// lib/models/voucher_response.dart

class VoucherResponse {
  final int id;
  final String code;
  final String discountType;   // PERCENT / FIXED
  final double discountValue;
  final DateTime? startDate;
  final DateTime? endDate;
  final int quantity;
  final String status;
  final int pointCost;

  VoucherResponse({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.quantity,
    required this.status,
    required this.pointCost,
  });

  factory VoucherResponse.fromJson(Map<String, dynamic> json) {
    return VoucherResponse(
      id: json['id'] as int,
      code: json['code']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? '',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      pointCost: (json['pointCost'] as num?)?.toInt() ?? 0,
    );
  }
}
