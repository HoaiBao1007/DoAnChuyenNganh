class PageResponse<T> {
  final List<T> content;

  PageResponse({required this.content});

  factory PageResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJson,
      ) {
    return PageResponse(
      content: (json["result"]["content"] as List)
          .map((e) => fromJson(e))
          .toList(),
    );
  }
}
