import 'api_client.dart';

class DriverApi {
  final ApiClient _api;

  DriverApi(this._api);

  Future<Map<String, dynamic>> pulse({
    required double lat,
    required double lng,
    required bool isOnline,
  }) async {
    final res = await _api.postJson(
      '/api/v1/driver/pulse',
      body: {'lat': lat, 'lng': lng, 'is_online': isOnline},
    );
    return res;
  }

  /// Get nearby drivers (for riders)
  Future<List<Map<String, dynamic>>> getNearbyDrivers({
    required double lat,
    required double lng,
    double? radiusKm,
    int? limit,
  }) async {
    final res = await _api.getJson(
      '/api/v1/drivers/nearby',
      query: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        if (radiusKm != null) 'radius_km': radiusKm.toString(),
        if (limit != null) 'limit': limit.toString(),
      },
      auth: false, // Public endpoint
    );
    final data = res['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  /// Get current driver's profile and status
  Future<Map<String, dynamic>> getMe() async {
    final res = await _api.getJson('/api/v1/driver/me');
    return Map<String, dynamic>.from(res['data'] ?? {});
  }
}
