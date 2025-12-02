// lib/models/app_notification.dart

class AppNotification {
  final int id;
  final String userId;
  final String orderId;
  final String message;
  final String type;
  final String status;
  final DateTime createdAt;
  bool read; // cho phép cập nhật trạng thái đã đọc trên UI

  AppNotification({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.read,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      userId: json['userId'] as String,
      orderId: json['orderId'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      read: json['read'] as bool,
    );
  }
}
