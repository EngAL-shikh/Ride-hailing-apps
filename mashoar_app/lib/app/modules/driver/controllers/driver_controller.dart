import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/network/driver_api.dart';
import '../../../core/network/auth_api.dart';
import '../../../core/network/trip_api.dart';
import '../../../core/storage/auth_store.dart';
import '../../../core/firebase/realtime_tracking_service.dart';
import '../../../core/firebase/realtime_trips_service.dart';
import '../../../routes/app_pages.dart';

class DriverController extends GetxController {
  final DriverApi _driverApi;
  final AuthApi _authApi;
  final TripApi _tripApi;
  final RealtimeTrackingService _tracking;
  final RealtimeTripsService _realtimeTrips;

  DriverController(
    this._driverApi,
    this._authApi,
    this._tripApi,
    this._tracking,
    this._realtimeTrips,
  );

  final isOnline = false.obs;
  final isSendingPulse = false.obs;
  final currentLat = 15.3694.obs;
  final currentLng = 44.1910.obs;
  final hasLocationPermission = false.obs;
  final errorMessage = RxnString();

  // Available trips
  final availableTrips = <Map<String, dynamic>>[].obs;
  final isLoadingTrips = false.obs;

  // Loading states for actions
  final isPlacingBid = false.obs;
  final isStartingTrip = false.obs;
  final isCompletingTrip = false.obs;
  final isCancellingTrip = false.obs;

  // Active trip (for tracking)
  final activeTrip = Rxn<Map<String, dynamic>>();
  final activeTripId = ''.obs;

  // Driver profile data (including verification status)
  final profileData = <String, dynamic>{}.obs;
  String get verificationStatus =>
      profileData['profile']?['verification_status']?.toString() ??
      'unverified';

  // Stream subscriptions for location updates and trips
  StreamSubscription<Position>? _locationStreamSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _availableTripsSubscription;
  StreamSubscription<Map<String, dynamic>?>? _activeTripStatusSubscription;

  // Track if trip accepted bottom sheet has been shown for current trip
  String? _tripAcceptedBottomSheetShownForTripId;

  @override
  void onInit() {
    super.onInit();
    // Restore driver online status from storage
    isOnline.value = AuthStore.driverOnline;
    _requestLocationPermissions();
    _startLocationStream();
    // Always check for active trip (even if offline) - load driver's assigned trips
    _loadDriverTrips();
    // Load driver profile
    fetchProfile();
    // Load available trips if online
    if (isOnline.value) {
      loadAvailableTrips();
    }

    // Listen to online status changes to load trips automatically
    ever(isOnline, (bool online) {
      Get.log(
        '[DriverController] ========== Online status changed: $online ==========',
      );
      if (online) {
        Get.log(
          '[DriverController] Driver went online, loading available trips...',
        );
        loadAvailableTrips();
        // Hybrid: Start listening to RTDB for real-time available trips (Live Flow)
        _startListeningToAvailableTrips();
      } else {
        Get.log(
          '[DriverController] Driver went offline, clearing available trips...',
        );
        availableTrips.clear();
        _stopListeningToAvailableTrips();
      }
    });

    // Hybrid: Start RTDB streams if online (with delay to ensure binding is complete)
    if (isOnline.value) {
      Get.log(
        '[DriverController] Driver is already online on init, starting RTDB stream...',
      );
      // Small delay to ensure all bindings are complete
      Future.delayed(const Duration(milliseconds: 500), () {
        if (isOnline.value) {
          _startListeningToAvailableTrips();
        }
      });
    }
  }

  // Removed _startPeriodicTripCheck() - using FCM notifications only (as per plan)

  /// Load driver's assigned trips to check for active trip
  Future<void> _loadDriverTrips() async {
    try {
      // Use driver-specific endpoint to get trips assigned to this driver
      final trips = await _tripApi.getMyDriverTrips();
      _checkActiveTrip(trips);

      // CRITICAL: If we found an active trip, ensure we're listening to RTDB updates
      if (activeTripId.value.isNotEmpty) {
        Get.log(
          '[DriverController] Active trip found after refresh, ensuring RTDB stream is active: ${activeTripId.value}',
        );
        _startListeningToActiveTripStatus(activeTripId.value);
      }
    } catch (e) {
      Get.log(
        '[DriverController] Error loading driver trips: $e',
        isError: true,
      );
    }
  }

