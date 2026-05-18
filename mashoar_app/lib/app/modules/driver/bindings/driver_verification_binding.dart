import 'package:get/get.dart';
import '../controllers/driver_verification_controller.dart';
import '../../../core/network/auth_api.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';

class DriverVerificationBinding extends Bindings {
  @override
  void dependencies() {
    final apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    final authApi = AuthApi(apiClient);

    Get.lazyPut(() => DriverVerificationController(authApi));
  }
}
