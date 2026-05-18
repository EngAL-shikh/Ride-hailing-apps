import 'api_client.dart';

class TripApi {
  final ApiClient _api;
  TripApi(this._api);

  Future<Map<String, dynamic>> requestTrip({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    double? offeredPrice,
  }) async {
    final res = await _api.postJson(
      '/api/v1/trips/request',
      body: {
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'dropoff_lat': dropoffLat,
        'dropoff_lng': dropoffLng,
        if (offeredPrice != null) 'offered_price': offeredPrice,
      },
    );

    final trip = res['trip'];
    if (trip is Map<String, dynamic>) return trip;
    throw ApiException(500, 'invalid_trip_response');
  }

  Future<Map<String, dynamic>> placeBid({
    required String tripId,
    required double amount,
  }) async {
    final res = await _api.postJson(
      '/api/v1/trips/$tripId/bid',
      body: {'amount': amount},
    );
    final bid = res['bid'];
    if (bid is Map<String, dynamic>) return bid;
    throw ApiException(500, 'invalid_bid_response');
  }

  Future<Map<String, dynamic>> acceptBid({
    required String tripId,
    required String bidId,
  }) async {
    final res = await _api.postJson(
      '/api/v1/trips/$tripId/accept',
      body: {'bid_id': int.parse(bidId)},
    );
    final trip = res['trip'];
    if (trip is Map<String, dynamic>) return trip;
    throw ApiException(500, 'invalid_trip_response');
  }

  /// Notify rider that driver has arrived at pickup location
  Future<Map<String, dynamic>> notifyArrival({required String tripId}) async {
    final res = await _api.postJson('/api/v1/trips/$tripId/arrival', body: {});
    final trip = res['trip'];
    if (trip is Map<String, dynamic>) return trip;
    throw ApiException(500, 'invalid_trip_response');
  }

  /// Start the trip (driver picked up the rider)
  Future<Map<String, dynamic>> startTrip({required String tripId}) async {
    final res = await _api.postJson('/api/v1/trips/$tripId/start', body: {});
    final trip = res['trip'];
    if (trip is Map<String, dynamic>) return trip;
    throw ApiException(500, 'invalid_trip_response');
  }

  /// Complete the trip (driver dropped off the rider)
  Future<Map<String, dynamic>> completeTrip({required String tripId}) async {
    final res = await _api.postJson('/api/v1/trips/$tripId/complete', body: {});
    final trip = res['trip'];
    if (trip is Map<String, dynamic>) return trip;
    throw ApiException(500, 'invalid_trip_response');
  }

  /// Cancel the trip
  Future<Map<String, dynamic>> cancelTrip({required String tripId}) async {
    final res = await _api.postJson('/api/v1/trips/$tripId/cancel', body: {});
    final trip = res['trip'];
    if (trip is Map<String, dynamic>) return trip;
    throw ApiException(500, 'invalid_trip_response');
  }

  Future<List<Map<String, dynamic>>> listBids({required String tripId}) async {
    final res = await _api.getJson('/api/v1/trips/$tripId/bids');
    final data = res['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  // Driver: Get available trips for bidding
  Future<List<Map<String, dynamic>>> getAvailableTrips() async {
    final res = await _api.getJson('/api/v1/trips/available');
    final data = res['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  // Rider: Get my trips
  Future<List<Map<String, dynamic>>> getMyTrips() async {
    final res = await _api.getJson('/api/v1/trips/my');
    final data = res['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  // Driver: Get my assigned trips
  Future<List<Map<String, dynamic>>> getMyDriverTrips() async {
    final res = await _api.getJson('/api/v1/trips/driver/my');
    final data = res['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }
}
