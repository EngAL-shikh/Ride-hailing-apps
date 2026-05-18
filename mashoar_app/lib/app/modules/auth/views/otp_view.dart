import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../controllers/auth_controller.dart';
import '../../../theme/app_theme.dart';

class OtpView extends StatefulWidget {
  const OtpView({super.key});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final AuthController controller = Get.find<AuthController>();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _hiddenController = TextEditingController();
  final int _otpLength = 4;
  String _otp = '';

  @override
  void initState() {
    super.initState();
    
    // Listen to hidden controller changes
    _hiddenController.addListener(() {
      final value = _hiddenController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (value.length <= _otpLength) {
        setState(() {
          _otp = value;
        });
        controller.otpController.text = value;
        
        // Auto verify when complete
        if (value.length == _otpLength) {
          Future.delayed(const Duration(milliseconds: 300), () {
            controller.verifyOtp();
          });
        }
      } else {
        // Limit to 4 digits
        _hiddenController.text = value.substring(0, _otpLength);
      }
    });

    // Auto-fill from main controller if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final otp = controller.otpController.text;
      if (otp.length == _otpLength) {
        _hiddenController.text = otp;
        _otp = otp;
      }
      // Focus hidden field
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _hiddenController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _focusNode.requestFocus();
  }

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
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                const Color(0xFF0F3460),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Obx(() {
                final err = controller.errorMessage.value;
                final otpDebug = controller.otpDebug.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Back button
                    Align(
                      alignment: Alignment.topRight,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Get.back(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Iconsax.arrow_right_3,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Icon
                    Hero(
                      tag: 'otp_icon',
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.lock_1,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Colors.white70],
                      ).createShader(bounds),
                      child: Text(
                        'otp_title'.tr,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                              letterSpacing: 1.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Subtitle
                    Text(
                      'أدخل الرمز المرسل إلى هاتفك',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // OTP Card
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
                              // Hidden text field for input
                              Opacity(
                                opacity: 0,
                                child: TextField(
                                  controller: _hiddenController,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(_otpLength),
                                  ],
                                  autofocus: true,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) {
                                    if (_otp.length == _otpLength) {
                                      controller.verifyOtp();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              // OTP Display Boxes
                              // Reverse order: first digit (index 0) appears on left, last digit (index 3) on right
                              GestureDetector(
                                onTap: _handleTap,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  textDirection: TextDirection.rtl,
                                  children: List.generate(_otpLength, (index) {
                                    // Reverse index: 0->3, 1->2, 2->1, 3->0
                                    // So first digit (index 0) appears on left (reversedIndex 3)
                                    final reversedIndex = _otpLength - 1 - index;
                                    final isFilled = reversedIndex < _otp.length;
                                    final isActive = reversedIndex == _otp.length && _focusNode.hasFocus;
                                    final digit = isFilled ? _otp[reversedIndex] : '';
                                    
                                    return Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: index < _otpLength - 1 ? 12 : 0,
                                          left: index > 0 ? 12 : 0,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeInOut,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? AppTheme.primaryColor.withOpacity(0.1)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isActive
                                                  ? AppTheme.primaryColor
                                                  : isFilled
                                                      ? AppTheme.primaryColor.withOpacity(0.3)
                                                      : AppTheme.lightGrey.withOpacity(0.3),
                                              width: isActive ? 2.5 : 1.5,
                                            ),
                                            boxShadow: isActive
                                                ? [
                                                    BoxShadow(
                                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 200),
                                              child: digit.isNotEmpty
                                                  ? Text(
                                                      digit,
                                                      key: ValueKey('digit_$index'),
                                                      style: TextStyle(
                                                        fontSize: 32,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.darkGrey,
                                                        letterSpacing: 2,
                                                      ),
                                                    )
                                                  : isActive
                                                      ? Container(
                                                          key: const ValueKey('cursor'),
                                                          width: 2,
                                                          height: 32,
                                                          color: AppTheme.primaryColor,
                                                        )
                                                      : const SizedBox.shrink(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Debug OTP
                              if (otpDebug != null && otpDebug.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.info.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.info.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Iconsax.info_circle,
                                          color: AppTheme.info,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${'otp_debug_label'.tr} $otpDebug',
                                        style: const TextStyle(
                                          color: AppTheme.info,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              // Error message
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
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              // Verify button
                              Obx(() => SizedBox(
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: controller.isLoading.value || _otp.length != _otpLength
                                          ? null
                                          : () {
                                              HapticFeedback.mediumImpact();
                                              controller.verifyOtp();
                                            },
                                      icon: controller.isLoading.value
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(
                                              Iconsax.tick_circle,
                                              size: 22,
                                            ),
                                      label: Text(
                                        controller.isLoading.value
                                            ? 'جاري التحقق...'
                                            : 'verify'.tr,
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
                              const SizedBox(height: 20),
                              // Resend option
                              TextButton.icon(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () {
                                        HapticFeedback.lightImpact();
                                        Get.back();
                                      },
                                icon: const Icon(
                                  Iconsax.refresh,
                                  size: 20,
                                ),
                                label: const Text(
                                  'إعادة إرسال الرمز',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
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
