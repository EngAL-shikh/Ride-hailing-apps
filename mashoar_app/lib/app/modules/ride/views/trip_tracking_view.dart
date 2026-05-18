import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/ride_controller.dart';
import '../../driver/controllers/driver_controller.dart';
import '../../../core/storage/auth_store.dart';
import '../../../theme/app_theme.dart';
import '../../../core/firebase/realtime_tracking_service.dart';
import '../../../core/config/app_config.dart';

/// Professional trip tracking view inspired by Uber/Careem
/// Shows real-time driver location, trip status, and actions
class TripTrackingView extends StatefulWidget {
  const TripTrackingView({super.key});

  @override
  State<TripTrackingView> createState() => _TripTrackingViewState();
}

class _TripTrackingViewState extends State<TripTrackingView> {
  Timer? _refreshTimer;
  BitmapDescriptor? _motorcycleIcon;
  bool _isLoadingIcon = false;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  StreamSubscription? _locationSubscription;
  DateTime _lastCameraUpdate = DateTime.now();
  bool _isFollowing = true;
  bool _isAnimating = false;
  
  @override
  void initState() {
    super.initState();
    // REMOVED: Timer-based polling - RTDB listeners handle real-time updates
    // No need to poll API every 5 seconds when we have real-time listeners
    
    // Load motorcycle icon
    _loadMotorcycleIcon();
    
    // Initial markers build
    _initializeMapData();

    // Start listening to location updates to update map markers/camera without rebuilding whole map
    _setupLocationListener();
  }

  void _initializeMapData() {
    // This will be called before the first build
    // We'll use a dummy/initial set of markers
  }

  void _setupLocationListener() {
    final rideController = Get.find<RideController>();
    _locationSubscription = rideController.lastLocation.listen((loc) {
      if (loc != null && mounted) {
        _updateMarkersAndCamera(loc);
      }
    });
  }

