class VerifyPhoneResponse {
  const VerifyPhoneResponse({
    required this.resetToken,
    required this.expiresInSeconds,
  });

  final String resetToken;
  final int expiresInSeconds;

  factory VerifyPhoneResponse.fromJson(Map<String, dynamic> json) {
    final resetToken = json['resetToken']?.toString() ?? '';
    if (resetToken.isEmpty) {
      throw const FormatException('Phản hồi xác minh không có resetToken');
    }

    return VerifyPhoneResponse(
      resetToken: resetToken,
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
