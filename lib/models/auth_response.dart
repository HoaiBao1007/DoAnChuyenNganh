class AuthenticationResponse {
  final String token;

  AuthenticationResponse({required this.token});

  factory AuthenticationResponse.fromJson(Map<String, dynamic> json) {
    return AuthenticationResponse(
      token: json["result"]["token"],
    );
  }
}
