import 'api_client.dart';
import 'package:flutter/foundation.dart';

class UiLayoutApi {
  final ApiClient _api;
  UiLayoutApi(this._api);

  Future<Map<String, dynamic>> fetchLayout({
    required String key,
    required String platform,
    required String locale,
  }) async {
    if (kDebugMode) {
      debugPrint('[SDUI] fetchLayout key=$key platform=$platform locale=$locale');
    }
    // UI layouts endpoint is public (no auth required)
    final json = await _api.getJson(
      '/api/v1/ui/layouts/$key',
      query: {'platform': platform, 'locale': locale},
      auth: false, // Public endpoint
    );

    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw ApiException(500, 'invalid_layout_response');
  }
}

