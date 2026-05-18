import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ride_controller.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

// Screen for riders to view bids and accept them
class TripBidsView extends StatefulWidget {
  const TripBidsView({super.key});

  @override
  State<TripBidsView> createState() => _TripBidsViewState();
}

class _TripBidsViewState extends State<TripBidsView> {
  @override
  void initState() {
    super.initState();
    // Get tripId from arguments
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      final tripIdFromArgs = arguments['tripId']?.toString();
      if (tripIdFromArgs != null && tripIdFromArgs.isNotEmpty) {
        final controller = Get.find<RideController>();
        controller.tripId.value = tripIdFromArgs;
        // Refresh bids to ensure we have the latest data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.refreshBids();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RideController>();
    final Color backgroundColor = const Color(0xFF111827);
    final Color cardColor = const Color(0xFF1F2937).withOpacity(0.8);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'عروض السائقين',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Iconsax.refresh, color: Colors.white),
              onPressed:
                  controller.isBusy.value ? null : controller.refreshBids,
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
            // Ensure tripId is set from bids if not already set
            if (controller.tripId.value.isEmpty && controller.bids.isNotEmpty) {
              final firstBid = controller.bids.first;
              final tripIdFromBid = firstBid['trip_id']?.toString();
              if (tripIdFromBid != null && tripIdFromBid.isNotEmpty) {
                controller.tripId.value = tripIdFromBid;
              }
            }

            if (controller.isBusy.value && controller.bids.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'جاري البحث عن عروض...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[400],
                          ),
                    ),
                  ],
                ),
              );
            }

            if (controller.bids.isEmpty) {
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
                          Iconsax.judge,
                          size: 80,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'لا توجد عروض',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لم يتقدم أي كابتن بعرض حتى الآن، يرجى الانتظار قليلاً',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: Colors.white,
              backgroundColor: const Color(0xFF1F2937),
              onRefresh: controller.refreshBids,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.bids.length,
                itemBuilder: (context, index) {
                  final bid = controller.bids[index];
                  final bidId = bid['id']?.toString() ?? '';
                  final driverData = bid['driver'];
                  final driver = driverData != null 
                      ? Map<String, dynamic>.from(driverData as Map)
                      : null;
                  final driverName = driver?['name']?.toString() ?? 'كابتن';
                  final amount = (bid['amount'] as num?)?.toDouble() ?? 0.0;
                  final status = bid['status']?.toString() ?? 'pending';

                  Color statusColor = const Color(0xFFF59E0B);
                  String statusText = 'قيد الانتظار';
                  IconData statusIcon = Iconsax.clock;

                  switch (status) {
                    case 'accepted':
                      statusColor = const Color(0xFF10B981);
                      statusText = 'مقبول';
                      statusIcon = Iconsax.tick_circle;
                      break;
                    case 'rejected':
                      statusColor = const Color(0xFFEF4444);
                      statusText = 'مرفوض';
                      statusIcon = Iconsax.close_circle;
                      break;
                    default:
                      statusColor = const Color(0xFFF59E0B);
                      statusText = 'قيد الانتظار';
                      statusIcon = Iconsax.clock;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child:
                                    const Icon(Iconsax.user, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driverName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
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
                              Icon(statusIcon, color: statusColor, size: 24),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Amount
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Iconsax.money_2,
                                    color: Color(0xFF10B981), size: 32),
                                const SizedBox(width: 16),
                                Text(
                                  '${amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'ريال',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Action button
                          if (status == 'pending')
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: controller.isBusy.value
                                    ? null
                                    : () {
                                        // Ensure tripId is set (from bid data if not already set)
                                        final bidTripId = bid['trip_id']?.toString() ?? '';
                                        if (bidTripId.isNotEmpty && controller.tripId.value.isEmpty) {
                                          controller.tripId.value = bidTripId;
                                        }
                                        
                                        // Check if tripId is still empty
                                        if (controller.tripId.value.isEmpty) {
                                          Get.snackbar(
                                            'خطأ',
                                            'لم يتم العثور على رقم الرحلة',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.red[900],
                                            colorText: Colors.white,
                                          );
                                          return;
                                        }
                                        
                                        controller.acceptBidId.value = bidId;
                                        controller.acceptBid();
                                      },
                                icon: Obx(() {
                                  final isLoading = controller.isBusy.value;
                                  return isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Iconsax.tick_circle, size: 20, color: Colors.white);
                                }),
                                label: Obx(() {
                                  final isLoading = controller.isBusy.value;
                                  return Text(
                                    isLoading ? 'جاري القبول...' : 'قبول هذا العرض',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  );
                                }),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
}
