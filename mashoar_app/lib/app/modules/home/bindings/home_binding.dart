import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../ride/bindings/ride_binding.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/ui_layout_api.dart';
import '../../../core/network/auth_api.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiClient>(() => ApiClient());
    Get.lazyPut<UiLayoutApi>(() => UiLayoutApi(Get.find<ApiClient>()));
    Get.lazyPut<AuthApi>(() => AuthApi(Get.find<ApiClient>()));
    Get.lazyPut<HomeController>(
      () => HomeController(Get.find<UiLayoutApi>(), Get.find<AuthApi>()),
    );

    // Also register RideController for map functionality
    final rideBinding = RideBinding();
    rideBinding.dependencies();
  }
}
