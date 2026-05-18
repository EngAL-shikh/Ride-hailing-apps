import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../controllers/ride_controller.dart';
import '../../../theme/app_theme.dart';

/// Redesigned ride request screen with modern UI and excellent UX
class RideRequestView extends GetView<RideController> {
  const RideRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceGrey,
        appBar: AppBar(
          title: const Text('طلب رحلة'),
          elevation: 0,
          backgroundColor: AppTheme.white,
        ),
        body: SafeArea(
          child: Obx(() {
            final err = controller.errorMessage.value;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section - Compact and modern
                  _buildHeaderSection(context),
                  const SizedBox(height: 24),

                  // Error message
                  if (err != null) ...[
                    _buildErrorMessage(err),
                    const SizedBox(height: 20),
                  ],

                  // Pickup Location Card
                  _buildLocationCard(
                    context: context,
                    title: 'نقطة الاستلام',
                    icon: Iconsax.location,
                    accentColor: AppTheme.success,
                    isPickup: true,
                  ),
                  const SizedBox(height: 16),

                  // Dropoff Location Card
                  _buildLocationCard(
                    context: context,
                    title: 'نقطة الوصول',
                    icon: Iconsax.location_tick,
                    accentColor: AppTheme.error,
                    isPickup: false,
                  ),
                  const SizedBox(height: 24),

                  // Price Selection Section
                  _buildPriceSection(context),
                  const SizedBox(height: 32),

                  // Request Button
                  _buildRequestButton(context),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.driving,
              color: AppTheme.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلب رحلة جديدة',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'حدد موقع الاستلام والوصول',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.danger,
            color: AppTheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color accentColor,
    required bool isPickup,
  }) {
    return Obx(() {
      final lat = isPickup ? controller.pickupLat.value : controller.dropoffLat.value;
      final lng = isPickup ? controller.pickupLng.value : controller.dropoffLng.value;
      final hasLocation = lat != 0.0 && lng != 0.0;

      return Card(
        elevation: 2,
        shadowColor: accentColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: accentColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location Display or Placeholder
                  if (hasLocation) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.gps,
                            size: 16,
                            color: AppTheme.mediumGrey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.mediumGrey,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGrey,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.lightGrey.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.location_slash,
                            size: 16,
                            color: AppTheme.lightGrey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'لم يتم تحديد الموقع',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.lightGrey,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    children: [
                      if (isPickup) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              try {
                                final position = await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );
                                controller.pickupLat.value = position.latitude;
                                controller.pickupLng.value = position.longitude;
                              } catch (e) {
                                Get.snackbar(
                                  'خطأ',
                                  'تعذر الحصول على موقعك الحالي',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                            },
                            icon: const Icon(Iconsax.gps, size: 18),
                            label: const Text('موقعي الحالي'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentColor,
                              side: BorderSide(color: accentColor.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _showLocationPicker(context, isPickup);
                          },
                          icon: const Icon(Iconsax.map_1, size: 18),
                          label: Text(hasLocation ? 'تغيير' : 'اختيار'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: AppTheme.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPriceSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.wallet_1,
                    color: AppTheme.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'السعر المعروض',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price Suggestion Chips
            Text(
              'اختر سعر مقترح أو أدخل سعرك',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGrey,
                  ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final basePrice = 1000.0; // Base price in YER
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPriceChip(
                    context: context,
                    label: 'اقتصادي',
                    price: basePrice,
                    isSelected: controller.offeredPrice.value == basePrice,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.offeredPrice.value = basePrice;
                    },
                  ),
                  _buildPriceChip(
                    context: context,
                    label: 'قياسي',
                    price: basePrice * 1.2,
                    isSelected: controller.offeredPrice.value == basePrice * 1.2,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.offeredPrice.value = basePrice * 1.2;
                    },
                  ),
                  _buildPriceChip(
                    context: context,
                    label: 'مميز',
                    price: basePrice * 1.5,
                    isSelected: controller.offeredPrice.value == basePrice * 1.5,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.offeredPrice.value = basePrice * 1.5;
                    },
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),

            // Custom Price Input
            Obx(() {
              return TextFormField(
                decoration: InputDecoration(
                  labelText: 'سعر مخصص (ريال يمني)',
                  prefixIcon: const Icon(Iconsax.money),
                  suffixText: 'ر.ي',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceGrey,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                initialValue: controller.offeredPrice.value.toString(),
                onChanged: (v) {
                  final price = double.tryParse(v);
                  if (price != null) {
                    controller.offeredPrice.value = price;
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChip({
    required BuildContext context,
    required String label,
    required double price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.lightGrey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? AppTheme.white : AppTheme.darkGrey,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${price.toStringAsFixed(0)} ر.ي',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected ? AppTheme.white : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestButton(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isBusy.value || controller.isRequestingTrip.value;
      final canRequest = controller.pickupLat.value != 0.0 &&
          controller.pickupLng.value != 0.0 &&
          controller.dropoffLat.value != 0.0 &&
          controller.dropoffLng.value != 0.0 &&
          controller.offeredPrice.value > 0;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: canRequest && !isLoading
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: !canRequest || isLoading ? null : () {
            HapticFeedback.mediumImpact();
            controller.requestTrip();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.white,
            disabledBackgroundColor: AppTheme.lightGrey.withOpacity(0.3),
            disabledForegroundColor: AppTheme.mediumGrey,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.send_1, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'إرسال طلب الرحلة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
        ),
      );
    });
  }

  void _showLocationPicker(BuildContext context, bool isPickup) {
    final latController = TextEditingController(
      text: isPickup
          ? controller.pickupLat.value.toString()
          : controller.dropoffLat.value.toString(),
    );
    final lngController = TextEditingController(
      text: isPickup
          ? controller.pickupLng.value.toString()
          : controller.dropoffLng.value.toString(),
    );

    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isPickup ? AppTheme.success : AppTheme.error)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPickup ? Iconsax.location : Iconsax.location_tick,
                        color: isPickup ? AppTheme.success : AppTheme.error,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPickup ? 'تحديد نقطة الاستلام' : 'تحديد نقطة الوصول',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Latitude Input
                TextFormField(
                  controller: latController,
                  decoration: InputDecoration(
                    labelText: 'خط العرض (Latitude)',
                    prefixIcon: const Icon(Iconsax.gps),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Longitude Input
                TextFormField(
                  controller: lngController,
                  decoration: InputDecoration(
                    labelText: 'خط الطول (Longitude)',
                    prefixIcon: const Icon(Iconsax.gps),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          final lat = double.tryParse(latController.text) ?? 0.0;
                          final lng = double.tryParse(lngController.text) ?? 0.0;

                          if (isPickup) {
                            controller.pickupLat.value = lat;
                            controller.pickupLng.value = lng;
                          } else {
                            controller.dropoffLat.value = lat;
                            controller.dropoffLng.value = lng;
                          }

                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPickup ? AppTheme.success : AppTheme.error,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('تأكيد'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
