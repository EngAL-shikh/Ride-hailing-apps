import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../controllers/ride_controller.dart';
import '../../../routes/app_pages.dart';

// Separate screen for viewing rider's trips
class MyTripsView extends GetView<RideController> {
  const MyTripsView({super.key});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = const Color(0xFF111827);
    final Color cardColor = const Color(0xFF1F2937).withOpacity(0.8);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'رحلاتي',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Iconsax.refresh, color: Colors.white),
              onPressed: controller.isBusy.value ? null : controller.loadMyTrips,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                backgroundColor,
                const Color(0xFF111827).withOpacity(0.9),
              ],
            ),
          ),
          child: Obx(() {
            if (controller.isBusy.value && controller.myTrips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'جاري التحميل...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[400],
                          ),
                    ),
                  ],
                ),
              );
            }

            if (controller.myTrips.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.driving,
                          size: 80,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'لا توجد رحلات',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ابدأ بطلب رحلة جديدة الآن',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Get.toNamed(Routes.rideMap),
                          icon: Icon(Iconsax.add_circle, color: Colors.white),
                          label: const Text(
                            'طلب رحلة جديدة',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: Colors.white,
              backgroundColor: const Color(0xFF1F2937),
              onRefresh: controller.loadMyTrips,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: controller.myTrips.length,
                itemBuilder: (context, index) {
                  final trip = controller.myTrips[index];
                  final tripId = trip['id']?.toString() ?? '';
                  final status = trip['status']?.toString() ?? 'unknown';
                  final offeredPrice =
                      (trip['offered_price'] as num?)?.toDouble() ?? 0.0;
                  final acceptedPrice =
                      (trip['accepted_price'] as num?)?.toDouble();
                  final bidsCount = (trip['bids'] as List?)?.length ?? 0;
                  final driverName = trip['driver']?['name']?.toString();

                  Color statusColor = Colors.grey;
                  String statusText = 'غير معروف';
                  IconData statusIcon = Iconsax.info_circle;
                  Color statusBG = Colors.grey.withOpacity(0.1);

                  switch (status) {
                    case 'bidding':
                      statusColor = const Color(0xFFF59E0B);
                      statusText = 'قيد المزايدة';
                      statusIcon = Iconsax.judge;
                      statusBG = const Color(0xFFF59E0B).withOpacity(0.15);
                      break;
                    case 'assigned':
                      statusColor = const Color(0xFF3B82F6);
                      statusText = 'تم التعيين';
                      statusIcon = Iconsax.truck;
                      statusBG = const Color(0xFF3B82F6).withOpacity(0.15);
                      break;
                    case 'in_progress':
                      statusColor = const Color(0xFF8B5CF6);
                      statusText = 'قيد التنفيذ';
                      statusIcon = Iconsax.driving;
                      statusBG = const Color(0xFF8B5CF6).withOpacity(0.15);
                      break;
                    case 'completed':
                      statusColor = const Color(0xFF10B981);
                      statusText = 'مكتملة';
                      statusIcon = Iconsax.tick_circle;
                      statusBG = const Color(0xFF10B981).withOpacity(0.15);
                      break;
                    case 'cancelled':
                      statusColor = const Color(0xFFEF4444);
                      statusText = 'ملغاة';
                      statusIcon = Iconsax.close_circle;
                      statusBG = const Color(0xFFEF4444).withOpacity(0.15);
                      break;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        if (status == 'bidding') {
                          controller.tripId.value = tripId;
                          controller.refreshBids();
                          Get.toNamed('/trip-bids',
                              arguments: {'tripId': tripId});
                        } else if (status == 'assigned' ||
                            status == 'in_progress') {
                          controller.tripId.value = tripId;
                          Get.toNamed('/trip-tracking');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusBG,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(statusIcon,
                                      color: statusColor, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'رحلة #$tripId',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Real-time bid count badge (uses Obx for live updates)
                                Obx(() {
                                  // Get real-time bid count from activeTrip if this is the active trip
                                  int liveBidsCount = bidsCount;
                                  if (controller.activeTrip.value != null &&
                                      controller.activeTrip.value!['id']?.toString() == tripId) {
                                    final activeBids = controller.activeTrip.value!['bids'] as List?;
                                    liveBidsCount = activeBids?.length ?? 0;
                                  }
                                  
                                  if (status == 'bidding' && liveBidsCount > 0) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$liveBidsCount عروض',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(
                                color: Colors.white.withOpacity(0.05),
                                height: 1),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'السعر المتوقع',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(acceptedPrice ?? offeredPrice).toStringAsFixed(0)} ريال',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                if (driverName != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'السائق',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        driverName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (status == 'bidding' && bidsCount > 0)
                                  Icon(
                                    Iconsax.arrow_left_1,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
