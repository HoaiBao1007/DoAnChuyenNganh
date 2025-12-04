class RatingResponse {
  final int id;
  final String userId;
  final String username;
  final double ratingValue;
  final String? comment;
  final DateTime? createdAt;

  RatingResponse({
    required this.id,
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

class RatingSummaryResponse {
  final double averageRating;
  final int totalRatings;

  RatingSummaryResponse({
    required this.averageRating,
    required this.totalRatings,
  });

  factory RatingSummaryResponse.fromJson(Map<String, dynamic> json) {
    return RatingSummaryResponse(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
    );
  }
}
