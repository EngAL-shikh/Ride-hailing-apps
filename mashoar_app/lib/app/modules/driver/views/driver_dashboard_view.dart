import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/driver_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/app_theme.dart';
import '../../../core/storage/auth_store.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Professional driver dashboard with map and available trips
class DriverDashboardView extends GetView<DriverController> {
  const DriverDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(() {
        final isOnline = controller.isOnline.value;
        return Scaffold(
          backgroundColor: AppTheme.surfaceGrey,
          appBar: isOnline
              ? null // Hide AppBar when online to give more space for map
              : AppBar(
                  title: const Text('لوحة تحكم السائق'),
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => _showLogoutDialog(context),
                      tooltip: 'تسجيل الخروج',
                    ),
                  ],
                ),
          body: Builder(
            builder: (context) {
              final err = controller.errorMessage.value;
              return Stack(
                children: [
                  // Map View (always show when online, even if no trips)
                  if (isOnline)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          controller.currentLat.value,
                          controller.currentLng.value,
                        ),
                        zoom: 14,
                      ),
                      markers: _buildTripMarkers(context),
                      myLocationEnabled: controller.hasLocationPermission.value,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      padding: EdgeInsets.only(
                        bottom: controller.availableTrips.isEmpty ? 200 : 400,
                      ),
                    ),

                  // Content when offline only
                  if (!isOnline)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildWelcomeCard(context, isOnline),
                          const SizedBox(height: 24),
                          _buildStatusCard(context, isOnline),
                          const SizedBox(height: 20),
                          if (err != null) _buildErrorCard(context, err),
                          const SizedBox(height: 20),
                          _buildLocationCard(context),
                          const SizedBox(height: 24),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),

                  // Empty state when online but no trips
                  if (isOnline &&
                      controller.availableTrips.isEmpty &&
                      !controller.isLoadingTrips.value)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions_bike_outlined,
                              size: 64,
                              color: AppTheme.lightGrey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد رحلات متاحة حالياً',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.mediumGrey,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'سيتم إشعارك عند توفر رحلات جديدة',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.lightGrey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Available Trips Bottom Sheet (when online and has trips AND no active trip)
                  // CRITICAL: Hide available trips bottom sheet when there's an active trip
                  // Auto-refresh: Load trips periodically when online
                  Obx(() {
                    final isOnline = controller.isOnline.value;
                    final hasActiveTrip = controller.activeTrip.value != null;
                    final tripsCount = controller.availableTrips.length;
                    final isLoading = controller.isLoadingTrips.value;

                    // Debug logging
                    Get.log(
                      '[DriverDashboardView] Bottom Sheet Check: isOnline=$isOnline, hasActiveTrip=$hasActiveTrip, tripsCount=$tripsCount, isLoading=$isLoading',
                    );

                    // Show bottom sheet when online, no active trip, and (has trips OR is loading)
                    if (isOnline && !hasActiveTrip) {
                      Get.log(
                        '[DriverDashboardView] Showing bottom sheet with $tripsCount trips',
                      );
                      return DraggableScrollableSheet(
                        initialChildSize: 0.5,
                        minChildSize: 0.3,
                        maxChildSize: 0.85,
                        builder: (context, scrollController) {
                          return Container(
                            margin: const EdgeInsets.all(
                              12,
                            ), // Margin from all sides
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(
                                20,
                              ), // Rounded from all sides
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Drag handle (smaller and more elegant)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  width: 36,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceGrey,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ), // Smaller padding
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.directions_bike,
                                          color: AppTheme.primaryColor,
                                          size: 18, // Smaller icon
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'الرحلات المتاحة',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              '${controller.availableTrips.length} رحلة متاحة',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppTheme.lightGrey,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Online Status Switch (like in status card)
                                      Obx(
                                        () => Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'متصل',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.mediumGrey,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            Switch(
                                              value: controller.isOnline.value,
                                              onChanged: (_) => controller
                                                  .toggleOnlineStatus(),
                                              activeColor: AppTheme.success,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 18,
                                        ), // Smaller icon
                                        onPressed:
                                            controller.loadAvailableTrips,
                                        tooltip: 'تحديث',
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                // Trips List
                                Expanded(
                                  child: controller.isLoadingTrips.value
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : controller.availableTrips.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .directions_bike_outlined,
                                                  size: 48,
                                                  color: AppTheme.lightGrey,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'لا توجد رحلات متاحة حالياً',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            AppTheme.mediumGrey,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'سيتم إشعارك عند توفر رحلات جديدة',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color:
                                                            AppTheme.lightGrey,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : RefreshIndicator(
                                          onRefresh:
                                              controller.loadAvailableTrips,
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.all(16),
                                            itemCount: controller
                                                .availableTrips
                                                .length,
                                            itemBuilder: (context, index) {
                                              final trip = controller
                                                  .availableTrips[index];
                                              return _buildTripCard(
                                                context,
                                                trip,
                                              );
                                            },
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                    Get.log(
                      '[DriverDashboardView] Hiding bottom sheet: isOnline=$isOnline, hasActiveTrip=$hasActiveTrip',
                    );
                    return const SizedBox.shrink();
                  }),

                  // Active Trip Card (always show if active trip exists, regardless of online status)
                  Obx(() {
                    final activeTrip = controller.activeTrip.value;
                    if (activeTrip == null) return const SizedBox.shrink();

                    return Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: _buildActiveTripCard(context, activeTrip),
                    );
                  }),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildActiveTripCard(BuildContext context, Map<String, dynamic> trip) {
    final status = trip['status']?.toString() ?? '';
    final riderName = trip['rider']?['name']?.toString() ?? 'راكب';
    final acceptedPrice = (trip['accepted_price'] as num?)?.toDouble();
    final tripId = trip['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        controller.activeTripId.value = tripId;
        Get.toNamed(Routes.tripTracking);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bike,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status == 'assigned'
                        ? 'رحلة مخصصة - في الطريق'
                        : 'الرحلة جارية',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الراكب: $riderName',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  if (acceptedPrice != null)
                    Text(
                      '${acceptedPrice.toStringAsFixed(0)} ريال',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
              onPressed: () {
                controller.activeTripId.value = tripId;
                Get.toNamed(Routes.tripTracking, arguments: {'trip': trip});
              },
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildTripMarkers(BuildContext context) {
    final markers = <Marker>{
      // Current location
      Marker(
        markerId: const MarkerId('my_location'),
        position: LatLng(
          controller.currentLat.value,
          controller.currentLng.value,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'موقعك'),
      ),
    };

    // Add trip markers
    for (var i = 0; i < controller.availableTrips.length; i++) {
      final trip = controller.availableTrips[i];
      final pickup = trip['pickup'] as Map<String, dynamic>?;
      if (pickup != null) {
        final lat = (pickup['lat'] as num?)?.toDouble();
        final lng = (pickup['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          final offeredPrice = (trip['offered_price'] as num?)?.toDouble() ?? 0;
          markers.add(
            Marker(
              markerId: MarkerId('trip_${trip['id']}'),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(
                title: 'رحلة #${trip['id']}',
                snippet: '${offeredPrice.toStringAsFixed(0)} ريال',
              ),
              onTap: () {
                // Show trip details
                _showTripDetails(context, trip);
              },
            ),
          );
        }
      }
    }

    return markers;
  }

  Widget _buildWelcomeCard(BuildContext context, bool isOnline) {
    return Obx(() {
      final status = controller.verificationStatus;
      final name = AuthStore.name ?? 'السائق';
      
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with premium gradient
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                  ),
                  child: const Center(
                    child: Icon(Iconsax.user, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً بجانبك، $name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildVerificationChip(status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Driver Stats or Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('الرحلات', '${controller.profileData['profile']?['trips_count'] ?? 0}', Iconsax.routing),
                  _buildMiniStat('التقييم', '${controller.profileData['profile']?['rating'] ?? 5.0}', Iconsax.star),
                  _buildMiniStat('المحفظة', '0.0', Iconsax.wallet),
                ],
              ),
            ),
            if (status == 'unverified') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.toNamed(Routes.driverVerification),
                icon: const Icon(Iconsax.verify, size: 18),
                label: const Text(
                  'توثيق الحساب الآن',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildVerificationChip(String status) {
    Color color;
    String text;
    IconData icon;
    
    switch (status) {
      case 'verified':
        color = const Color(0xFF10B981);
        text = 'حساب موثق';
        icon = Iconsax.verify;
        break;
      case 'pending':
        color = Colors.orange;
        text = 'قيد المراجعة';
        icon = Iconsax.timer;
        break;
      case 'rejected':
        color = Colors.red;
        text = 'تم رفض التوثيق';
        icon = Iconsax.close_circle;
        break;
      default:
        color = Colors.grey;
        text = 'غير موثق';
        icon = Iconsax.info_circle;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.4), size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isOnline) {
    // This card only shows when offline - allows driver to go online
    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceGrey, width: 2),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cancel, size: 32, color: AppTheme.mediumGrey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أنت غير متصل',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.mediumGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'قم بالاتصال لبدء استقبال طلبات الركاب',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Switch(
              value: false,
              onChanged: (_) => controller.toggleOnlineStatus(),
              activeColor: AppTheme.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'موقعك الحالي',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.getCurrentLocation,
                  tooltip: 'تحديث الموقع',
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'خط العرض',
              controller.currentLat.value.toStringAsFixed(6),
              Icons.north,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'خط الطول',
              controller.currentLng.value.toStringAsFixed(6),
              Icons.east,
            ),
            if (controller.isSendingPulse.value) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'جاري إرسال الموقع...',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجراءات السريعة',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          context,
          icon: Icons.account_balance_wallet,
          title: 'المحفظة',
          subtitle: 'عرض الرصيد والمعاملات',
          color: AppTheme.primaryColor,
          onTap: () => Get.toNamed(Routes.wallet),
        ),
      ],
    );
  }

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> trip) {
    final tripId = trip['id']?.toString() ?? '';
    final riderName = trip['rider']?['name']?.toString() ?? 'راكب';
    final offeredPrice = (trip['offered_price'] as num?)?.toDouble() ?? 0;
    final pickup = trip['pickup'] as Map<String, dynamic>?;
    final dropoff = trip['dropoff'] as Map<String, dynamic>?;
    final bids = trip['bids'] as List? ?? [];
    final bidsCount = (trip['bids_count'] as num?)?.toInt() ?? bids.length;
    final myBid = bids.isNotEmpty ? bids.first : null;
    final myBidAmount = myBid != null
        ? (myBid['amount'] as num?)?.toDouble()
        : null;
    final hasBids = bidsCount > 0;

    // Calculate distance (simple approximation)
    double distance = 0;
    if (pickup != null && dropoff != null) {
      final pickupLat = (pickup['lat'] as num?)?.toDouble() ?? 0;
      final pickupLng = (pickup['lng'] as num?)?.toDouble() ?? 0;
      final dropoffLat = (dropoff['lat'] as num?)?.toDouble() ?? 0;
      final dropoffLng = (dropoff['lng'] as num?)?.toDouble() ?? 0;
      // Simple distance calculation (Haversine approximation)
      distance = _calculateDistance(
        pickupLat,
        pickupLng,
        dropoffLat,
        dropoffLng,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _showTripDetails(context, trip),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bike,
                      color: AppTheme.primaryColor,
                      size: 16, // Smaller icon
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رحلة #$tripId',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'الراكب: $riderName',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.lightGrey),
                        ),
                      ],
                    ),
                  ),
                  if (myBidAmount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'مزايدة',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Price and Distance
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      Icons.monetization_on,
                      '${offeredPrice.toStringAsFixed(0)} ريال',
                      AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      Icons.straighten,
                      '${distance.toStringAsFixed(1)} كم',
                      AppTheme.info,
                    ),
                  ),
                ],
              ),
              if (myBidAmount != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 14, // Smaller icon
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'مزايدتك: ${myBidAmount.toStringAsFixed(0)} ريال',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (hasBids && myBidAmount == null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: AppTheme.warning,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$bidsCount مزايدة',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Action Button (with loading state)
              Obx(() {
                final isLoading = controller.isPlacingBid.value;

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => _showBidDialog(context, trip),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.white,
                              ),
                            ),
                          )
                        : Icon(
                            myBidAmount != null ? Icons.edit : Icons.gavel,
                            size: 18,
                          ),
                    label: Text(
                      isLoading
                          ? 'جاري الإرسال...'
                          : (myBidAmount != null
                                ? 'تعديل المزايدة'
                                : 'وضع مزايدة'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppTheme.primaryColor
                          .withOpacity(0.6),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.lightGrey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.lightGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.lightGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.lightGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTripDetails(BuildContext context, Map<String, dynamic> trip) {
    // Close any existing bottom sheets first (UX improvement)
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل الرحلة #${trip['id']}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('الراكب: ${trip['rider']?['name'] ?? 'غير معروف'}'),
            Text(
              'السعر المطلوب: ${(trip['offered_price'] as num?)?.toDouble() ?? 0} ريال',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  _showBidDialog(context, trip);
                },
                child: const Text('وضع مزايدة'),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showBidDialog(BuildContext context, Map<String, dynamic> trip) {
    final tripId = trip['id']?.toString() ?? '';
    final offeredPrice = (trip['offered_price'] as num?)?.toDouble() ?? 0;
    final bids = trip['bids'] as List? ?? [];
    final myBid = bids.isNotEmpty ? bids.first : null;
    final currentBid = myBid != null
        ? (myBid['amount'] as num?)?.toDouble()
        : offeredPrice;

    final bidController = TextEditingController(
      text: (currentBid ?? offeredPrice).toStringAsFixed(0),
    );

    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(myBid != null ? 'تعديل المزايدة' : 'وضع مزايدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bidController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ (ريال)',
                  hintText: 'أدخل المبلغ',
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: controller.isPlacingBid.value
                  ? null
                  : () => Get.back(),
              child: const Text('إلغاء'),
            ),
            Obx(() {
              final isLoading = controller.isPlacingBid.value;

              return ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        final amount = double.tryParse(bidController.text);
                        if (amount != null && amount > 0) {
                          controller.placeBid(tripId, amount);
                          Get.back();
                        } else {
                          Get.snackbar('خطأ', 'يرجى إدخال مبلغ صحيح');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: AppTheme.primaryColor.withOpacity(
                    0.6,
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.white,
                          ),
                        ),
                      )
                    : const Text('تأكيد'),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                Get.back();
                controller.logout();
              },
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371; // km
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
}
