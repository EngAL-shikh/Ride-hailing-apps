import 'api_client.dart';

class WalletApi {
  final ApiClient _api;
  WalletApi(this._api);

  Future<Map<String, dynamic>> me() async {
    final res = await _api.getJson('/api/v1/wallet/me', auth: true);
    final data = res['data'];
    if (data is Map<String, dynamic>) return data;
    throw ApiException(500, 'invalid_wallet_response');
  }

  Future<List<Map<String, dynamic>>> transactions() async {
    final res = await _api.getJson('/api/v1/wallet/transactions', auth: true);
    final data = res['data'];
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.map((e) => e as Map<String, dynamic>));
    }
    return [];
  }
}

