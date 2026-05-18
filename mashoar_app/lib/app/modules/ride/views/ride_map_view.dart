import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:dotted_border/dotted_border.dart';
import '../controllers/ride_controller.dart';
import '../../../core/firebase/realtime_tracking_service.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_pages.dart';

/// Professional ride map view with nearby drivers and active trip floating card
class RideMapView extends GetView<RideController> {
  RideMapView({super.key});

  // State for drivers list expansion
  final _isDriversListExpanded = false.obs;
  // Controller for DraggableScrollableSheet
  final _sheetController = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceGrey,
        // AppBar removed for minimal full-screen map experience
        body: Stack(
          children: [
            // Google Map (STABLE: Not inside top-level Obx)
            Obx(() {
              // We still use Obx for the map, but only for variables that change RARELY
              // like mapError or initial location setup.
              // Frequent variables like driverMarkers are handled inside the markers set
              // and we must be careful NOT to trigger full rebuilds for every tiny move.
              
              final pickupLat = controller.pickupLat.value;
              final pickupLng = controller.pickupLng.value;

              if (controller.mapError.value != null) {
                return _buildErrorState(context);
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(pickupLat, pickupLng),
                  zoom: 14,
                ),
                onMapCreated: (GoogleMapController mapController) async {
                  Get.log('[RideMapView] Google Map created successfully');
                  controller.mapController = mapController;
                  controller.mapError.value = null;

                  await Future.delayed(const Duration(milliseconds: 300));
                  if (controller.nearbyDrivers.isNotEmpty) {
                    await _buildAllMarkers(Get.context);
                  } else if (controller.pickupLat.value != 0.0 &&
                      controller.pickupLng.value != 0.0) {
                    await controller.loadNearbyDrivers();
                    if (controller.nearbyDrivers.isNotEmpty) {
                      await _buildAllMarkers(Get.context);
                    }
                  }
                },
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: true,
                // Granular access to markers and polylines
                markers: _buildMarkers(Get.context),
                polylines: _buildPolylines(),
                myLocationEnabled: controller.hasLocationPermission.value,
                myLocationButtonEnabled: false,
                onTap: (LatLng position) {
                  _handleMapTap(position);
                },
              );
            }),

            // 1. Floating Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Iconsax.arrow_right_3,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  onPressed: () => Get.back(),
                ),
              ),
            ),

            // 2. Control Buttons (GPS, Nearest Driver, Refresh)
            Obx(() => Positioned(
              bottom: controller.activeTrip.value != null ? 220 : 120,
              left: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: "nearest_driver_button",
                    mini: true,
                    onPressed: () => _goToNearestDriver(context),
                    backgroundColor: Colors.white,
                    child: const Icon(Iconsax.location, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: "gps_button_ride_map",
                    mini: true,
                    onPressed: () => _getCurrentLocation(context, true),
                    backgroundColor: Colors.white,
                    child: const Icon(Iconsax.gps, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: "refresh_button_ride_map",
                    mini: true,
                    onPressed: () => controller.loadNearbyDrivers(),
                    backgroundColor: Colors.white,
                    child: controller.isLoadingDrivers.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ),
                          )
                        : const Icon(Iconsax.refresh, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            )),

            // Active Trip Floating Card
            Obx(() {
              if (controller.activeTrip.value != null) {
                return Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: _buildActiveTripCard(context),
                );
              }
              return const SizedBox.shrink();
            }),

            // Request Form Bottom Sheet
            Obx(() {
              if (controller.activeTrip.value == null) {
                double sheetSize;
                if (controller.isSelectingOnMap.value) {
                  sheetSize = 0.3;
                } else if (controller.currentRequestStep.value == 3) {
                  sheetSize = 0.65;
                } else {
                  sheetSize = 0.5;
                }
                
                return DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: sheetSize,
                  minChildSize: 0.3,
                  maxChildSize: 0.8,
                  builder: (context, scrollController) {
                    return _buildRequestForm(context, scrollController);
                  },
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  /// Build all markers including custom driver card markers
  Future<void> _buildAllMarkers(BuildContext? context) async {
    // Use Get.context if context is null or not mounted
    final safeContext = (context != null && context.mounted)
        ? context
        : Get.context;

    if (safeContext == null) {
      Get.log(
        '[RideMapView] Cannot build markers: no context available',
        isError: true,
      );
      return;
    }
    final markers = <Marker>{};

    // Pickup marker (draggable)
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          controller.pickupLat.value,
          controller.pickupLng.value,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: 'نقطة الاستلام',
          snippet: controller.pickupAddress.value,
        ),
        draggable: true,
        onDragEnd: (LatLng newPosition) {
          controller.pickupLat.value = newPosition.latitude;
          controller.pickupLng.value = newPosition.longitude;
          Get.snackbar(
            'تم',
            'تم تحديث موقع الاستلام',
            backgroundColor: Colors.white,
            colorText: Colors.black,
            borderColor: Colors.grey.shade300,
            borderWidth: 1,
          );
        },
      ),
    );

    // Dropoff marker (draggable)
    if (controller.dropoffLat.value != 0 && controller.dropoffLng.value != 0) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(
            controller.dropoffLat.value,
            controller.dropoffLng.value,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: 'نقطة الوصول',
            snippet: controller.dropoffAddress.value,
          ),
          draggable: true,
          onDragEnd: (LatLng newPosition) {
            controller.dropoffLat.value = newPosition.latitude;
            controller.dropoffLng.value = newPosition.longitude;
            Get.snackbar(
              'تم',
              'تم تحديث موقع الوصول',
              backgroundColor: Colors.white,
              colorText: Colors.black,
              borderColor: Colors.grey.shade300,
              borderWidth: 1,
            );
          },
        ),
      );
    }

    // Nearby drivers markers with custom card icons
    Get.log(
      '[RideMapView] Building markers for ${controller.nearbyDrivers.length} nearby drivers',
    );
    for (var driver in controller.nearbyDrivers) {
      // Try different possible data structures
      Map<String, dynamic>? driverProfile;
      if (driver['driver_profile'] != null) {
        driverProfile = driver['driver_profile'] as Map<String, dynamic>?;
      } else if (driver['profile'] != null) {
        driverProfile = driver['profile'] as Map<String, dynamic>?;
      }

      double? lat;
      double? lng;

      if (driverProfile != null) {
        lat =
            (driverProfile['last_location_latitude'] as num?)?.toDouble() ??
            (driverProfile['last_lat'] as num?)?.toDouble() ??
            (driverProfile['latitude'] as num?)?.toDouble();
        lng =
            (driverProfile['last_location_longitude'] as num?)?.toDouble() ??
            (driverProfile['last_lng'] as num?)?.toDouble() ??
            (driverProfile['longitude'] as num?)?.toDouble();
      } else {
        // Try direct access
        lat =
            (driver['last_location_latitude'] as num?)?.toDouble() ??
            (driver['last_lat'] as num?)?.toDouble() ??
            (driver['latitude'] as num?)?.toDouble();
        lng =
            (driver['last_location_longitude'] as num?)?.toDouble() ??
            (driver['last_lng'] as num?)?.toDouble() ??
            (driver['longitude'] as num?)?.toDouble();
      }

      if (lat != null && lng != null && lat != 0 && lng != 0) {
        final driverId = driver['id']?.toString() ?? '';

        // Use motorcycle icon instead of custom card
        markers.add(
          Marker(
            markerId: MarkerId('driver_$driverId'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            anchor: const Offset(0.5, 1.0), // Bottom center
            onTap: () {
              // Move map to driver location
              // Use Get.context to avoid deactivated context issues
              if (lat != null && lng != null) {
                final safeContext = Get.context;
                if (safeContext != null) {
                  _goToDriverLocation(safeContext, LatLng(lat, lng));
                }
              }
            },
          ),
        );
      }
    }

    // Active trip driver marker
    if (controller.lastLocation.value != null &&
        controller.activeTrip.value != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('active_driver'),
          position: LatLng(
            controller.lastLocation.value!.lat,
            controller.lastLocation.value!.lng,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: const InfoWindow(title: 'سائقك'),
        ),
      );
    }

    // Update markers in controller
    controller.driverMarkers.clear();
    controller.driverMarkers.addAll(markers);
    // Update GetBuilder to refresh markers
    controller.update(['markers']);
  }

  Set<Marker> _buildMarkers(BuildContext? context) {
    // Use Get.context if context is null or not mounted
    final safeContext = (context != null && context.mounted)
        ? context
        : Get.context;

    if (safeContext == null) {
      Get.log(
        '[RideMapView] Cannot build markers: no context available',
        isError: true,
      );
      return <Marker>{};
    }
    final markers = <Marker>{};

    // Pickup marker (draggable)
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          controller.pickupLat.value,
          controller.pickupLng.value,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: 'نقطة الاستلام',
          snippet: controller.pickupAddress.value,
        ),
        draggable: true,
        onDragEnd: (LatLng newPosition) {
          controller.pickupLat.value = newPosition.latitude;
          controller.pickupLng.value = newPosition.longitude;
          Get.snackbar(
            'تم',
            'تم تحديث موقع الاستلام',
            backgroundColor: Colors.white,
            colorText: Colors.black,
            borderColor: Colors.grey.shade300,
            borderWidth: 1,
          );
        },
      ),
    );

    // Dropoff marker (draggable)
    if (controller.dropoffLat.value != 0 && controller.dropoffLng.value != 0) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(
            controller.dropoffLat.value,
            controller.dropoffLng.value,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: 'نقطة الوصول',
            snippet: controller.dropoffAddress.value,
          ),
          draggable: true,
          onDragEnd: (LatLng newPosition) {
            controller.dropoffLat.value = newPosition.latitude;
            controller.dropoffLng.value = newPosition.longitude;
            Get.snackbar(
              'تم',
              'تم تحديث موقع الوصول',
              backgroundColor: Colors.white,
              colorText: Colors.black,
              borderColor: Colors.grey.shade300,
              borderWidth: 1,
            );
          },
        ),
      );
    }

    // Add driver markers (custom card markers)
    markers.addAll(controller.driverMarkers);

    // Active trip driver marker
    if (controller.lastLocation.value != null &&
        controller.activeTrip.value != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('active_driver'),
          position: LatLng(
            controller.lastLocation.value!.lat,
            controller.lastLocation.value!.lng,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: const InfoWindow(title: 'سائقك'),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};

    if (controller.pickupLat.value != 0 &&
        controller.pickupLng.value != 0 &&
        controller.dropoffLat.value != 0 &&
        controller.dropoffLng.value != 0) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(controller.pickupLat.value, controller.pickupLng.value),
            LatLng(controller.dropoffLat.value, controller.dropoffLng.value),
          ],
          color: AppTheme.primaryColor,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    return polylines;
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.red.shade50, Colors.orange.shade50],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.map, color: Colors.red.shade300, size: 80),
              const SizedBox(height: 24),
              Text(
                'خطأ في تحميل الخريطة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                controller.mapError.value!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  controller.mapError.value = null;
                },
                icon: const Icon(Iconsax.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm(
    BuildContext context,
    ScrollController scrollController,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Drivers card (above form, expands in place)
          _buildDriversCardExpandable(context),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                // Step Progress Indicator
                Obx(() {
                  final step = controller.currentRequestStep.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.arrow_down_1,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'الخطوة $step من 3',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),

                // Step Content
                Obx(() {
                  final step = controller.currentRequestStep.value;
                  
                  if (step == 1) {
                    return _buildStep1Pickup(context);
                  } else if (step == 2) {
                    return _buildStep2Dropoff(context);
                  } else {
                    return _buildStep3Price(context);
                  }
                }),
                
                const SizedBox(height: 32),
                
                // Navigation Buttons
                Obx(() {
                  final step = controller.currentRequestStep.value;
                  final isLoading = controller.isBusy.value || controller.isRequestingTrip.value;
                  
                  return Row(
                    children: [
                      // Previous Button
                      if (step > 1)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.goToPreviousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade300, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'السابق',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      if (step > 1) const SizedBox(width: 12),
                      
                      // Next/Submit Button
                      Expanded(
                        flex: step > 1 ? 1 : 1,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () {
                            if (step < 3) {
                              controller.goToNextStep();
                            } else {
                              // Final step - submit request
                              controller.requestTrip();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      step < 3 ? Iconsax.arrow_left_2 : Iconsax.send_2,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      step < 3 ? 'التالي' : 'طلب الرحلة',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCardContent(
    BuildContext context,
    String type,
    bool isSelected,
  ) {
    final isPickup = type == 'pickup';
    return InkWell(
      onTap: () {
        controller.selectionMode.value = isPickup ? 'pickup' : 'dropoff';
        Get.snackbar(
          isPickup ? 'اختر موقع الاستلام' : 'اختر موقع الوصول',
          isPickup
              ? 'اضغط على الخريطة لتحديد موقع الاستلام'
              : 'اضغط على الخريطة لتحديد موقع الوصول',
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.white,
          colorText: Colors.black,
          borderColor: Colors.grey.shade300,
          borderWidth: 1,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPickup ? Iconsax.location : Iconsax.location_add,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPickup ? 'من وين' : 'إلى أين تريد الذهاب',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPickup
                            ? 'اضغط هنا ثم حدد في الخارطة موقعك الحالي الذي انت فيه'
                            : 'اضغط هنا ثم حدد في الخارطة موقع الوصول الذي تريده',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  final currentMode = controller.selectionMode.value;
                  if (currentMode == (isPickup ? 'pickup' : 'dropoff')) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'اختر',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Iconsax.gps),
                  onPressed: () {
                    if (isPickup) {
                      _getCurrentLocation(context, true);
                    } else {
                      _getCurrentLocation(context, false);
                    }
                    controller.selectionMode.value = null;
                  },
                  tooltip: 'استخدام موقعي الحالي',
                  color: Colors.black,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(BuildContext context) {
    final trip = controller.activeTrip.value!;
    final status = trip['status']?.toString() ?? '';
    final driverName = trip['driver']?['name']?.toString() ?? 'سائق';
    final acceptedPrice = (trip['accepted_price'] as num?)?.toDouble();
    final tripId = trip['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        controller.tripId.value = tripId;
        Get.toNamed(Routes.tripTracking);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
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
                Iconsax.car,
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
                    status == 'assigned' ? 'السائق في الطريق' : 'الرحلة جارية',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'السائق: $driverName',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (acceptedPrice != null)
                    Text(
                      '${acceptedPrice.toStringAsFixed(0)} ريال',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.arrow_left_2, size: 20),
              onPressed: () {
                controller.tripId.value = tripId;
                Get.toNamed(Routes.tripTracking);
              },
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _handleMapTap(LatLng position) {
    // Only allow selection if in selection mode
    final mode = controller.selectionMode.value;
    if (mode == null) {
      Get.snackbar(
        'تنبيه',
        'يرجى اختيار نوع الموقع أولاً (استلام أو وصول)',
        backgroundColor: Colors.white,
        colorText: Colors.black,
        borderColor: Colors.grey.shade300,
        borderWidth: 1,
      );
      return;
    }

    if (mode == 'pickup') {
      controller.pickupLat.value = position.latitude;
      controller.pickupLng.value = position.longitude;
      controller.isPickupSelected.value = true; // Mark as selected
      controller.isSelectingOnMap.value = false; // Exit selecting state
      controller.selectionMode.value = null; // Exit selection mode
      
      // Animate sheet back up
      _animateSheetTo(0.5);
      
      Get.snackbar(
        '✅ تم بنجاح!',
        'تم تحديد موقع الاستلام',
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade900,
        borderColor: Colors.green.shade300,
        borderWidth: 2,
        duration: const Duration(seconds: 2),
      );
      
      // Auto-advance to next step after a short delay
      Future.delayed(const Duration(milliseconds: 800), () {
        controller.goToNextStep();
      });
    } else if (mode == 'dropoff') {
      controller.dropoffLat.value = position.latitude;
      controller.dropoffLng.value = position.longitude;
      controller.isDropoffSelected.value = true; // Mark as selected
      controller.isSelectingOnMap.value = false; // Exit selecting state
      controller.selectionMode.value = null; // Exit selection mode
      
      // Animate sheet back up
      _animateSheetTo(0.5);
      
      Get.snackbar(
        '✅ تم بنجاح!',
        'تم تحديد موقع الوصول',
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade900,
        borderColor: Colors.green.shade300,
        borderWidth: 2,
        duration: const Duration(seconds: 2),
      );
      
      // Auto-advance to next step after a short delay
      Future.delayed(const Duration(milliseconds: 800), () {
        controller.goToNextStep();
        // Animate to taller size for price step
        Future.delayed(const Duration(milliseconds: 100), () {
          _animateSheetTo(0.65);
        });
      });
    }
  }

  /// Go to nearest driver location
  void _goToNearestDriver(BuildContext context) async {
    // Load drivers first if list is empty
    if (controller.nearbyDrivers.isEmpty) {
      Get.log('[RideMapView] No drivers in list, loading nearby drivers...');
      await controller.loadNearbyDrivers();
      // Wait a bit for drivers to load
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (controller.nearbyDrivers.isEmpty) {
      Get.snackbar(
        'لا يوجد سائقين',
        'لا يوجد سائقين متاحين حالياً. تأكد من أن السائقين متصلين وأرسلوا موقعهم مؤخراً.',
        backgroundColor: Colors.white,
        colorText: Colors.orange.shade700,
        borderColor: Colors.orange.shade300,
        borderWidth: 1,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Find nearest driver
    double? nearestLat;
    double? nearestLng;
    double minDistance = double.infinity;

    for (var driver in controller.nearbyDrivers) {
      Map<String, dynamic>? driverProfile;
      if (driver['driver_profile'] != null) {
        driverProfile = driver['driver_profile'] as Map<String, dynamic>?;
      }

      double? lat;
      double? lng;

      if (driverProfile != null) {
        lat =
            (driverProfile['last_location_latitude'] as num?)?.toDouble() ??
            (driverProfile['last_lat'] as num?)?.toDouble();
        lng =
            (driverProfile['last_location_longitude'] as num?)?.toDouble() ??
            (driverProfile['last_lng'] as num?)?.toDouble();
      } else {
        lat =
            (driver['last_location_latitude'] as num?)?.toDouble() ??
            (driver['last_lat'] as num?)?.toDouble();
        lng =
            (driver['last_location_longitude'] as num?)?.toDouble() ??
            (driver['last_lng'] as num?)?.toDouble();
      }

      if (lat != null && lng != null && lat != 0 && lng != 0) {
        final distance = _calculateDistance(
          controller.pickupLat.value,
          controller.pickupLng.value,
          lat,
          lng,
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearestLat = lat;
          nearestLng = lng;
        }
      }
    }

    if (nearestLat != null &&
        nearestLng != null &&
        controller.mapController != null) {
      controller.mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(nearestLat, nearestLng), 16),
      );
      Get.snackbar(
        'تم',
        'تم الانتقال إلى أقرب سائق',
        backgroundColor: Colors.white,
        colorText: Colors.black,
        borderColor: Colors.grey.shade300,
        borderWidth: 1,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  Future<void> _getCurrentLocation(BuildContext context, bool isPickup) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'تنبيه',
            'يجب السماح بالوصول للموقع',
            backgroundColor: Colors.white,
            colorText: Colors.black,
            borderColor: Colors.grey.shade300,
            borderWidth: 1,
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'تنبيه',
          'الرجاء تفعيل صلاحيات الموقع من إعدادات التطبيق',
          backgroundColor: Colors.white,
          colorText: Colors.black,
          borderColor: Colors.grey.shade300,
          borderWidth: 1,
        );
        return;
      }

      controller.hasLocationPermission.value =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final shouldOpen = await Get.dialog<bool>(
          Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('تفعيل خدمة المواقع'),
              content: const Text(
                'يجب تفعيل خدمة المواقع لاستخدام هذه الميزة. هل تريد فتح إعدادات الموقع؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('فتح الإعدادات'),
                ),
              ],
            ),
          ),
        );
        if (shouldOpen == true) {
          await Geolocator.openLocationSettings();
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (isPickup) {
        controller.pickupLat.value = position.latitude;
        controller.pickupLng.value = position.longitude;
        controller.isPickupSelected.value = true; // Mark step as complete
        controller.pickupAddress.value = 'موقعي الحالي';
        
        Get.snackbar(
          '✅ تم بنجاح!',
          'تم تحديد موقعك الحالي كنقطة استلام',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
          borderColor: Colors.green.shade300,
          borderWidth: 2,
        );
        
        // Refresh nearby drivers only when pickup location changes
        controller.loadNearbyDrivers();
        
        // Auto-advance to next step
        Future.delayed(const Duration(milliseconds: 800), () {
          controller.goToNextStep();
        });
      } else {
        controller.dropoffLat.value = position.latitude;
        controller.dropoffLng.value = position.longitude;
        controller.isDropoffSelected.value = true; // Mark step as complete
        controller.dropoffAddress.value = 'موقعي الحالي';
        
        Get.snackbar(
          '✅ تم بنجاح!',
          'تم تحديد موقعك الحالي كنقطة وصول',
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
          borderColor: Colors.green.shade300,
          borderWidth: 2,
        );
        
        // Auto-advance to next step
        Future.delayed(const Duration(milliseconds: 800), () {
          controller.goToNextStep();
        });
      }
    } catch (e) {
      Get.log('[RideMapView] Location error: $e', isError: true);
      Get.snackbar(
        'خطأ',
        'فشل الحصول على الموقع: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red.shade700,
        borderColor: Colors.red.shade300,
        borderWidth: 1,
      );
    }
  }

  /// Show driver details (show bottom sheet instead of navigating)
  void _showDriverDetails(BuildContext? context, Map<String, dynamic> driver) {
    // Use Get.context if context is null or deactivated
    final safeContext = context ?? Get.context;
    if (safeContext != null && safeContext.mounted) {
      _showDriverCardBottomSheet(safeContext, driver);
    } else {
      Get.log('[RideMapView] Context is not available, using Get.context');
      _showDriverCardBottomSheet(Get.context!, driver);
    }
  }

  /// Show driver card as bottom sheet when marker is tapped
  void _showDriverCardBottomSheet(
    BuildContext? context,
    Map<String, dynamic> driver,
  ) {
    // Use Get.context if context is null or not mounted
    final safeContext = (context != null && context.mounted)
        ? context
        : Get.context;

    if (safeContext == null) {
      Get.log(
        '[RideMapView] Cannot show driver details: no context available',
        isError: true,
      );
      return;
    }

    // Log driver data for debugging
    Get.log('[RideMapView] Showing driver details: ${driver.keys.toList()}');

    // Extract driver data - try multiple possible structures
    Map<String, dynamic>? driverProfile;
    if (driver['driver_profile'] != null) {
      driverProfile = driver['driver_profile'] as Map<String, dynamic>?;
      Get.log('[RideMapView] Found driver_profile');
    } else if (driver['profile'] != null) {
      driverProfile = driver['profile'] as Map<String, dynamic>?;
      Get.log('[RideMapView] Found profile');
    }

    // Extract driver ID
    final driverId =
        driver['id']?.toString() ??
        driver['user_id']?.toString() ??
        driver['driver_id']?.toString() ??
        '';

    // Extract driver name - try multiple possible keys
    final driverName =
        driver['name']?.toString() ??
        driver['user_name']?.toString() ??
        driver['driver_name']?.toString() ??
        driverProfile?['name']?.toString() ??
        'سائق';

    // Extract rating - try multiple possible keys
    final rating =
        (driverProfile?['rating'] as num?)?.toDouble() ??
        (driverProfile?['average_rating'] as num?)?.toDouble() ??
        (driver['rating'] as num?)?.toDouble() ??
        (driver['average_rating'] as num?)?.toDouble() ??
        0.0;

    // Extract avatar URL - try multiple possible keys
    final avatarUrl =
        driverProfile?['avatar'] as String? ??
        driverProfile?['avatar_url'] as String? ??
        driverProfile?['photo'] as String? ??
        driver['avatar'] as String? ??
        driver['avatar_url'] as String? ??
        driver['photo'] as String?;

    // Extract additional data like in DriverDetailsView
    final phone =
        driver['phone']?.toString() ??
        driverProfile?['phone']?.toString() ??
        '';
    final tripsCount =
        (driverProfile?['trips_count'] as num?)?.toInt() ??
        (driver['trips_count'] as num?)?.toInt() ??
        0;
    final bikePlate =
        driverProfile?['bike_plate']?.toString() ??
        driver['bike_plate']?.toString() ??
        '';
    final reviews =
        driver['reviews'] as List? ?? driverProfile?['reviews'] as List? ?? [];

    Get.log(
      '[RideMapView] Driver details - ID: $driverId, Name: $driverName, Rating: $rating, Avatar: $avatarUrl',
    );

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(safeContext).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Driver Header
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar(safeContext);
                                },
                              ),
                            )
                          : _buildDefaultAvatar(safeContext),
                    ),
                    const SizedBox(width: 16),
                    // Driver Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Rating Stars
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < rating.floor()
                                      ? Icons.star
                                      : (index < rating
                                            ? Icons.star_half
                                            : Icons.star_border),
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        safeContext,
                        icon: Icons.directions_bike,
                        value: '$tripsCount',
                        label: 'رحلة مكتملة',
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        safeContext,
                        icon: Icons.star,
                        value: rating.toStringAsFixed(1),
                        label: 'التقييم',
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        safeContext,
                        icon: Icons.verified,
                        value: 'موثق',
                        label: 'الحالة',
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Driver Info Card
                _buildInfoCard(
                  safeContext,
                  title: 'معلومات السائق',
                  children: [
                    _buildInfoRow(
                      icon: Icons.badge,
                      label: 'رقم اللوحة',
                      value: bikePlate.isNotEmpty ? bikePlate : 'غير متوفر',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      icon: Icons.phone,
                      label: 'رقم الهاتف',
                      value: phone.isNotEmpty ? phone : 'غير متوفر',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reviews Section (always show, even if empty)
                _buildInfoCard(
                  safeContext,
                  title: 'التقييمات والآراء',
                  children: [
                    if (reviews.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 48,
                                color: AppTheme.lightGrey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'لا توجد تقييمات بعد',
                                style: TextStyle(color: AppTheme.lightGrey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...reviews.take(5).map((review) {
                        final reviewRating =
                            (review['rating'] as num?)?.toDouble() ?? 0;
                        final comment = review['comment']?.toString() ?? '';
                        final reviewerName =
                            review['reviewer']?['name']?.toString() ?? 'راكب';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildReviewItem(
                            reviewerName: reviewerName,
                            rating: reviewRating,
                            comment: comment,
                          ),
                        );
                      }),
                  ],
                ),
                const SizedBox(height: 16),

                // Request Ride Button
                Obx(() {
                  final isLoading =
                      controller.isBusy.value ||
                      controller.isRequestingTrip.value;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Get.back(); // Close bottom sheet
                              // Set pickup and dropoff if not set
                              if (controller.pickupLat.value == 0.0 ||
                                  controller.dropoffLat.value == 0.0) {
                                Get.snackbar(
                                  'تنبيه',
                                  'يرجى تحديد موقع الاستلام والوصول أولاً',
                                  backgroundColor: AppTheme.white,
                                  colorText: AppTheme.warning,
                                  borderColor: AppTheme.warning.withOpacity(
                                    0.3,
                                  ),
                                  borderWidth: 1,
                                  borderRadius: 12,
                                );
                                return;
                              }
                              // Request trip with this driver
                              controller.requestTripWithDriver(driverId);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AppTheme.primaryColor
                            .withOpacity(0.5),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_bike,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'طلب رحلة مع هذا السائق',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
  }

  /// Build default avatar when no image
  Widget _buildDefaultAvatar(BuildContext context) {
    return Center(
      child: Icon(
        Iconsax.user,
        size: 36,
        color: AppTheme.primaryColor.withOpacity(0.4),
      ),
    );
  }

  /// Build stat card (same as DriverDetailsView)
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.lightGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build info card (same as DriverDetailsView)
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// Build info row (same as DriverDetailsView)
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppTheme.lightGrey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build review item (same as DriverDetailsView)
  Widget _buildReviewItem({
    required String reviewerName,
    required double rating,
    required String comment,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryLight,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(color: AppTheme.mediumGrey, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  /// Create custom marker icon from driver card widget using Canvas (fast and reliable)
  Future<BitmapDescriptor?> _createDriverCardMarker(
    BuildContext context,
    String driverId,
    String driverName,
    double rating,
    String? avatarUrl,
  ) async {
    // Use Canvas directly - faster and more reliable than Widget-to-Image
    return await _createDriverCardMarkerCanvas(driverName, rating, avatarUrl);
  }

  /// Build SDUI-compatible driver card widget for marker
  Widget _buildDriverCardMarkerWidget(
    String driverName,
    double rating,
    String? avatarUrl,
  ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 200,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightGrey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Iconsax.user,
                            size: 24,
                            color: AppTheme.primaryColor.withOpacity(0.4),
                          ),
                        ),
                      )
                    : Icon(
                        Iconsax.user,
                        size: 24,
                        color: AppTheme.primaryColor.withOpacity(0.4),
                      ),
              ),
            ),
            // Driver Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    driverName,
                    style: const TextStyle(
                      color: AppTheme.darkGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppTheme.mediumGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Request Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 74,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'طلب مشوار',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Convert widget to image bytes using RepaintBoundary (SDUI compatible)
  Future<Uint8List?> _widgetToImage(Widget widget) async {
    try {
      final key = GlobalKey();

      // Wrap widget in RepaintBoundary for efficient rendering
      final repaintBoundary = RepaintBoundary(key: key, child: widget);

      // Build widget tree in a temporary overlay (off-screen)
      final overlay = Overlay.of(Get.context!);
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -1000, // Off-screen
          top: -1000,
          child: Material(
            type: MaterialType.transparency,
            child: repaintBoundary,
          ),
        ),
      );

      overlay.insert(overlayEntry);

      // Wait for frame to render
      await Future.delayed(const Duration(milliseconds: 100));
      await WidgetsBinding.instance.endOfFrame;

      // Find RepaintBoundary and capture
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        overlayEntry.remove();
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      overlayEntry.remove();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      Get.log(
        '[RideMapView] Error converting widget to image: $e',
        isError: true,
      );
      return null;
    }
  }

  /// Fallback: Create marker using Canvas (simpler, more reliable)
  Future<BitmapDescriptor?> _createDriverCardMarkerCanvas(
    String driverName,
    double rating,
    String? avatarUrl,
  ) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(200, 80);

      // Draw card background
      final cardPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final cardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      );
      canvas.drawRRect(cardRect, cardPaint);

      // Draw border
      final borderPaint = Paint()
        ..color = AppTheme.lightGrey.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(cardRect, borderPaint);

      // Draw avatar circle
      final avatarRadius = 24.0;
      final avatarX = 16.0 + avatarRadius;
      final avatarY = size.height / 2;
      final avatarPaint = Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(avatarX, avatarY), avatarRadius, avatarPaint);

      // Draw driver name
      final nameTextPainter = TextPainter(
        text: TextSpan(
          text: driverName,
          style: const TextStyle(
            color: AppTheme.darkGrey,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.rtl,
        maxLines: 1,
        ellipsis: '...',
      );
      nameTextPainter.layout();
      nameTextPainter.paint(
        canvas,
        Offset(avatarX + avatarRadius + 12, avatarY - 20),
      );

      // Draw rating
      final ratingText = '⭐ ${rating.toStringAsFixed(1)}';
      final ratingTextPainter = TextPainter(
        text: TextSpan(
          text: ratingText,
          style: const TextStyle(
            color: AppTheme.mediumGrey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.rtl,
      );
      ratingTextPainter.layout();
      ratingTextPainter.paint(
        canvas,
        Offset(avatarX + avatarRadius + 12, avatarY + 4),
      );

      // Draw button background
      final buttonPaint = Paint()
        ..color = AppTheme.primaryColor
        ..style = PaintingStyle.fill;
      final buttonRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 90, 16, 74, 48),
        const Radius.circular(12),
      );
      canvas.drawRRect(buttonRect, buttonPaint);

      // Draw button text
      final buttonTextPainter = TextPainter(
        text: const TextSpan(
          text: 'طلب مشوار',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.rtl,
      );
      buttonTextPainter.layout();
      buttonTextPainter.paint(
        canvas,
        Offset(size.width - 90 + 37 - buttonTextPainter.width / 2, 32),
      );

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final uint8List = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(uint8List);
    } catch (e) {
      Get.log('[RideMapView] Error in Canvas fallback: $e', isError: true);
      return null;
    }
  }

  /// Build expandable drivers card (above form, expands in place)
  Widget _buildDriversCardExpandable(BuildContext context) {
    if (controller.nearbyDrivers.isEmpty) {
      return const SizedBox.shrink();
    }

    return GetBuilder<RideController>(
      id: 'nearbyDrivers',
      builder: (controller) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (always visible)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _isDriversListExpanded.value =
                        !_isDriversListExpanded.value;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_bike,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'إظهار السائقين القريبين (${controller.nearbyDrivers.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                        ),
                        Obx(
                          () => Icon(
                            _isDriversListExpanded.value
                                ? Iconsax.arrow_down_2
                                : Iconsax.arrow_left_2,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Expandable list
                Obx(() {
                  if (!_isDriversListExpanded.value) {
                    return const SizedBox.shrink();
                  }
                  // Expand sheet when drivers list is shown
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _sheetController.animateTo(
                      0.7,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  });
                  return Container(
                    height: 100,
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.nearbyDrivers.length,
                      itemBuilder: (context, index) {
                        final driver = controller.nearbyDrivers[index];
                        return _buildDriverCard(context, driver);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build driver card for horizontal list
  Widget _buildDriverCard(BuildContext context, Map<String, dynamic> driver) {
    Map<String, dynamic>? driverProfile;
    if (driver['driver_profile'] != null) {
      driverProfile = driver['driver_profile'] as Map<String, dynamic>?;
    } else if (driver['profile'] != null) {
      driverProfile = driver['profile'] as Map<String, dynamic>?;
    }

    final driverName = driver['name']?.toString() ?? 'سائق';
    final rating =
        (driverProfile?['rating'] as num?)?.toDouble() ??
        (driver['rating'] as num?)?.toDouble() ??
        0.0;
    final avatarUrl = driverProfile?['avatar'] as String?;

    // Extract location using same logic as _goToNearestDriver and _buildAllMarkers
    double? lat;
    double? lng;

    if (driverProfile != null) {
      lat =
          (driverProfile['last_location_latitude'] as num?)?.toDouble() ??
          (driverProfile['last_lat'] as num?)?.toDouble() ??
          (driverProfile['latitude'] as num?)?.toDouble();
      lng =
          (driverProfile['last_location_longitude'] as num?)?.toDouble() ??
          (driverProfile['last_lng'] as num?)?.toDouble() ??
          (driverProfile['longitude'] as num?)?.toDouble();
    } else {
      lat =
          (driver['last_location_latitude'] as num?)?.toDouble() ??
          (driver['last_lat'] as num?)?.toDouble() ??
          (driver['latitude'] as num?)?.toDouble();
      lng =
          (driver['last_location_longitude'] as num?)?.toDouble() ??
          (driver['last_lng'] as num?)?.toDouble() ??
          (driver['longitude'] as num?)?.toDouble();
    }

    return Container(
      width: 180, // Width as requested
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar (smaller for compact card)
          Container(
            margin: const EdgeInsets.all(6),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Iconsax.user,
                        size: 24,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                : const Icon(
                    Iconsax.user,
                    size: 24,
                    color: AppTheme.primaryColor,
                  ),
          ),
          // Driver Info (compact)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Text(
                    driverName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Action buttons (vertical stack)
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Details button
                GestureDetector(
                  onTap: () {
                    // Collapse sheet to show map
                    _isDriversListExpanded.value = false;
                    _sheetController.animateTo(
                      0.3,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    // Show driver details (navigate to DriverDetailsView)
                    // Use Get.context to avoid deactivated context issues
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (Get.context != null) {
                        _showDriverDetails(Get.context, driver);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.info_circle,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'معلومات',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Go to location button
                GestureDetector(
                  onTap: () async {
                    // Close expanded list
                    _isDriversListExpanded.value = false;
                    // Collapse sheet
                    _sheetController.animateTo(
                      0.3,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    // Go to driver location
                    if (lat != null && lng != null && lat != 0 && lng != 0) {
                      // Wait for sheet to collapse
                      await Future.delayed(const Duration(milliseconds: 350));
                      // Ensure markers are built (use Get.context to avoid deactivated context)
                      await _buildAllMarkers(Get.context);
                      // Wait a bit more for markers to render
                      await Future.delayed(const Duration(milliseconds: 200));
                      // Go to location (use Get.context to avoid deactivated context)
                      final safeContext = Get.context;
                      if (safeContext != null) {
                        await _goToDriverLocation(
                          safeContext,
                          LatLng(lat, lng),
                        );
                      }
                    } else {
                      Get.snackbar(
                        'تنبيه',
                        'موقع السائق غير متاح',
                        backgroundColor: Colors.white,
                        colorText: Colors.red,
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.location,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'عرض',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  /// Go to driver location on map
  Future<void> _goToDriverLocation(
    BuildContext context,
    LatLng location,
  ) async {
    if (controller.mapController != null) {
      try {
        // Animate camera to driver location with zoom
        await controller.mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 16),
        );

        // Wait a bit then zoom in more to make sure marker is visible
        await Future.delayed(const Duration(milliseconds: 500));
        await controller.mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 17),
        );

        Get.log('[RideMapView] Camera moved to driver location: $location');
      } catch (e) {
        Get.log('[RideMapView] Error moving camera: $e', isError: true);
        Get.snackbar(
          'تنبيه',
          'فشل الانتقال إلى موقع السائق',
          backgroundColor: Colors.white,
          colorText: Colors.red,
        );
      }
    } else {
      Get.log('[RideMapView] Map controller is null', isError: true);
      Get.snackbar(
        'تنبيه',
        'الخريطة غير جاهزة بعد',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }

  // ========== Step Builder Methods for Beginner-Friendly UI ==========
  
  /// Step 1: Pickup Location Selection
  Widget _buildStep1Pickup(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step Title with Icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.location,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'حدد موقع الاستلام\n(من وين؟)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Main Selection Button
        Obx(() {
          final isSelected = controller.isPickupSelected.value;
          final isSelecting = controller.isSelectingOnMap.value && 
                              controller.selectionMode.value == 'pickup';
          
          return ElevatedButton(
            onPressed: isSelected ? null : () {
              // Activate selection mode
              controller.isSelectingOnMap.value = true;
              controller.selectionMode.value = 'pickup';
              // Animate sheet down to show more map
              _animateSheetTo(0.3);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: isSelected 
                  ? Colors.green 
                  : isSelecting 
                      ? Colors.grey.shade300 
                      : AppTheme.primaryColor,
              foregroundColor: isSelecting ? Colors.grey.shade700 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected 
                      ? Iconsax.tick_circle 
                      : isSelecting 
                          ? Iconsax.finger_cricle 
                          : Iconsax.map_1,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isSelected 
                      ? 'تم التحديد ✓' 
                      : isSelecting 
                          ? 'قم بالتحديد على الخريطة' 
                          : 'اضغط هنا لتحديد موقعك على الخريطة',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
        
        const SizedBox(height: 16),
        
        // Divider with "أو"
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'أو',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // GPS Button
        OutlinedButton(
          onPressed: () => _getCurrentLocation(context, true),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            side: BorderSide(color: AppTheme.primaryColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.gps, size: 22, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                '📱 استخدم موقعي الحالي',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tip Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Iconsax.info_circle, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '💡 نصيحة: اضغط على الزر الأخضر ثم اضغط على الخريطة في موقعك',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Step 2: Dropoff Location Selection
  Widget _buildStep2Dropoff(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step Title with Icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.flag,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'حدد موقع الوصول\n(إلى وين؟)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Main Selection Button
        Obx(() {
          final isSelected = controller.isDropoffSelected.value;
          final isSelecting = controller.isSelectingOnMap.value && 
                              controller.selectionMode.value == 'dropoff';
          
          return ElevatedButton(
            onPressed: isSelected ? null : () {
              // Activate selection mode
              controller.isSelectingOnMap.value = true;
              controller.selectionMode.value = 'dropoff';
              // Animate sheet down to show more map
              _animateSheetTo(0.3);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: isSelected 
                  ? Colors.green 
                  : isSelecting 
                      ? Colors.grey.shade300 
                      : Colors.red.shade600,
              foregroundColor: isSelecting ? Colors.grey.shade700 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected 
                      ? Iconsax.tick_circle 
                      : isSelecting 
                          ? Iconsax.finger_cricle 
                          : Iconsax.map_1,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isSelected 
                      ? 'تم التحديد ✓' 
                      : isSelecting 
                          ? 'قم بالتحديد على الخريطة' 
                          : 'اضغط هنا لتحديد وجهتك على الخريطة',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
        
        const SizedBox(height: 20),
        
        // Tip Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Iconsax.info_circle, color: Colors.orange.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '💡 نصيحة: اضغط على الزر الأحمر ثم اضغط على الخريطة في وجهتك',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Step 3: Price Selection
  Widget _buildStep3Price(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step Title with Icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.dollar_circle,
                color: Colors.amber.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'كم السعر اللي تدفعه؟',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Instruction
        Text(
          'اختر سعر أو اكتب سعرك:',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        
        // Price Chips
        Obx(() {
          final selectedChip = controller.selectedPriceChip.value;
          return Row(
            children: [
              Expanded(
                child: _buildPriceChip(1, 1000, selectedChip == 1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceChip(2, 1200, selectedChip == 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceChip(3, 1500, selectedChip == 3),
              ),
            ],
          );
        }),
        
        const SizedBox(height: 24),
        
        // Divider with "أو"
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'أو اكتب سعر آخر',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Custom Price Input
        TextField(
          decoration: InputDecoration(
            hintText: 'أدخل السعر',
            suffixText: 'ريال',
            prefixIcon: const Icon(Iconsax.edit, size: 22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            final price = double.tryParse(v);
            if (price != null) {
              controller.offeredPrice.value = price;
              controller.selectedPriceChip.value = 0; // Deselect chips
              controller.isPriceSelected.value = true;
            }
          },
        ),
      ],
    );
  }
  
  /// Build a price chip button
  Widget _buildPriceChip(int chipNumber, double price, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.selectPriceChip(chipNumber, price),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              '${price.toInt()}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ريال',
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Animate bottom sheet to specific size
  void _animateSheetTo(double size) {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        size,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