  /// Public method to refresh driver trips (for FCM service)
  Future<void> refreshDriverTrips() => _loadDriverTrips();

  /// Check for active trip (assigned or in_progress) and start tracking
  void _checkActiveTrip(List<Map<String, dynamic>> trips) {
    Get.log(
      '[DriverController] Checking ${trips.length} trips for active trip',
    );

    // Log all trip statuses for debugging
    for (var trip in trips) {
      Get.log(
        '[DriverController] Trip ${trip['id']}: status=${trip['status']}, driver_id=${trip['driver_id']}',
      );
    }

    final active = trips.firstWhereOrNull((trip) {
      final status = trip['status']?.toString();
      final isActive = ['assigned', 'in_progress'].contains(status);
      Get.log(
        '[DriverController] Trip ${trip['id']}: status=$status, isActive=$isActive',
      );
      return isActive;
    });

    if (active != null) {
      Get.log(
        '[DriverController] Active trip found: ${active['id']}, status=${active['status']}',
      );
      final newTripId = active['id']?.toString() ?? '';

      if (activeTripId.value != newTripId) {
        activeTrip.value = active;
        activeTripId.value = newTripId;

        // Hybrid: Start listening to RTDB for real-time trip status updates (Live Flow)
        _startListeningToActiveTripStatus(newTripId);

        _startFirebaseTracking();
      } else {
        // Update active trip data but keep listening (stream is already active)
        activeTrip.value = active;
        // Don't restart stream if already listening to the same trip
        // The stream will automatically update activeTrip.value from RTDB
      }
    } else {
      Get.log('[DriverController] No active trip found');
      activeTrip.value = null;
      activeTripId.value = '';
      _stopListeningToActiveTripStatus();
    }
  }

  Future<void> loadAvailableTrips() async {
    if (!isOnline.value) {
      Get.log('[DriverController] Cannot load trips: driver is offline');
      availableTrips.clear();
      return;
    }

    try {
      isLoadingTrips.value = true;
      Get.log('[DriverController] Loading available trips...');
      final trips = await _tripApi.getAvailableTrips();
      Get.log('[DriverController] Received ${trips.length} trips from API');
      availableTrips.assignAll(trips);
      Get.log(
        '[DriverController] Updated availableTrips: ${availableTrips.length} trips',
      );
      // Also check driver's assigned trips (may have been assigned while viewing available trips)
      _loadDriverTrips();
    } catch (e) {
      Get.log('[DriverController] Error loading trips: $e', isError: true);
    } finally {
      isLoadingTrips.value = false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      final data = await _driverApi.getMe();
      profileData.value = data;
    } catch (e) {
      Get.log('[DriverController] Error fetching profile: $e', isError: true);
    }
  }

  Future<void> placeBid(String tripId, double amount) async {
    if (isPlacingBid.value) return; // Prevent multiple clicks

    try {
      isPlacingBid.value = true;
      await _tripApi.placeBid(tripId: tripId, amount: amount);

      // CRITICAL: Start listening to this trip for status updates (in case bid is accepted)
      // This ensures the driver sees the "bid accepted" update immediately
      Get.log(
        '[DriverController] Starting to listen to trip $tripId for bid acceptance...',
      );
      _startListeningToActiveTripStatus(tripId);

      // Refresh available trips (RTDB will update automatically, but this ensures consistency)
      await loadAvailableTrips();
      Get.snackbar('نجح', 'تم وضع المزايدة بنجاح');
    } catch (e) {
      Get.log('[DriverController] Error placing bid: $e', isError: true);
      Get.snackbar('خطأ', 'فشل في وضع المزايدة');
    } finally {
      isPlacingBid.value = false;
    }
  }

  Future<void> _requestLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      hasLocationPermission.value =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (!hasLocationPermission.value) {
        errorMessage.value = 'يجب السماح بالوصول للموقع';
        return;
      }