  void _updateMarkersAndCamera(DriverLocation loc) {
    if (!mounted || !_isFollowing) return;

    // Use a small throttle to avoid jitter during fast movement
    if (_mapController != null && 
        DateTime.now().difference(_lastCameraUpdate).inMilliseconds >= 1000) {
      Get.log('[TripTrackingView] Auto-following camera to: ${loc.lat}, ${loc.lng}');
      _isAnimating = true;
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
      ).then((_) => _isAnimating = false);
      _lastCameraUpdate = DateTime.now();
    }
  }

  void _onCameraMoveStarted() {
    // If the camera starts moving and it's NOT from our internal animation,
    // it means the user is manually moving the map.
    if (!_isAnimating && _isFollowing) {
      setState(() {
        _isFollowing = false;
        Get.log('[TripTrackingView] User moved map, disabling auto-follow');
      });
    }
  }

  void _recenter() {
    final rideController = Get.find<RideController>();
    final loc = rideController.lastLocation.value;
    if (loc != null && _mapController != null) {
      setState(() {
        _isFollowing = true;
        _isAnimating = true;
      });
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(loc.lat, loc.lng), 15),
      ).then((_) => _isAnimating = false);
    }
  }
  
  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
  
  /// Create custom motorcycle icon marker
  Future<void> _loadMotorcycleIcon() async {
    if (_isLoadingIcon) return;
    _isLoadingIcon = true;
    
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = 80.0;
      
      // Draw background circle
      final paint = Paint()
        ..color = AppTheme.primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 4,
        paint,
      );
      
      // Draw white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 4,
        borderPaint,
      );
      
      // Draw motorcycle icon using IconData
      final iconData = Icons.directions_bike;
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: 40,
            fontFamily: iconData.fontFamily,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size - textPainter.width) / 2,
          (size - textPainter.height) / 2,
        ),
      );
      
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final uint8List = byteData!.buffer.asUint8List();
      
      _motorcycleIcon = BitmapDescriptor.fromBytes(uint8List);
    } catch (e) {
      Get.log('[TripTrackingView] Error creating motorcycle icon: $e', isError: true);
      // Fallback to default blue marker
      _motorcycleIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    } finally {
      _isLoadingIcon = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // REMOVED: Refresh on build - RTDB listeners handle all updates
    // No need to call API on every build when we have real-time listeners
    
    final isDriver = AuthStore.userType == 'driver';
    
    // Get trip ID from arguments or controller
    final arguments = Get.arguments;
    Map<String, dynamic>? tripFromArgs;
    String? tripIdFromArgs;
    
    if (arguments is Map<String, dynamic>) {
      final tripArg = arguments['trip'];
      if (tripArg is Map<String, dynamic>) {
        tripFromArgs = tripArg;
        tripIdFromArgs = tripArg['id']?.toString();
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceGrey,
        body: Obx(() {
          // For drivers, use DriverController
          if (isDriver) {
            final driverController = Get.find<DriverController>();
            final activeTripId = tripIdFromArgs ?? driverController.activeTripId.value;
            
            if (activeTripId.isEmpty) {
              return _buildNoTripState(context);
            }

            // Always get trip from controller (to get latest status updates)
            // Priority: activeTrip > availableTrips > tripFromArgs
            Map<String, dynamic>? trip = driverController.activeTrip.value;
            
            if (trip == null || trip['id']?.toString() != activeTripId) {
              // Try to find in available trips
              try {
                trip = driverController.availableTrips.firstWhere(
                  (t) => t['id']?.toString() == activeTripId,
                );
              } catch (e) {
                // Fallback to tripFromArgs if not found
                trip = tripFromArgs;
              }
            }
            
            // trip should not be null here, but check anyway
            if (trip == null || trip['id']?.toString() != activeTripId) {
              return _buildLoadingState(context);
            }
            
            // Log status for debugging
            Get.log('[TripTrackingView] Building trip tracking for driver trip ${trip['id']}, status: ${trip['status']}');
            
            return _buildTripTracking(context, trip, isDriver);
          }
          
          // For riders, use RideController
          final rideController = Get.find<RideController>();
          final activeTripId = tripIdFromArgs ?? rideController.tripId.value;
          
          if (activeTripId.isEmpty) {
            return _buildNoTripState(context);
          }

          // Always get trip from controller (to get latest status updates)
          // Priority: activeTrip > myTrips > tripFromArgs
          Map<String, dynamic>? trip = rideController.activeTrip.value;
          
          if (trip == null || trip['id']?.toString() != activeTripId) {
            // Try to find in myTrips
            try {
              trip = rideController.myTrips.firstWhere(
                (t) => t['id']?.toString() == activeTripId,
              );
            } catch (e) {
              // Fallback to tripFromArgs if not found
              trip = tripFromArgs;
            }
          }

          if (trip == null) {
            return _buildLoadingState(context);
          }
          
          // Log status for debugging
          Get.log('[TripTrackingView] Building trip tracking for trip ${trip['id']}, status: ${trip['status']}');
          
          return _buildTripTracking(context, trip, isDriver);
        }),
      ),
    );
  }

  Widget _buildTripTracking(BuildContext context, Map<String, dynamic> trip, bool isDriver) {
    final tripId = trip['id']?.toString() ?? '';
    final rideController = Get.find<RideController>();
    
    // Initial data extraction (stable)
    final pickup = trip['pickup'] as Map<String, dynamic>?;
    final dropoff = trip['dropoff'] as Map<String, dynamic>?;
    final pickupLat = (pickup?['lat'] as num?)?.toDouble() ?? 15.3694;
    final pickupLng = (pickup?['lng'] as num?)?.toDouble() ?? 44.191;
    final dropoffLat = (dropoff?['lat'] as num?)?.toDouble() ?? 15.4;
    final dropoffLng = (dropoff?['lng'] as num?)?.toDouble() ?? 44.2;

    return Stack(
      children: [
        // Full screen map (STABLE: Not inside any Obx)
        Obx(() => GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(pickupLat, pickupLng),
            zoom: 14,
          ),
          markers: _buildMarkers(
            pickupLat,
            pickupLng,
            dropoffLat,
            dropoffLng,
            isDriver,
            rideController.lastLocation.value,
          ),
          polylines: _buildPolylines(
            pickupLat,
            pickupLng,
            dropoffLat,
            dropoffLng,
            isDriver,
            rideController.lastLocation.value,
            rideController.routePoints,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onCameraMoveStarted: _onCameraMoveStarted,
          padding: const EdgeInsets.only(bottom: 300),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            if (!isDriver && rideController.lastLocation.value != null) {
              final loc = rideController.lastLocation.value!;
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
              );
            }
          },
        )),

        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
              color: AppTheme.darkGrey,
            ),
          ),
        ),

        // Share button (for rider)
        // Note: Wrap ONLY this button in Obx for status change
        Obx(() {
          final currentTrip = rideController.activeTrip.value;
          final currentStatus = currentTrip?['status']?.toString() ?? 'unknown';
          
          if (!isDriver && currentStatus != 'completed' && currentStatus != 'cancelled') {
            return Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareTrip(tripId),
                  color: AppTheme.primaryColor,
                  tooltip: 'مشاركة الرحلة',
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // Recenter / Follow Button
        Positioned(
          bottom: 340,
          left: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Follow Toggle Button
              if (!_isFollowing)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.gps_fixed),
                    onPressed: _recenter,
                    color: Colors.white,
                    tooltip: 'تتبع السائق',
                  ),
                ),
              // Manual Zoom to Trip Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () {
                    if (_mapController != null) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(LatLng(pickupLat, pickupLng), 14),
                      );
                    }
                  },
                  color: AppTheme.primaryColor,
                  tooltip: 'موقع الاستلام',
                ),
              ),
            ],
          ),
        ),

        // Bottom sheet with trip info (Professional design)
        DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.25,
          maxChildSize: 0.7,
          builder: (context, scrollController) {
            // GRANULAR Obx: Only the content of the bottom sheet is reactive
            return Obx(() {
              // Get latest data from appropriate controller
              Map<String, dynamic>? currentTrip;
              String status;
              String? driverName;
              String? riderName;
              double? acceptedPrice;
              
              if (isDriver) {
                final driverController = Get.find<DriverController>();
                currentTrip = (driverController.activeTrip.value?['id']?.toString() == tripId)
                    ? driverController.activeTrip.value
                    : trip;
              } else {
                currentTrip = (rideController.activeTrip.value?['id']?.toString() == tripId)
                    ? rideController.activeTrip.value
                    : trip;
              }
              
              status = currentTrip?['status']?.toString() ?? 'unknown';
              driverName = currentTrip?['driver']?['name']?.toString();
              riderName = currentTrip?['rider']?['name']?.toString();
              acceptedPrice = (currentTrip?['accepted_price'] as num?)?.toDouble();

              return Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        children: [
                          _buildStatusCard(
                            context,
                            status: status,
                            driverName: driverName,
                            riderName: riderName,
                            isDriver: isDriver,
                            price: acceptedPrice,
                          ),
                          const SizedBox(height: 8),
                          _buildTripTimeline(context, status),
                          const SizedBox(height: 8),
                          _buildActionButtons(
                            context,
                            status: status,
                            isDriver: isDriver,
                            tripId: tripId,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            });
          },
        ),
      ],
    );
  }

  Set<Marker> _buildMarkers(
    double pickupLat,
    double pickupLng,
    double dropoffLat,
    double dropoffLng,
    bool isDriver,
    DriverLocation? driverLoc,
  ) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickupLat, pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'نقطة الاستلام'),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(dropoffLat, dropoffLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'نقطة الوصول'),
      ),
    };

    // Add driver marker for rider view (reactive to location updates)
    if (!isDriver) {
      if (driverLoc != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: LatLng(driverLoc.lat, driverLoc.lng),
            icon: _motorcycleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            anchor: const Offset(0.5, 0.5), // Center the icon
            infoWindow: const InfoWindow(title: 'السائق'),
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(
    double pickupLat,
    double pickupLng,
    double dropoffLat,
    double dropoffLng,
    bool isDriver,
    DriverLocation? driverLoc,
    List<LatLng> routePoints,
  ) {
    final polylines = <Polyline>{};
    
    // Route from pickup to dropoff (dashed line if no directions, solid if directions exist)
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints.isNotEmpty 
            ? routePoints 
            : [
                LatLng(pickupLat, pickupLng),
                LatLng(dropoffLat, dropoffLng),
              ],
        color: AppTheme.primaryColor,
        width: 5,
        patterns: routePoints.isNotEmpty ? [] : [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
    
    // Line from rider to driver (for rider view only)
    if (!isDriver) {
      if (driverLoc != null) {
        // Get rider's current location (use pickup location as rider location)
        polylines.add(
          Polyline(
            polylineId: const PolylineId('rider_to_driver'),
            points: [
              LatLng(pickupLat, pickupLng), // Rider location (pickup point)
              LatLng(driverLoc.lat, driverLoc.lng), // Driver location
            ],
            color: Colors.blue,
            width: 4,
            patterns: [PatternItem.dash(10), PatternItem.gap(5)],
          ),
        );
      }
    }
    
    return polylines;
  }

  Widget _buildNoTripState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bike_outlined,
                size: 64,
                color: AppTheme.lightGrey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد رحلة نشطة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ابدأ رحلة جديدة من الصفحة الرئيسية',
              style: TextStyle(color: AppTheme.lightGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          const Text(
            'جاري تحميل بيانات الرحلة...',
            style: TextStyle(color: AppTheme.mediumGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String status,
    String? driverName,
    String? riderName,
    required bool isDriver,
    double? price,
  }) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusInfo.color,
            statusInfo.color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: statusInfo.color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusInfo.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        statusInfo.text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (price != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${price.toStringAsFixed(0)} ريال',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (isDriver && riderName != null)
                  Text(
                    'الراكب: $riderName',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (!isDriver && driverName != null)
                  Text(
                    'السائق: $driverName',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripTimeline(BuildContext context, String status) {
    final steps = [
      _TimelineStep(
        title: 'طلب الرحلة',
        subtitle: 'تم إنشاء طلب الرحلة',
        isCompleted: true,
        isActive: status == 'bidding',
      ),
      _TimelineStep(
        title: 'تم التعيين',
        subtitle: 'السائق في الطريق',
        isCompleted: ['assigned', 'in_progress', 'completed'].contains(status),
        isActive: status == 'assigned',
      ),
      _TimelineStep(
        title: 'قيد التنفيذ',
        subtitle: 'الرحلة جارية',
        isCompleted: ['in_progress', 'completed'].contains(status),
        isActive: status == 'in_progress',
      ),
      _TimelineStep(
        title: 'مكتملة',
        subtitle: 'تم الوصول بسلامة',
        isCompleted: status == 'completed',
        isActive: status == 'completed',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceGrey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.isCompleted
                              ? AppTheme.primaryColor
                              : (step.isActive
                                  ? AppTheme.primaryLight
                                  : AppTheme.surfaceGrey),
                          border: Border.all(
                            color: step.isCompleted || step.isActive
                                ? AppTheme.primaryColor
                                : AppTheme.lightGrey,
                            width: 2,
                          ),
                        ),
                        child: step.isCompleted
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: step.isCompleted || step.isActive
                              ? AppTheme.darkGrey
                              : AppTheme.lightGrey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 2,
                      color: step.isCompleted
                          ? AppTheme.primaryColor
                          : AppTheme.surfaceGrey,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on,
              color: AppTheme.success,
              size: 14,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${price.toStringAsFixed(0)} ريال',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context, {
    required String status,
    required bool isDriver,
    required String tripId,
  }) {
    if (status == 'completed' || status == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Start Trip button (for driver when assigned)
        if (isDriver && status == 'assigned')
          Obx(() {
            final driverController = Get.find<DriverController>();
            final isLoading = driverController.isStartingTrip.value;
            
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () {
                  driverController.startTrip(tripId);
                },
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow, size: 20), // Smaller icon
                label: Text(
                  isLoading ? 'جاري البدء...' : 'بدء الرحلة',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), // Smaller font
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
                ),
              ),
            );
          }),

        // Complete Trip button (for driver when in_progress)
        if (isDriver && status == 'in_progress')
          Obx(() {
            final driverController = Get.find<DriverController>();
            final isLoading = driverController.isCompletingTrip.value;
            
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () {
                  driverController.completeTrip(tripId);
                },
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle, size: 20), // Smaller icon
                label: Text(
                  isLoading ? 'جاري الإكمال...' : 'إكمال الرحلة',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), // Smaller font
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: AppTheme.success.withOpacity(0.6),
                ),
              ),
            );
          }),

        // Cancel button
        if (status != 'in_progress') ...[
          const SizedBox(height: 12),
          Obx(() {
            final isLoading = isDriver
                ? Get.find<DriverController>().isCancellingTrip.value
                : Get.find<RideController>().isCancellingTrip.value;
            
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : () => _showCancelDialog(context, tripId, isDriver),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.error),
                        ),
                      )
                    : const Icon(Icons.cancel_outlined, size: 18), // Smaller icon
                label: Text(
                  isLoading ? 'جاري الإلغاء...' : 'إلغاء الرحلة',
                  style: const TextStyle(fontSize: 14), // Smaller font
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: BorderSide(
                    color: isLoading ? AppTheme.error.withOpacity(0.5) : AppTheme.error,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _shareTrip(String tripId) {
    final shareUrl = '${AppConfig.apiBaseUrl.replaceAll('/api', '')}/share/$tripId';
    Share.share(
      'تتبع رحلتي على مشوار: $shareUrl',
      subject: 'تتبع رحلتي',
    );
  }

  void _showCancelDialog(BuildContext context, String tripId, bool isDriver) {
    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('إلغاء الرحلة'),
          content: const Text('هل أنت متأكد من إلغاء الرحلة؟'),
          actions: [
            Obx(() {
              final isLoading = isDriver
                  ? Get.find<DriverController>().isCancellingTrip.value
                  : Get.find<RideController>().isCancellingTrip.value;
              
              return TextButton(
                onPressed: isLoading ? null : () => Get.back(),
                child: const Text('لا'),
              );
            }),
            Obx(() {
              final isLoading = isDriver
                  ? Get.find<DriverController>().isCancellingTrip.value
                  : Get.find<RideController>().isCancellingTrip.value;
              
              return ElevatedButton(
                onPressed: isLoading ? null : () {
                  Get.back();
                  if (isDriver) {
                    final driverController = Get.find<DriverController>();
                    driverController.cancelTrip(tripId);
                  } else {
                    final rideController = Get.find<RideController>();
                    rideController.cancelTrip();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.error.withOpacity(0.6),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('نعم، إلغاء'),
              );
            }),
          ],
        ),
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'bidding':
        return _StatusInfo(
          text: 'قيد المزايدة',
          icon: Icons.gavel,
          color: Colors.orange,
        );
      case 'assigned':
        return _StatusInfo(
          text: 'السائق في الطريق',
          icon: Icons.directions_bike,
          color: AppTheme.info,
        );
      case 'in_progress':
        return _StatusInfo(
          text: 'الرحلة جارية',
          icon: Icons.navigation,
          color: AppTheme.primaryColor,
        );
      case 'completed':
        return _StatusInfo(
          text: 'مكتملة',
          icon: Icons.check_circle,
          color: AppTheme.success,
        );
      case 'cancelled':
        return _StatusInfo(
          text: 'ملغاة',
          icon: Icons.cancel,
          color: AppTheme.error,
        );
      default:
        return _StatusInfo(
          text: 'غير معروف',
          icon: Icons.help_outline,
          color: AppTheme.lightGrey,
        );
    }
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;

  _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isActive,
  });
}

class _StatusInfo {
  final String text;
  final IconData icon;
  final Color color;

  _StatusInfo({
    required this.text,
    required this.icon,
    required this.color,
  });
}
