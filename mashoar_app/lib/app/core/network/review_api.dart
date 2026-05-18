import 'api_client.dart';

class ReviewApi {
  final ApiClient _api;
  ReviewApi(this._api);

  /// Submit a review for a completed trip
  Future<void> submitReview({
    required String tripId,
    required int rating,
    String? comment,
  }) async {
    await _api.postJson(
      '/api/v1/trips/$tripId/review',
      body: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }

  /// Get reviews for a driver
  Future<List<Map<String, dynamic>>> getDriverReviews(String driverId) async {
    final res = await _api.getJson('/api/v1/drivers/$driverId/reviews');
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
