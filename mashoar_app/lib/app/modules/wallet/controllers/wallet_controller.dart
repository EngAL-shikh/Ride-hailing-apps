import 'package:get/get.dart';
import '../../../core/network/wallet_api.dart';

class WalletController extends GetxController {
  final WalletApi _walletApi;

  WalletController(this._walletApi);

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final balance = 0.0.obs;
  final debtLimit = 0.0.obs;
  final transactions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchWallet();
  }

  Future<void> fetchWallet() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final data = await _walletApi.me();
      balance.value = (data['balance'] as num?)?.toDouble() ?? 0.0;
      debtLimit.value = (data['debt_limit'] as num?)?.toDouble() ?? 0.0;

      final txs = await _walletApi.transactions();
      transactions.value = txs;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  String getTransactionTypeLabel(String type) {
    switch (type) {
      case 'commission':
        return 'عمولة';
      case 'credit':
        return 'إيداع';
      case 'debit':
        return 'سحب';
      default:
        return type;
    }
  }
}
