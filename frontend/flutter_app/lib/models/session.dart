class Session {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresIn: json['expires_in'],
    );
  }
}
