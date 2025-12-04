class RatingSummary {
  final double averageRating;
  final int ratingCount;

  RatingSummary({
    required this.averageRating,
    required this.ratingCount,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    // ⚠️ Đổi key cho khớp với JSON thật từ Postman
    final avg = (json['averageRating'] ?? json['avgRating'] ?? 0).toDouble();
    final count = (json['ratingCount'] ?? json['totalRatings'] ?? 0).toInt();

    return RatingSummary(
      averageRating: avg,
      ratingCount: count,
    );
  }
}
