import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../controllers/auth_controller.dart';
import '../../../core/storage/auth_store.dart';
import '../../../theme/app_theme.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF1A1A2E), // Dark blue-purple
                const Color(0xFF16213E), // Darker blue
                const Color(0xFF0F3460), // Deep blue
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Obx(() {
                final isDriver = controller.userType.value == 'driver';
                final err = controller.errorMessage.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Logo/Icon with animation
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.driving,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title with gradient effect
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Colors.white70],
                      ).createShader(bounds),
                      child: Text(
                        'app_name'.tr,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                              letterSpacing: 1.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      'نقل آمن وسريع في اليمن',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Form Card with improved design
                    Card(
                      elevation: 12,
                      shadowColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.grey.shade50,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Welcome title with icon
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.login_1,
                                    color: AppTheme.primaryColor,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'login_title'.tr,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.darkGrey,
                                          fontSize: 24,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              // Role Selection - Improved design
                              Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: AppTheme.lightGrey.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButton<String>(
                                value: controller.userType.value,
                                isExpanded: true,
                                underline: const SizedBox(),
                                icon: Icon(
                                  Iconsax.arrow_down_1,
                                  color: AppTheme.mediumGrey,
                                ),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.darkGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'rider',
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.info.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Iconsax.user,
                                            color: AppTheme.info,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'role_rider'.tr,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'driver',
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.success.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Iconsax.driving,
                                            color: AppTheme.success,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'role_driver'.tr,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: controller.isLoading.value
                                    ? null
                                    : (v) {
                                        if (v != null) {
                                          controller.userType.value = v;
                                          // Add haptic feedback
                                          HapticFeedback.lightImpact();
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Driver mode selection (login or register) - Improved design
                            if (isDriver) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceGrey,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.lightGrey.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Obx(() => AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: controller.isLoading.value
                                                ? null
                                                : () {
                                                    controller.driverMode.value = 'login';
                                                    HapticFeedback.lightImpact();
                                                  },
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              decoration: BoxDecoration(
                                                color: controller.driverMode.value == 'login'
                                                    ? AppTheme.primaryColor
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: controller.driverMode.value == 'login'
                                                    ? [
                                                        BoxShadow(
                                                          color: AppTheme.primaryColor.withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Iconsax.login_1,
                                                    color: controller.driverMode.value == 'login'
                                                        ? Colors.white
                                                        : AppTheme.mediumGrey,
                                                    size: 22,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'تسجيل دخول',
                                                    style: TextStyle(
                                                      color: controller.driverMode.value == 'login'
                                                          ? Colors.white
                                                          : AppTheme.mediumGrey,
                                                      fontWeight: controller.driverMode.value == 'login'
                                                          ? FontWeight.bold
                                                          : FontWeight.w500,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )),
                                    ),
                                    Expanded(
                                      child: Obx(() => AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: controller.isLoading.value
                                                ? null
                                                : () {
                                                    controller.driverMode.value = 'register';
                                                    HapticFeedback.lightImpact();
                                                  },
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              decoration: BoxDecoration(
                                                color: controller.driverMode.value == 'register'
                                                    ? AppTheme.primaryColor
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: controller.driverMode.value == 'register'
                                                    ? [
                                                        BoxShadow(
                                                          color: AppTheme.primaryColor.withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Iconsax.user_add,
                                                    color: controller.driverMode.value == 'register'
                                                        ? Colors.white
                                                        : AppTheme.mediumGrey,
                                                    size: 22,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'سائق جديد',
                                                    style: TextStyle(
                                                      color: controller.driverMode.value == 'register'
                                                          ? Colors.white
                                                          : AppTheme.mediumGrey,
                                                      fontWeight: controller.driverMode.value == 'register'
                                                          ? FontWeight.bold
                                                          : FontWeight.w500,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Name field (only for new driver registration) - Animated
                              Obx(() {
                                if (controller.driverMode.value == 'register') {
                                  return AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          controller: controller.nameController
                                            ..text = AuthStore.name ?? '',
                                          decoration: InputDecoration(
                                            labelText: 'name_label'.tr,
                                            hintText: 'أدخل اسمك الكامل',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(12),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Iconsax.user,
                                                color: AppTheme.primaryColor,
                                                size: 20,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: AppTheme.lightGrey.withOpacity(0.3),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: AppTheme.lightGrey.withOpacity(0.3),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: const BorderSide(
                                                color: AppTheme.primaryColor,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                              const SizedBox(height: 16),
                            ],
                            // Phone field - Improved design
                            TextField(
                              controller: controller.phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'phone_label'.tr,
                                hintText: 'phone_hint'.tr,
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Iconsax.call,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppTheme.lightGrey.withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppTheme.lightGrey.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Error message - Improved design
                            if (err != null) ...[
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.error.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.error.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Iconsax.danger,
                                        color: AppTheme.error,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        err,
                                        style: const TextStyle(
                                          color: AppTheme.error,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            // Submit button - Improved design with icon
                            Obx(() => SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () {
                                        HapticFeedback.mediumImpact();
                                        controller.goToOtp();
                                      },
                                icon: controller.isLoading.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(
                                        Iconsax.arrow_left_2,
                                        size: 22,
                                      ),
                                label: Text(
                                  controller.isLoading.value ? 'جاري التحقق...' : 'continue'.tr,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            )),
                          ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
