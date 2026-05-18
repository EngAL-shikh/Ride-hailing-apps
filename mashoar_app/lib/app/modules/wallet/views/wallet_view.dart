import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../controllers/wallet_controller.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = const Color(0xFF111827);
    final Color cardColor = const Color(0xFF1F2937).withOpacity(0.8);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'wallet_title'.tr,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Iconsax.refresh, color: Colors.white),
              onPressed: controller.fetchWallet,
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.balance.value == 0) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.5),
                ),
              ),
            );
          }

          final error = controller.errorMessage.value;
          if (error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.danger, color: Colors.red[400], size: 64),
                  const SizedBox(height: 16),
                  Text(
                    error,
                    style: TextStyle(color: Colors.red[400], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: controller.fetchWallet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('retry'.tr,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.white,
            backgroundColor: const Color(0xFF1F2937),
            onRefresh: controller.fetchWallet,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Balance Card with high-gloss gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4F46E5),
                          Color(0xFF7C3AED),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        children: [
                          // Glass overlay effect
                          Positioned(
                            top: -50,
                            right: -50,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(Iconsax.wallet_1,
                                          color: Colors.white, size: 28),
                                    ),
                                    Text(
                                      'Mashoar Pay',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 48),
                                Text(
                                  'الرصيد المتاح',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${controller.balance.value.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 48,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'ريال',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Iconsax.info_circle,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'حد الدين: ${controller.debtLimit.value.toStringAsFixed(0)} ريال',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'سجل المعاملات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'عرض الكل',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transactions List
                  if (controller.transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Icon(Iconsax.document_text,
                              color: Colors.white.withOpacity(0.1), size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد معاملات بعد',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  else
                    ...controller.transactions.map((tx) {
                      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                      final isNegative = amount < 0;
                      final date = tx['created_at']?.toString() ?? '';
                      final type = tx['type']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.03),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isNegative ? Colors.red : Color(0xFF10B981))
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isNegative ? Iconsax.minus : Iconsax.add,
                              color: isNegative
                                  ? Colors.red[400]
                                  : Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            controller.getTransactionTypeLabel(type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              date,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                          trailing: Text(
                            '${isNegative ? '' : '+'}${amount.toStringAsFixed(0)} ريال',
                            style: TextStyle(
                              color: isNegative
                                  ? Colors.red[400]
                                  : Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
