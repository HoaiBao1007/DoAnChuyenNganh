class AddressResponse {
  final String fullName;
  final String phone;
  final String address;

  AddressResponse({
    required this.fullName,
    required this.phone,
    required this.address,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) {
    return AddressResponse(
      fullName: json["fullName"] ?? "",
      phone: json["phone"] ?? "",
      address: json["address"] ?? "",
    );
  }
}
