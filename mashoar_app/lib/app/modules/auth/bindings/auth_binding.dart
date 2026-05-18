import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_api.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiClient>(() => ApiClient());
    Get.lazyPut<AuthApi>(() => AuthApi(Get.find<ApiClient>()));
    Get.lazyPut<AuthController>(() => AuthController(Get.find<AuthApi>()));
  }
}
