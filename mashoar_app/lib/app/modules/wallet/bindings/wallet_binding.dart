import 'package:get/get.dart';

import '../controllers/wallet_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/wallet_api.dart';

class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiClient>(() => ApiClient());
    Get.lazyPut<WalletApi>(() => WalletApi(Get.find<ApiClient>()));
    Get.lazyPut<WalletController>(() => WalletController(Get.find<WalletApi>()));
  }
}
