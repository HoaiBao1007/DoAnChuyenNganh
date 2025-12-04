// lib/models/minigame_history.dart
class MinigameHistory {
  final int id;
  final String userId;
  final String type;          // "SPIN", "DAILY_REWARD", ...
  final String description;   // message: "🎉 Chúc mừng! Bạn nhận được 20 điểm!"
  final int? pointsEarned;    // có thể null khi trúng voucher
  final DateTime createdAt;

  MinigameHistory({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.pointsEarned,
    required this.createdAt,
  });

  factory MinigameHistory.fromJson(Map<String, dynamic> json) {
    return MinigameHistory(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pointsEarned: json['pointsEarned'] == null
          ? null
          : (json['pointsEarned'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['createdAt'].toString()) ??
          DateTime.now(),
    );
  }
}
