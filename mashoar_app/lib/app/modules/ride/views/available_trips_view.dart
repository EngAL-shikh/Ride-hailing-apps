import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ride_controller.dart';

// Screen for drivers to view available trips and place bids
class AvailableTripsView extends GetView<RideController> {
  const AvailableTripsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الرحلات المتاحة'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.isBusy.value
                  ? null
                  : controller.loadAvailableTrips,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Obx(() {
            if (controller.isBusy.value && controller.availableTrips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'جاري التحميل...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              );
            }

            if (controller.availableTrips.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.directions_bike,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'لا توجد رحلات متاحة',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد رحلات جديدة للمزايدة عليها حالياً',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.loadAvailableTrips,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.availableTrips.length,
                itemBuilder: (context, index) {
                  final trip = controller.availableTrips[index];
                  final tripId = trip['id']?.toString() ?? '';
                  final riderName = trip['rider']?['name']?.toString() ?? 'غير معروف';
                  final offeredPrice =
                      (trip['offered_price'] as num?)?.toDouble() ?? 0.0;
                  final bids = trip['bids'] as List? ?? [];
                  final myBid = bids.isNotEmpty ? bids.first : null;
                  final myBidAmount = myBid != null
                      ? (myBid['amount'] as num?)?.toDouble()
                      : null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.blue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.directions_bike,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'رحلة #$tripId',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      'الراكب: $riderName',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Price info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.monetization_on,
                                    color: Colors.amber.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'السعر المطلوب: ${offeredPrice.toStringAsFixed(0)} ريال',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (myBidAmount != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'مزايدتك: ${myBidAmount.toStringAsFixed(0)} ريال',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: controller.isBusy.value
                                      ? null
                                      : () => _showBidDialog(context, tripId),
                                  icon: Icon(
                                    myBidAmount != null
                                        ? Icons.edit
                                        : Icons.gavel,
                                    size: 18,
                                  ),
                                  label: Text(
                                    myBidAmount != null
                                        ? 'تعديل المزايدة'
                                        : 'وضع مزايدة',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              if (myBidAmount != null) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      controller.tripId.value = tripId;
                                      Get.toNamed('/ride-map');
                                    },
                                    icon: const Icon(Icons.map, size: 18),
                                    label: const Text('عرض على الخريطة'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
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

  void _showBidDialog(BuildContext context, String tripId) {
    final bidController = TextEditingController(
      text: controller.bidAmount.value.toStringAsFixed(0),
    );

    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('وضع مزايدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bidController,
                decoration: InputDecoration(
                  labelText: 'المبلغ (ريال)',
                  hintText: 'أدخل المبلغ',
                  prefixIcon: const Icon(Icons.monetization_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(bidController.text);
                if (amount != null && amount > 0) {
                  controller.bidAmount.value = amount;
                  controller.placeBid(tripIdParam: tripId, amount: amount);
                  Get.back();
                } else {
                  Get.snackbar('خطأ', 'يرجى إدخال مبلغ صحيح');
                }
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }
}