      // Check if location services are enabled
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
        errorMessage.value = 'يجب تفعيل خدمة المواقع';
        return;
      }
    } catch (e) {
      Get.log('[DriverController] Permission error: $e', isError: true);
      errorMessage.value = 'خطأ في صلاحيات الموقع';
    }
  }

  void _startLocationStream() {
    if (!hasLocationPermission.value) {
      Get.log('[DriverController] Cannot start location stream: no permission');
      return;
    }

    // Cancel previous stream if exists
    _locationStreamSubscription?.cancel();

    Get.log('[DriverController] Starting location stream...');
    _locationStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
        ).listen(
          (position) {
            currentLat.value = position.latitude;
            currentLng.value = position.longitude;

            Get.log(
              '[DriverController] Location updated: ${position.latitude}, ${position.longitude}, activeTripId: ${activeTripId.value}',
            );

            // Auto-send pulse if online
            if (isOnline.value) {
              sendPulse();
            }

            // Send location to Firebase if active trip (as per plan)
            if (activeTripId.value.isNotEmpty) {
              _sendLocationToFirebase(position);
            }
          },
          onError: (error) {
            Get.log(
              '[DriverController] Location stream error: $error',
              isError: true,
            );
          },
        );
  }

  Future<void> toggleOnlineStatus() async {
    if (!hasLocationPermission.value) {
      await _requestLocationPermissions();
      if (!hasLocationPermission.value) return;
    }

    final newStatus = !isOnline.value;
    Get.log(
      '[DriverController] ========== Toggling online status: $newStatus ==========',
    );

    isOnline.value = newStatus;
    // Save online status to storage
    await AuthStore.setDriverOnline(isOnline.value);

    if (isOnline.value) {
      Get.log(
        '[DriverController] Driver going online, sending pulse and loading trips...',
      );
      // Send initial pulse when going online
      await sendPulse();
      // Load available trips when going online (initial load)
      loadAvailableTrips();
      // Note: _startListeningToAvailableTrips() will be called automatically by ever(isOnline) listener
    } else {
      Get.log('[DriverController] Driver going offline, clearing trips...');
      // Clear available trips when going offline (but keep active trip)
      availableTrips.clear();
    }
    // Always check for active trip
    await _loadDriverTrips();
  }

  Future<void> sendPulse() async {
    if (!isOnline.value) return;

    try {
      isSendingPulse.value = true;
      errorMessage.value = null;

      await _driverApi.pulse(
        lat: currentLat.value,
        lng: currentLng.value,
        isOnline: isOnline.value,
      );

      Get.log(
        '[DriverController] Pulse sent: ${currentLat.value}, ${currentLng.value}',
      );
    } catch (e) {
      Get.log('[DriverController] Pulse error: $e', isError: true);
      errorMessage.value = 'خطأ في إرسال الموقع';
    } finally {
      isSendingPulse.value = false;
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      if (!hasLocationPermission.value) {
        await _requestLocationPermissions();
        if (!hasLocationPermission.value) return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentLat.value = position.latitude;
      currentLng.value = position.longitude;

      if (isOnline.value) {
        await sendPulse();
      }

      Get.snackbar('نجح', 'تم تحديث الموقع');
    } catch (e) {
      Get.log('[DriverController] Location error: $e', isError: true);
      Get.snackbar('خطأ', 'فشل في الحصول على الموقع');
    }
  }

  /// Start Firebase tracking for active trip
  void _startFirebaseTracking() {
    if (activeTripId.value.isEmpty) {
      Get.log(
        '[DriverController] Cannot start Firebase tracking: activeTripId is empty',
      );
      return;
    }

    Get.log(
      '[DriverController] Starting Firebase tracking for trip ${activeTripId.value}',
    );

    // CRITICAL: Send current location immediately when tracking starts
    // This ensures the rider sees the driver's location right away
    if (currentLat.value != 0.0 && currentLng.value != 0.0) {
      Get.log(
        '[DriverController] Sending initial location to Firebase: ${currentLat.value}, ${currentLng.value}',
      );
      Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .then((position) {
            _sendLocationToFirebase(position);
          })
          .catchError((error) {
            Get.log(
              '[DriverController] Error getting current position for Firebase: $error',
              isError: true,
            );
          });
    } else {
      Get.log(
        '[DriverController] Current location not available yet, will send when location stream provides it',
      );
    }

    // Ensure location stream is running (it should be, but double-check)
    if (_locationStreamSubscription == null ||
        _locationStreamSubscription!.isPaused) {
      Get.log('[DriverController] Location stream not active, restarting...');
      _startLocationStream();
    }
  }

  /// Send driver location to Firebase during active trip (as per plan)
  Future<void> _sendLocationToFirebase(Position position) async {
    if (activeTripId.value.isEmpty) {
      Get.log('[DriverController] Cannot send location: activeTripId is empty');
      return;
    }

    try {
      Get.log(
        '[DriverController] Sending location to Firebase RTDB: trip=${activeTripId.value}, lat=${position.latitude}, lng=${position.longitude}',
      );
      await _tracking.updateDriverLocation(
        tripId: activeTripId.value,
        lat: position.latitude,
        lng: position.longitude,
        heading: position.heading,
        speed: position.speed,
      );
      Get.log('[DriverController] Location sent successfully to Firebase RTDB');
    } catch (e, stackTrace) {
      Get.log('[DriverController] Firebase tracking error: $e', isError: true);
      Get.log('[DriverController] Stack trace: $stackTrace', isError: true);
    }
  }

  /// Show bottom sheet when trip is accepted (like Uber/Careem)
  void showTripAcceptedBottomSheet(String tripId) async {
    Get.log(
      '[DriverController] showTripAcceptedBottomSheet called for trip: $tripId',
    );

    // CRITICAL: Prevent duplicate calls - if already shown for this trip, skip
    if (_tripAcceptedBottomSheetShownForTripId == tripId &&
        (Get.isBottomSheetOpen ?? false)) {
      Get.log(
        '[DriverController] Bottom sheet already shown for trip $tripId, skipping...',
      );
      return;
    }

    // CRITICAL: Close ALL existing bottom sheets (may have multiple stacked)
    while (Get.isBottomSheetOpen ?? false) {
      Get.log('[DriverController] Closing existing bottom sheet...');
      Get.back();
      // Small delay to ensure bottom sheet closes
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Mark as shown BEFORE loading to prevent duplicate calls during load
    _tripAcceptedBottomSheetShownForTripId = tripId;

    // Check if trip is already in activeTrip (from RTDB stream)
    var trip = activeTrip.value;
    Get.log(
      '[DriverController] activeTrip current: ${trip != null ? trip['id'] : 'null'}, status: ${trip != null ? trip['status'] : 'N/A'}',
    );

    // If not found in activeTrip, try to load it from API (but don't trigger _checkActiveTrip to avoid loop)
    if (trip == null || trip['id']?.toString() != tripId) {
      Get.log('[DriverController] Trip not in activeTrip, loading from API...');
      try {
        final allTrips = await _tripApi.getMyDriverTrips();
        Get.log('[DriverController] Found ${allTrips.length} total trips');

        trip = allTrips.firstWhereOrNull((t) => t['id']?.toString() == tripId);

        Get.log(
          '[DriverController] Found trip in API: ${trip != null}, status: ${trip != null ? trip['status'] : 'N/A'}',
        );

        // If found and status is assigned/in_progress, set as active (but don't call _checkActiveTrip)
        if (trip != null &&
            ['assigned', 'in_progress'].contains(trip['status']?.toString())) {
          Get.log('[DriverController] Setting trip as active: ${trip['id']}');
          activeTrip.value = trip;
          activeTripId.value = tripId;
          _startFirebaseTracking();
          // Start listening to trip status if not already listening
          if (_activeTripStatusSubscription == null ||
              activeTripId.value != tripId) {
            _startListeningToActiveTripStatus(tripId);
          }
        } else if (trip != null) {
          Get.log(
            '[DriverController] Trip found but status is ${trip['status']}, not setting as active',
          );
        }
      } catch (e) {
        Get.log(
          '[DriverController] Error loading trips for bottom sheet: $e',
          isError: true,
        );
      }
    }

    if (trip == null) {
      Get.log('[DriverController] Trip not found for bottom sheet: $tripId');
      // Show error message to user
      Get.snackbar(
        'خطأ',
        'لم يتم العثور على الرحلة. يرجى تحديث الصفحة.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Wait a bit more to ensure previous bottom sheets are closed
    await Future.delayed(const Duration(milliseconds: 200));

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(Get.context!).size.height *
              0.85, // Increased to 85%
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
          children: [
            // Drag handle (at top)
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تم قبول مزايدتك!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'رحلة #${trip['id']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Trip Details Section
                    Text(
                      'تفاصيل الرحلة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: _buildTripDetailRow(
                        Icons.monetization_on,
                        'السعر المقبول',
                        '${(trip['accepted_price'] ?? trip['offered_price'] ?? 0).toStringAsFixed(0)} ريال',
                        Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rider Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: _buildTripDetailRow(
                        Icons.person,
                        'الراكب',
                        trip['rider']?['name'] ?? 'غير معروف',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pickup Location Card
                    if (trip['pickup_lat'] != null &&
                        trip['pickup_lng'] != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: _buildTripDetailRow(
                          Icons.location_on,
                          'موقع الاستلام',
                          '${trip['pickup_lat']?.toStringAsFixed(4)}, ${trip['pickup_lng']?.toStringAsFixed(4)}',
                          Colors.orange,
                        ),
                      ),
                    if (trip['pickup_lat'] != null &&
                        trip['pickup_lng'] != null)
                      const SizedBox(height: 12),

                    // Dropoff Location Card
                    if (trip['dropoff_lat'] != null &&
                        trip['dropoff_lng'] != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: _buildTripDetailRow(
                          Icons.place,
                          'موقع الوصول',
                          '${trip['dropoff_lat']?.toStringAsFixed(4)}, ${trip['dropoff_lng']?.toStringAsFixed(4)}',
                          Colors.red,
                        ),
                      ),
                    if (trip['dropoff_lat'] != null &&
                        trip['dropoff_lng'] != null)
                      const SizedBox(height: 12),

                    // Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: _buildTripDetailRow(
                        Icons.info_outline,
                        'حالة الرحلة',
                        trip['status'] == 'assigned'
                            ? 'تم التعيين'
                            : trip['status'] == 'in_progress'
                            ? 'قيد التنفيذ'
                            : trip['status'] ?? 'غير معروف',
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.back(); // Close bottom sheet
                        // Navigate to trip tracking
                        Get.toNamed(
                          '/trip-tracking',
                          arguments: {'trip': trip},
                        );
                      },
                      icon: const Icon(
                        Icons.directions_bike,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: const Text(
                        'عرض تفاصيل الرحلة',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text(
                        'إغلاق',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
    );
  }

  Widget _buildTripDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Start the trip (driver picked up the rider)
  Future<void> startTrip(String tripId) async {
    if (isStartingTrip.value) return; // Prevent multiple clicks

    try {
      isStartingTrip.value = true;
      await _tripApi.startTrip(tripId: tripId);
      await _loadDriverTrips(); // Refresh trips
      Get.snackbar('نجح', 'تم بدء الرحلة');
    } catch (e) {
      Get.log('[DriverController] Error starting trip: $e', isError: true);
      Get.snackbar('خطأ', 'فشل في بدء الرحلة');
    } finally {
      isStartingTrip.value = false;
    }
  }

  /// Complete the trip (driver dropped off the rider)
  Future<void> completeTrip(String tripId) async {
    if (isCompletingTrip.value) return; // Prevent multiple clicks

    try {
      isCompletingTrip.value = true;
      await _tripApi.completeTrip(tripId: tripId);

      // CRITICAL: Close only trip-related bottom sheets (not available trips bottom sheet)
      // Close trip tracking view if open
      if (Get.currentRoute == '/trip-tracking') {
        Get.log('[DriverController] Closing trip tracking view...');
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Close trip accepted bottom sheet if open (but keep available trips bottom sheet)
      // We check if there's a bottom sheet that's NOT the available trips one
      // Available trips bottom sheet is part of the dashboard view, not a separate bottom sheet
      // So we only close Get.bottomSheet() calls, not DraggableScrollableSheet widgets
      int closedCount = 0;
      while (Get.isBottomSheetOpen ?? false && closedCount < 2) {
        Get.log('[DriverController] Closing trip-related bottom sheet...');
        Get.back();
        closedCount++;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Refresh trips
      await _loadDriverTrips();

      // Clear active trip (trip is now completed)
      activeTrip.value = null;
      activeTripId.value = '';

      // Reload available trips if online (this will show available trips bottom sheet if there are trips)
      if (isOnline.value) {
        await loadAvailableTrips();
      }

      Get.snackbar('نجح', 'تم إكمال الرحلة بنجاح');

      // Note: We don't navigate back here because we want to keep the driver on dashboard
      // The available trips bottom sheet will automatically show if there are trips
    } catch (e) {
      Get.log('[DriverController] Error completing trip: $e', isError: true);
      Get.snackbar('خطأ', 'فشل في إكمال الرحلة');
    } finally {
      isCompletingTrip.value = false;
    }
  }

  /// Cancel the trip
  Future<void> cancelTrip(String tripId) async {
    if (isCancellingTrip.value) return; // Prevent multiple clicks

    try {
      isCancellingTrip.value = true;
      await _tripApi.cancelTrip(tripId: tripId);

      // Close ALL bottom sheets
      while (Get.isBottomSheetOpen ?? false) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _loadDriverTrips(); // Refresh trips

      // Clear active trip
      activeTrip.value = null;
      activeTripId.value = '';

      // Reload available trips if online
      if (isOnline.value) {
        await loadAvailableTrips();
      }

      Get.snackbar('تم', 'تم إلغاء الرحلة');

      // Navigate back if on tracking view
      if (Get.currentRoute == '/trip-tracking') {
        Get.back();
      }
    } catch (e) {
      Get.log('[DriverController] Error cancelling trip: $e', isError: true);
      Get.snackbar('خطأ', 'فشل في إلغاء الرحلة');
    } finally {
      isCancellingTrip.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (e) {
      Get.log('[DriverController] Logout error: $e', isError: true);
    } finally {
      await AuthStore.clear();
      Get.offAllNamed(Routes.login);
    }
  }

  /// Start listening to available trips via Firebase RTDB (Hybrid: Live Flow)
  void _startListeningToAvailableTrips() {
    // Cancel previous subscription
    _availableTripsSubscription?.cancel();
    _availableTripsSubscription = null;

    if (!isOnline.value) {
      Get.log(
        '[DriverController] Cannot listen to available trips: driver is offline',
      );
      return;
    }

    Get.log(
      '[DriverController] ========== Starting RTDB stream for available trips ==========',
    );
    Get.log('[DriverController] Driver is online: ${isOnline.value}');
    Get.log(
      '[DriverController] RealtimeTripsService instance: ${_realtimeTrips.hashCode}',
    );

    try {
      _availableTripsSubscription = _realtimeTrips.streamAvailableTrips().listen(
        (trips) {
          Get.log(
            '[DriverController] ========== RTDB UPDATE: Received ${trips.length} available trips ==========',
          );
          if (trips.isNotEmpty) {
            Get.log(
              '[DriverController] Trip IDs: ${trips.map((t) => t['id']?.toString() ?? 'null').join(', ')}',
            );
            for (var trip in trips) {
              Get.log(
                '[DriverController] Trip ${trip['id']}: status=${trip['status']}, rider_id=${trip['rider_id']}',
              );
            }
          }

          // Update the list (this will trigger Obx rebuilds)
          availableTrips.assignAll(trips);

          Get.log(
            '[DriverController] ✓ Updated availableTrips observable: ${availableTrips.length} trips',
          );
          Get.log(
            '[DriverController] availableTrips list: ${availableTrips.map((t) => t['id']).join(', ')}',
          );

          // Force UI update using GetX reactive system
          // Obx will automatically rebuild when availableTrips changes
        },
        onError: (error, stackTrace) {
          Get.log(
            '[DriverController] ========== RTDB STREAM ERROR ==========',
            isError: true,
          );
          Get.log('[DriverController] Error: $error', isError: true);
          Get.log(
            '[DriverController] Error type: ${error.runtimeType}',
            isError: true,
          );
          Get.log('[DriverController] Stack trace: $stackTrace', isError: true);

          // Try to restart the stream after a delay
          Future.delayed(const Duration(seconds: 3), () {
            if (isOnline.value && _availableTripsSubscription == null) {
              Get.log(
                '[DriverController] Attempting to restart RTDB stream after error...',
              );
              _startListeningToAvailableTrips();
            }
          });
        },
        onDone: () {
          Get.log(
            '[DriverController] ========== RTDB stream closed (onDone) ==========',
          );
          _availableTripsSubscription = null;

          // Try to restart if still online
          if (isOnline.value) {
            Get.log(
              '[DriverController] Stream closed but driver is still online, restarting...',
            );
            Future.delayed(const Duration(seconds: 1), () {
              if (isOnline.value) {
                _startListeningToAvailableTrips();
              }
            });
          }
        },
        cancelOnError: false, // Don't cancel on error, let onError handle it
      );

      Get.log(
        '[DriverController] ✓ RTDB stream subscription created successfully',
      );
      Get.log(
        '[DriverController] Subscription active: ${_availableTripsSubscription != null}',
      );
    } catch (e, stackTrace) {
      Get.log(
        '[DriverController] ========== EXCEPTION creating RTDB stream ==========',
        isError: true,
      );
      Get.log('[DriverController] Exception: $e', isError: true);
      Get.log('[DriverController] Stack trace: $stackTrace', isError: true);
    }
  }

  /// Stop listening to available trips
  void _stopListeningToAvailableTrips() {
    _availableTripsSubscription?.cancel();
    _availableTripsSubscription = null;
  }

  /// Start listening to active trip status via Firebase RTDB (Hybrid: Live Flow)
  void _startListeningToActiveTripStatus(String tripIdStr) {
    // Don't start a new stream if already listening to the same trip
    // (This prevents infinite loops when RTDB updates trigger _checkActiveTrip)
    if (_activeTripStatusSubscription != null &&
        activeTripId.value == tripIdStr) {
      Get.log(
        '[DriverController] Already listening to trip $tripIdStr, skipping to prevent loop...',
      );
      return;
    }

    // Cancel previous subscription (if listening to a different trip or restarting)
    if (_activeTripStatusSubscription != null) {
      Get.log(
        '[DriverController] Cancelling previous stream for trip ${activeTripId.value}',
      );
      _activeTripStatusSubscription?.cancel();
    }

    Get.log(
      '[DriverController] Starting to listen to active trip status: $tripIdStr',
    );

    _activeTripStatusSubscription = _realtimeTrips
        .streamTrip(tripIdStr)
        .listen(
          (trip) {
            if (trip != null) {
              Get.log(
                '[DriverController] Active trip status updated via RTDB: ${trip['status']}',
              );

              // Update active trip with latest data from RTDB
              activeTrip.value = trip;

              // Update activeTripId if changed
              final newTripId = trip['id']?.toString() ?? '';
              if (newTripId.isNotEmpty && activeTripId.value != newTripId) {
                activeTripId.value = newTripId;
                // Reset bottom sheet flag when trip ID changes
                _tripAcceptedBottomSheetShownForTripId = null;
              }

              // Handle status changes
              final status = trip['status']?.toString() ?? '';

              if (status == 'assigned' || status == 'in_progress') {
                // Ensure Firebase tracking is active
                if (activeTripId.value.isNotEmpty) {
                  _startFirebaseTracking();
                }
                // Show trip accepted bottom sheet if status changed to assigned
                // CRITICAL: Only show once per trip ID, and only if not already shown
                if (status == 'assigned' &&
                    activeTripId.value == tripIdStr &&
                    _tripAcceptedBottomSheetShownForTripId != tripIdStr &&
                    !(Get.isBottomSheetOpen ?? false)) {
                  Get.log(
                    '[DriverController] Trip accepted! Showing bottom sheet for trip: $tripIdStr',
                  );
                  // Mark as shown BEFORE showing to prevent duplicate calls
                  _tripAcceptedBottomSheetShownForTripId = tripIdStr;
                  // Small delay to ensure UI is ready
                  Future.delayed(const Duration(milliseconds: 500), () {
                    // Double-check conditions before showing
                    if (activeTripId.value == tripIdStr &&
                        _tripAcceptedBottomSheetShownForTripId == tripIdStr &&
                        !(Get.isBottomSheetOpen ?? false)) {
                      showTripAcceptedBottomSheet(tripIdStr);
                    }
                  });
                }
                // Trigger UI update
                update(['active_trip', 'trip_status']);
              } else if (status == 'completed' || status == 'cancelled') {
                // Stop tracking
                activeTrip.value = null;
                activeTripId.value = '';
                _tripAcceptedBottomSheetShownForTripId = null; // Reset flag
                _stopListeningToActiveTripStatus();

                // Reload available trips if online
                if (isOnline.value) {
                  loadAvailableTrips();
                }
                // Trigger UI update
                update(['active_trip', 'trip_status']);
              } else {
                // Other status changes (e.g., bidding -> assigned)
                update(['active_trip', 'trip_status']);
              }
            }
          },
          onError: (error) {
            Get.log(
              '[DriverController] Error listening to active trip status: $error',
              isError: true,
            );
          },
        );
  }

  /// Stop listening to active trip status
  void _stopListeningToActiveTripStatus() {
    _activeTripStatusSubscription?.cancel();
    _activeTripStatusSubscription = null;
  }

  @override
  void onClose() {
    _locationStreamSubscription?.cancel();
    _stopListeningToAvailableTrips();
    _stopListeningToActiveTripStatus();
    super.onClose();
  }
}
