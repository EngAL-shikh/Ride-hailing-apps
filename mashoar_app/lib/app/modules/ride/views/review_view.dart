import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../controllers/ride_controller.dart';
import '../../../theme/app_theme.dart';

/// Review bottom sheet for rating driver after trip completion
class ReviewView extends GetView<RideController> {
  final String tripId;
  final String driverName;

  const ReviewView({
    super.key,
    required this.tripId,
    required this.driverName,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'قيم السائق',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        driverName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Rating Stars
            Obx(() {
              final rating = controller.reviewRating.value;
              return Column(
                children: [
                  const Text(
                    'كيف كانت تجربتك مع السائق؟',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => controller.reviewRating.value = index + 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: index < rating
                              ? Colors.amber
                              : Colors.grey.shade300,
                          size: 40,
                        ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Comment field
            TextField(
              controller: controller.reviewCommentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'اكتب تعليقك (اختياري)',
                hintText: 'شارك تجربتك مع السائق...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            Obx(() {
              final isLoading = controller.isSubmittingReview.value;
              final rating = controller.reviewRating.value;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isLoading || rating == 0)
                      ? null
                      : () => controller.submitReview(tripId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.send_2, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'إرسال التقييم',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            }),
            const SizedBox(height: 8),

            // Skip button
            TextButton(
              onPressed: () {
                Get.back();
                // Close all bottom sheets
                while (Get.isBottomSheetOpen ?? false) {
                  Get.back();
                }
              },
              child: const Text(
                'تخطي',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
