import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_api.dart';
import '../../../core/storage/auth_store.dart';
import '../../../core/firebase/fcm_service.dart';

class AuthController extends GetxController {
  final AuthApi _authApi;

  AuthController(this._authApi);

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  final userType = 'rider'.obs; // rider|driver
  final driverMode = 'login'.obs; // 'login' | 'register' - only for drivers
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final otpDebug =
      RxnString(); // Dev-only helper: show otp_debug under OTP field.

  @override
  void onInit() {
    super.onInit();
    // Reset driver mode when switching user type
    userType.listen((type) {
      if (type == 'driver') {
        // Default to login mode
        driverMode.value = 'login';
        // Clear name field when switching to login mode
        if (driverMode.value == 'login') {
          nameController.clear();
        }
      } else {
        // Clear name when switching to rider
        nameController.clear();
      }
    });
    
    // Auto-fill name when switching to register mode if saved name exists
    driverMode.listen((mode) {
      if (mode == 'register' && nameController.text.isEmpty) {
        final savedName = AuthStore.name;
        if (savedName != null && savedName.isNotEmpty) {
          nameController.text = savedName;
        }
      } else if (mode == 'login') {
        // Clear name when switching to login mode
        nameController.clear();
      }
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }

  Future<void> goToOtp() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      otpDebug.value = null;

      final phone = phoneController.text.trim();
      if (phone.isEmpty) {
        errorMessage.value = 'enter_phone'.tr;
        return;
      }

      // Driver registration logic:
      // - If driverMode is 'register', try to register (new user) - name is required
      // - If driverMode is 'login', skip registration and go directly to OTP (login flow)
      // - If registration fails because phone already exists (422), continue to OTP (login flow)
      if (userType.value == 'driver') {
        if (driverMode.value == 'register') {
          final name = nameController.text.trim();
          if (name.isEmpty) {
            errorMessage.value = 'enter_name'.tr;
            return;
          }
          try {
            await _authApi.register(name: name, phone: phone, type: 'driver');
          } catch (e) {
            // If registration fails because phone already exists (422 status), that's OK - user is logging in
            // Continue to OTP request. Other errors will be caught by outer try-catch.
            if (e is ApiException && e.statusCode == 422) {
              // 422 = validation error, likely "phone already taken"
              // This is fine - user exists, continue to OTP request (login flow)
              Get.log('[AuthController] Driver phone already exists, continuing to login flow');
            } else {
              // Re-throw other errors (network, server errors, etc.)
              rethrow;
            }
          }
        }
        // If driverMode is 'login', skip registration and go directly to OTP
      }

      final res = await _authApi.requestOtp(phone: phone);
      final debugOtp = res['otp_debug']?.toString();
      if (debugOtp != null && debugOtp.isNotEmpty) {
        otpDebug.value = debugOtp;
      }
      Get.toNamed('/otp');
    } catch (e) {
      errorMessage.value = 'network_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final phone = phoneController.text.trim();
      final otp = otpController.text.trim();
      if (otp.isEmpty) {
        errorMessage.value = 'enter_otp'.tr;
        return;
      }

      // Get FCM token if available
      String? fcmToken;
      try {
        final fcmService = FcmService();
        fcmToken = await fcmService.getToken();
        Get.log('[AuthController] FCM token obtained: ${fcmToken != null ? fcmToken.substring(0, 20) + "..." : "null"}');
      } catch (e) {
        Get.log('[AuthController] Failed to get FCM token: $e', isError: true);
        // Continue without FCM token - not critical for login
      }

      final res = await _authApi.verifyOtp(
        phone: phone,
        otp: otp,
        deviceName: 'mashoar_app',
        fcmToken: fcmToken,
      );

      // Save name: priority: API response > saved name > entered name > phone
      final nameToSave = res.userName ??
          AuthStore.name ??
          (userType.value == 'driver' && nameController.text.trim().isNotEmpty
              ? nameController.text.trim()
              : null) ??
          phone;

      await AuthStore.saveSession(
        token: res.token,
        userType: res.userType,
        phone: phone,
        name: nameToSave,
      );

      // If driver and name was entered, save it for next time
      if (userType.value == 'driver' && nameController.text.trim().isNotEmpty) {
        // Already saved above
      }

      // Navigate based on user type
      if (res.userType == 'driver') {
        Get.offAllNamed('/driver-dashboard');
      } else {
        Get.offAllNamed('/home');
      }
    } catch (e) {
      errorMessage.value = 'invalid_otp'.tr;
    } finally {
      isLoading.value = false;
    }
  }
}
