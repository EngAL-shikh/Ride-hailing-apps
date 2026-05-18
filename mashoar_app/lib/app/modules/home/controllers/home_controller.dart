import 'package:get/get.dart';
import '../../../core/network/ui_layout_api.dart';
import '../../../core/network/auth_api.dart';
import '../../../core/storage/auth_store.dart';
import '../../../routes/app_pages.dart';
import '../../ride/controllers/ride_controller.dart';

class HomeController extends GetxController {
  final UiLayoutApi _layoutApi;
  final AuthApi _authApi;

  HomeController(this._layoutApi, this._authApi);

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final layoutPayload = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    fetchHomeLayout();
    // RideController.onInit() already calls loadMyTrips() and loadNearbyDrivers()
    // No need to call them again here - prevents duplicate API calls
  }

  Future<void> fetchHomeLayout() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      Get.log('[HomeController] Starting fetchHomeLayout...');
      final locale = Get.locale?.languageCode ?? 'ar';
      Get.log('[HomeController] Locale: $locale');

      final data = await _layoutApi.fetchLayout(
        key: 'home',
        platform: 'mobile',
        locale: locale,
      );
      Get.log('[HomeController] Layout fetched successfully');

      final payload = data['payload'];
      if (payload is Map<String, dynamic>) {
        Get.log('[HomeController] Payload is valid, updating UI');
        layoutPayload.value = payload;
      } else {
        Get.log('[HomeController] ERROR: Invalid payload structure');
        throw Exception('invalid_payload');
      }
    } catch (e) {
      Get.log('[HomeController] ERROR: $e', isError: true);
      // Distinguish between "server unreachable" and "layout not found".
      final msg = e.toString();
      if (msg.contains('layout_not_found') || msg.contains('404')) {
        errorMessage.value = 'layout_not_found'.tr;
      } else if (msg.contains('timeout') || msg.contains('Connection')) {
        errorMessage.value = 'تعذر الاتصال بالخادم. تأكد من تشغيل السيرفر.';
      } else {
        errorMessage.value = 'خطأ: $msg';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (e) {
      Get.log('[HomeController] Logout error: $e', isError: true);
    } finally {
      await AuthStore.clear();
      Get.offAllNamed(Routes.login);
    }
  }
}
