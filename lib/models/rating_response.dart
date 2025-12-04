// lib/models/rating_response.dart

class RatingResponse {
  final int id;
  final int productId;
  final String userId;
  final String username;
  final double ratingValue;
  final String? comment;
  final DateTime? createdAt;

  RatingResponse({
    required this.id,
    required this.productId,
    required this.userId,
    required this.username,
    required this.ratingValue,
    this.comment,
    this.createdAt,
  });

  factory RatingResponse.fromJson(Map<String, dynamic> json) {
    return RatingResponse(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      productId: json['productId'] is int
          ? json['productId'] as int
          : int.tryParse(json['productId'].toString()) ?? 0,
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      ratingValue: (json['ratingValue'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
