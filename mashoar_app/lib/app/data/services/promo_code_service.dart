import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import 'settings_service.dart';

/// Service to validate and apply promo codes
class PromoCodeService extends GetxService {
  final ApiClient apiClient = Get.find();
  final SettingsService settingsService = Get.find();

  final isValidating = false.obs;
  final validatedPromo = Rx<ValidatedPromoCode?>(null);

  /// Validate promo code before applying
  Future<PromoCodeValidationResult> validate(String code, double tripAmount) async {
    try {
      isValidating.value = true;
      validatedPromo.value = null;

      final data = await apiClient.postJson('/promo-codes/validate', body: {
        'code': code.toUpperCase(),
        'trip_amount': tripAmount,
      });

      if (data['valid'] == true) {
        validatedPromo.value = ValidatedPromoCode.fromJson(data);
        
        return PromoCodeValidationResult(
          valid: true,
          discount: validatedPromo.value!.discount,
          finalAmount: validatedPromo.value!.finalAmount,
          message: 'تم تطبيق كود الخصم بنجاح',
        );
      } else {
        return PromoCodeValidationResult(
          valid: false,
          message: data['message'] ?? 'كود الخصم غير صحيح',
        );
      }
    } catch (e) {
      Get.log('[PromoCodeService] Validation error: $e', isError: true);
      return PromoCodeValidationResult(
        valid: false,
        message: 'حدث خطأ أثناء التحقق من الكود',
      );
    } finally {
      isValidating.value = false;
    }
  }

  /// Apply promo code after trip completion
  Future<bool> apply(int promoCodeId, int tripId, double discountAmount) async {
    try {
      await apiClient.postJson('/promo-codes/apply', body: {
        'promo_code_id': promoCodeId,
        'trip_id': tripId,
        'discount_amount': discountAmount,
      });

      return true;
    } catch (e) {
      Get.log('[PromoCodeService] Apply error: $e', isError: true);
      return false;
    }
  }

  /// Clear validated promo
  void clear() {
    validatedPromo.value = null;
  }
}

class ValidatedPromoCode {
  final int id;
  final String code;
  final String type;
  final double discount;
  final double originalAmount;
  final double finalAmount;
  final String? description;

  ValidatedPromoCode({
    required this.id,
    required this.code,
    required this.type,
    required this.discount,
    required this.originalAmount,
    required this.finalAmount,
    this.description,
  });

  factory ValidatedPromoCode.fromJson(Map<String, dynamic> json) {
    return ValidatedPromoCode(
      id: json['promo_code_id'],
      code: json['code'],
      type: json['type'],
      discount: (json['discount'] ?? 0).toDouble(),
      originalAmount: (json['original_amount'] ?? 0).toDouble(),
      finalAmount: (json['final_amount'] ?? 0).toDouble(),
      description: json['description'],
    );
  }
}

class PromoCodeValidationResult {
  final bool valid;
  final double? discount;
  final double? finalAmount;
  final String message;

  PromoCodeValidationResult({
    required this.valid,
    this.discount,
    this.finalAmount,
    required this.message,
  });
}
