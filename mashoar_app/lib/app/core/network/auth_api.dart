import 'api_client.dart';

class AuthApi {
  final ApiClient _api;
  AuthApi(this._api);

  Future<void> register({
    required String name,
    required String phone,
    required String type, // rider|driver
  }) async {
    await _api.postJson(
      '/api/v1/auth/register',
      body: {'name': name, 'phone': phone, 'type': type},
    );
  }

  Future<Map<String, dynamic>> requestOtp({required String phone}) async {
    return await _api.postJson(
      '/api/v1/auth/request-otp',
      body: {'phone': phone},
    );
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phone,
    required String otp,
    required String deviceName,
    String? fcmToken,
  }) async {
    final body = {
      'phone': phone,
      'otp': otp,
      'device_name': deviceName,
    };
    if (fcmToken != null && fcmToken.isNotEmpty) {
      body['fcm_token'] = fcmToken;
    }
    
    final res = await _api.postJson(
      '/api/v1/auth/verify-otp',
      body: body,
    );

    final token = res['token']?.toString();
    final user = res['user'];

    if (token == null || token.isEmpty) {
      throw ApiException(500, 'missing_token');
    }

    String userType = 'rider';
    String? userName;
    if (user is Map<String, dynamic>) {
      userType = (user['type'] ?? 'rider').toString();
      userName = user['name']?.toString();
    }

    return VerifyOtpResult(
      token: token,
      userType: userType,
      userName: userName,
    );
  }

  Future<void> logout() async {
    await _api.postJson('/api/v1/auth/logout', body: {});
  }

  Future<void> updateFcmToken({required String fcmToken}) async {
    await _api.postJson(
      '/api/v1/auth/update-fcm-token',
      body: {'fcm_token': fcmToken},
    );
  }

  Future<void> verifyDriver({
    required String fullName,
    required String bikePlate,
    required String? avatarPath,
    required String? idCardFrontPath,
    required String? idCardBackPath,
  }) async {
    await _api.postMultipart(
      '/api/v1/driver/verify',
      fields: {
        'full_name': fullName,
        'bike_plate': bikePlate,
      },
      files: {
        if (avatarPath != null) 'avatar': avatarPath,
        if (idCardFrontPath != null) 'id_card_front': idCardFrontPath,
        if (idCardBackPath != null) 'id_card_back': idCardBackPath,
      },
    );
  }
}

class VerifyOtpResult {
  final String token;
  final String userType;
  final String? userName;
  const VerifyOtpResult({
    required this.token,
    required this.userType,
    this.userName,
  });
}
