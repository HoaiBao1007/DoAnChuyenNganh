class AppNotification {
  final int id;
  final String userId;
  final int? orderId;
  final String message;
  final DateTime createdAt;
  bool read;
  final String? type;   // nếu BE có trường type
  final String? title;  // nếu BE có trường title

  AppNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.createdAt,
    this.orderId,
    this.read = false,
    this.type,
    this.title,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    DateTime _parseDate(dynamic v) {
      if (v is String) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return AppNotification(
      id: _parseInt(json['id']),
      userId: json['userId']?.toString() ?? '',
      orderId: json['orderId'] != null ? _parseInt(json['orderId']) : null,
      message: json['message']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      read: (json['read'] as bool?) ?? false,
      type: json['type']?.toString(),
      title: json['title']?.toString(),
    );
  }
}
