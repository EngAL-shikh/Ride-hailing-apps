import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/firebase/realtime_tracking_service.dart';
import '../../../core/firebase/realtime_trips_service.dart';
import '../../../core/network/trip_api.dart';
import '../../../core/network/driver_api.dart';
import '../../../core/network/review_api.dart';
import '../../../core/storage/auth_store.dart';
import '../../../core/services/google_maps_service.dart';
import '../views/review_view.dart';


class RideController extends GetxController {
  final RealtimeTrackingService _tracking;
  final RealtimeTripsService _realtimeTrips;
  final TripApi _trips;
  final DriverApi _driverApi;
  final ReviewApi _reviewApi;
  final GoogleMapsService _googleMapsService = Get.find<GoogleMapsService>();

  RideController(
    this._tracking,
    this._realtimeTrips,
    this._trips,
    this._driverApi,
    this._reviewApi,
  );

  final tripId = ''.obs;
  final isDriver = (AuthStore.userType == 'driver').obs;
  
  // Stream subscriptions for Firebase tracking and trips
  StreamSubscription<DriverLocation?>? _locationStreamSubscription;
  StreamSubscription<Map<String, dynamic>?>? _tripStatusSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _tripBidsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _availableTripsSubscription;
  StreamSubscription<Map<String, dynamic>?>? _myActiveTripSubscription; // For rider's active trip updates
  DateTime _lastLocationUpdate = DateTime.now();

  // Rider inputs
  final pickupLat = 15.3694.obs;
  final pickupLng = 44.1910.obs;
  final dropoffLat = 15.4000.obs;
  final dropoffLng = 44.2000.obs;
  final offeredPrice = 10000.0.obs;

  // Location selection mode: 'pickup', 'dropoff', or null (none)
  final selectionMode = RxnString();

  // Address strings for display
  final pickupAddress = 'موقع الاستلام'.obs;
  final dropoffAddress = 'موقع الوصول'.obs;

  // Google Maps controller
  GoogleMapController? mapController;

  // ========== Step-by-Step System for Beginners ==========
  // Current step in the request flow (1 = pickup, 2 = dropoff, 3 = price)
  final currentRequestStep = 1.obs;
  
  // Tutorial state (show on first use)
  final showTutorial = true.obs;
  
  // Track if pickup/dropoff have been selected
  final isPickupSelected = false.obs;
  final isDropoffSelected = false.obs;
  final isPriceSelected = false.obs;
  
  // Track if user is actively selecting on map (for UI state)
  final isSelectingOnMap = false.obs;
  
  // Selected price chip (0 = none, 1 = economy, 2 = standard, 3 = premium)
  final selectedPriceChip = 0.obs;
  // ========================================================

  // Driver inputs
  final bidAmount = 12000.0.obs;
  final acceptBidId = ''.obs;

  // Loading states for actions
  final isRequestingTrip = false.obs;
  final isStartingTrip = false.obs;
  final isCompletingTrip = false.obs;
  final isCancellingTrip = false.obs;

  final bids = <Map<String, dynamic>>[].obs;
  final availableTrips = <Map<String, dynamic>>[].obs; // For drivers
  final myTrips = <Map<String, dynamic>>[].obs; // For riders
  final errorMessage = RxnString();

  final lastLocation = Rxn<DriverLocation>();
  final isStreaming = false.obs;
  final isSending = false.obs;
  final isBusy = false.obs;
  final hasLocationPermission = false.obs;
  final mapError = RxnString(); // Map loading error

  // Nearby drivers (for riders)
  final nearbyDrivers = <Map<String, dynamic>>[].obs;
  final isLoadingDrivers = false.obs;

  // Driver markers cache
  final driverMarkers = <Marker>{}.obs;
  
  // Route polylines
  final routePoints = <LatLng>[].obs;
  bool _isFetchingDirections = false;
  String _lastFetchedRouteKey = ''; // Combination of origin and destination to avoid re-fetching same route

  // Active trip (for showing floating card)
  final activeTrip = Rxn<Map<String, dynamic>>();

  // Review state
  final reviewRating = 0.obs;
  final reviewCommentController = TextEditingController();
  final isSubmittingReview = false.obs;
  final reviewedTripIds =
      <String>{}.obs; // Track which trips have been reviewed

  @override
  void onInit() {
    super.onInit();
    _requestLocationPermissions();

    // Set current location as default pickup location
    _setCurrentLocationAsPickup();

    if (isDriver.value) {
      loadAvailableTrips(); // Initial load via API
      startListeningToAvailableTrips(); // Then listen to RTDB for live updates
    } else {
      loadMyTrips(); // Load rider's trips
      checkActiveTrip(); // Check for active trip
      // Start listening to active trip for real-time bid count updates
      _startListeningToMyActiveTrip();
      // Wait for location to be set, then load drivers
      Future.delayed(const Duration(seconds: 1), () {
        if (pickupLat.value != 0.0 && pickupLng.value != 0.0) {
          loadNearbyDrivers();
        }
      });
      // Periodic refresh every 30 seconds (only if drivers exist)
      // _startPeriodicDriverRefresh(); // DISABLED - only refresh when needed
    }
    if (tripId.value.isNotEmpty) {
      _startListening();
    }
  }

  /// Set current location as default pickup location
  Future<void> _setCurrentLocationAsPickup() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return; // Can't get location
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return; // Location service not enabled
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      pickupLat.value = position.latitude;
      pickupLng.value = position.longitude;
      pickupAddress.value = 'موقعي الحالي';

      Get.log(
        '[RideController] Set current location as pickup: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      Get.log(
        '[RideController] Error setting current location: $e',
        isError: true,
      );
    }
  }

  // Removed _startPeriodicRefresh() - using FCM notifications only (as per plan)

  /// Check for active trip and show floating card
  /// Active trip includes: bidding (waiting for bids), assigned, in_progress
  void checkActiveTrip() {
    Get.log(
      '[RideController] checkActiveTrip: checking ${myTrips.length} trips',
    );

    // Log all trips for debugging
    for (var trip in myTrips) {
      Get.log(
        '[RideController] Trip ${trip['id']}: status=${trip['status']}, driver_id=${trip['driver_id']}',
      );
    }

    // Find active trip (bidding, assigned, in_progress)
    // CRITICAL: Include 'bidding' status so rider can see bids in real-time
    final active = myTrips.firstWhereOrNull((trip) {
      final status = trip['status']?.toString();
      final isActive = ['bidding', 'assigned', 'in_progress'].contains(status);
      Get.log(
        '[RideController] Trip ${trip['id']}: status=$status, isActive=$isActive',
      );
      return isActive;
    });

    if (active != null) {
      Get.log(
        '[RideController] Active trip found: ${active['id']}, status=${active['status']}',
      );
      final newTripId = active['id']?.toString() ?? '';
      
      // Only restart listening if tripId changed
      if (tripId.value != newTripId) {
        Get.log('[RideController] Trip ID changed from ${tripId.value} to $newTripId, restarting listeners');
        
        activeTrip.value = active;
        tripId.value = newTripId;
        
        // Hybrid: Start listening to RTDB for real-time updates (Live Flow)
        // CRITICAL: Listen to bids even if trip is in 'bidding' status
        _startListeningToTripStatus(newTripId);
        _startListeningToTripBids(newTripId);
        
        // Start location tracking if trip is in progress (not for bidding)
        final status = active['status']?.toString() ?? '';
        if (status == 'assigned' || status == 'in_progress') {
          _startListening();
        }
      } else {
        // Same trip ID - just update data, DON'T restart listeners
        Get.log('[RideController] Same trip ID ($newTripId), updating data only (no new listeners)');
        activeTrip.value = active;
        // Listeners are already running, no need to restart them
      }
    } else {
      Get.log('[RideController] No active trip found');
      // Clear active trip if no active trip found (e.g., after cancellation)
      activeTrip.value = null;
      tripId.value = '';
      _stopListening();
      _stopListeningToTripStatus();
      _stopListeningToTripBids();

      // DO NOT check for review here - only show review after trip completion via FCM/RTDB
      // _checkForCompletedTripNeedingReview() should only be called:
      // 1. After receiving FCM notification for trip_completed
      // 2. After driver completes trip (for rider)
    }
  }

  /// Check for completed trip that needs review
  /// This should ONLY be called from FCM notification handler, not on app init
  void checkForCompletedTripNeedingReview() async {
    // Find most recent completed trip that hasn't been reviewed
    final completedTrip = myTrips.firstWhereOrNull((trip) {
      final status = trip['status']?.toString();
      final tripIdStr = trip['id']?.toString() ?? '';
      final isCompleted = status == 'completed';
      final notReviewed = !reviewedTripIds.contains(tripIdStr);
      return isCompleted && notReviewed && trip['driver_id'] != null;
    });

    if (completedTrip != null) {
      final tripIdStr = completedTrip['id']?.toString() ?? '';
      Get.log(
        '[RideController] Found completed trip needing review: $tripIdStr',
      );

      // Mark as reviewed to prevent showing again
      reviewedTripIds.add(tripIdStr);

      // Close any existing bottom sheets
      while (Get.isBottomSheetOpen ?? false) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Get driver name
      final driverName =
          completedTrip['driver']?['name']?.toString() ??
          completedTrip['driver_name']?.toString() ??
          'السائق';

      // Show review bottom sheet
      await Future.delayed(const Duration(milliseconds: 500));
      Get.bottomSheet(
        ReviewView(tripId: tripIdStr, driverName: driverName),
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
      );
    }
  }

  /// Load nearby drivers (called manually or on location change, not auto-refresh)
  // Removed auto-refresh to reduce server load - use pull-to-refresh instead

  /// Load nearby drivers for riders
  Future<void> loadNearbyDrivers() async {
    Get.log(
      '[RideController] loadNearbyDrivers called - isDriver: ${isDriver.value}, hasLocationPermission: ${hasLocationPermission.value}, pickupLat: ${pickupLat.value}, pickupLng: ${pickupLng.value}',
    );

    if (isDriver.value) {
      Get.log('[RideController] Skipping: user is driver');
      return;
    }

    if (!hasLocationPermission.value) {
      Get.log('[RideController] Skipping: no location permission');
      // Silent - no annoying snackbar, just log
      return;
    }

    if (pickupLat.value == 0.0 || pickupLng.value == 0.0) {
      Get.log(
        '[RideController] Skipping: invalid location coordinates (${pickupLat.value}, ${pickupLng.value})',
      );
      // Silent - no annoying snackbar, just log
      return;
    }

    try {
      isLoadingDrivers.value = true;
      Get.log(
        '[RideController] Calling API to get nearby drivers... lat: ${pickupLat.value}, lng: ${pickupLng.value}, radiusKm: null, limit: 100',
      );

      final drivers = await _driverApi.getNearbyDrivers(
        lat: pickupLat.value,
        lng: pickupLng.value,
        radiusKm:
            null, // No radius limit - show all available drivers (will be managed from admin panel later)
        limit: 100, // Increased limit to show more drivers
      );

      Get.log('[RideController] Received ${drivers.length} drivers from API');
      nearbyDrivers.assignAll(drivers);

      // Trigger markers rebuild after drivers are loaded
      update(['markers', 'nearbyDrivers']);
      Get.log('[RideController] Drivers updated, markers rebuild triggered');

      if (drivers.isEmpty) {
        Get.log('[RideController] No drivers found');
        // Silent - no annoying snackbar for empty state
        // The UI will show empty state naturally
      } else {
        Get.log(
          '[RideController] Found ${drivers.length} drivers - showing on map',
        );
      }
    } catch (e, stackTrace) {
      Get.log(
        '[RideController] Error loading nearby drivers: $e',
        isError: true,
      );
      Get.log('[RideController] Stack trace: $stackTrace', isError: true);
      
      // Silent error handling - no annoying snackbar for network errors
      // The UI will show loading state or retry option naturally
      // Only show error if it's a critical user action (not background refresh)
    } finally {
      isLoadingDrivers.value = false;
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

      // Check if location services are enabled
      if (hasLocationPermission.value) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          final shouldOpen = await Get.dialog<bool>(
            Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
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
        }
      }
    } catch (e) {
      Get.log('[RideController] Permission error: $e', isError: true);
      hasLocationPermission.value = false;
    }
  }

  void _startListening() {
    // Cancel previous stream if exists
    _locationStreamSubscription?.cancel();
    
    if (tripId.value.isEmpty) {
      Get.log('[RideController] Cannot start listening: tripId is empty');
      isStreaming.value = false;
      return;
    }
    
    Get.log('[RideController] Starting to listen for driver location: tripId=${tripId.value}');
    isStreaming.value = true;
    
    _locationStreamSubscription = _tracking.streamDriverLocation(tripId.value).listen(
      (loc) {
        if (loc != null) {
          // Throttle UI updates to once per second to reduce lag
          final now = DateTime.now();
          if (now.difference(_lastLocationUpdate).inMilliseconds > 1000 || lastLocation.value == null) {
            Get.log('[RideController] Updating driver location (throttled): lat=${loc.lat}, lng=${loc.lng}');
            lastLocation.value = loc;
            _lastLocationUpdate = now;
            
            // Trigger UI update
            update(['driver_location']);
          }

          // If assigned but no route yet, try to fetch it now that we have driver location
          if (activeTrip.value?['status'] == 'assigned' && routePoints.isEmpty) {
            _fetchDirections();
          }
        } else {
          Get.log('[RideController] Received null location (no data yet)');
        }
      },
      onError: (error) {
        Get.log('[RideController] Error listening to driver location: $error', isError: true);
        isStreaming.value = false;
      },
      onDone: () {
        Get.log('[RideController] Driver location stream closed');
        isStreaming.value = false;
      },
    );
  }
  
  void _stopListening() {
    Get.log('[RideController] Stopping driver location stream');
    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
    isStreaming.value = false;
    lastLocation.value = null;
  }

  /// Start listening to trip status changes via Firebase RTDB (Hybrid: Live Flow)
  void _startListeningToTripStatus(String tripIdStr) {
    // Cancel previous subscription
    _tripStatusSubscription?.cancel();

    Get.log('[RideController] Starting to listen to trip status: $tripIdStr');

    String? _lastProcessedStatus; // Track last processed status to avoid duplicate navigation

    _tripStatusSubscription = _realtimeTrips.streamTrip(tripIdStr).listen(
      (trip) {
        if (trip == null) return;

        final status = trip['status']?.toString() ?? '';
        
        // Skip if status hasn't changed (prevents navigation loops)
        if (_lastProcessedStatus == status) {
          Get.log('[RideController] Status unchanged ($status), skipping navigation');
          
          // Still update activeTrip data (for bids, etc.)
          final existingBids = activeTrip.value?['bids'] ?? bids;
          final updatedTrip = Map<String, dynamic>.from(trip);
          if (existingBids != null && existingBids is List) {
            updatedTrip['bids'] = existingBids;
            updatedTrip['bids_count'] = existingBids.length;
          }
          activeTrip.value = updatedTrip;
          update(['active_trip', 'trip_status']);
          return;
        }
        
        _lastProcessedStatus = status;
        Get.log('[RideController] ========== RTDB Status Change: $status ==========');

        // Preserve existing bids if they exist (to avoid losing them)
        final existingBids = activeTrip.value?['bids'] ?? bids;
        final updatedTrip = Map<String, dynamic>.from(trip);
        if (existingBids != null && existingBids is List) {
          updatedTrip['bids'] = existingBids;
          updatedTrip['bids_count'] = existingBids.length;
        }

        // Update active trip with latest data from RTDB
        activeTrip.value = updatedTrip;

        // Update tripId if changed
        final newTripId = trip['id']?.toString() ?? '';
        if (newTripId.isNotEmpty && tripId.value != newTripId) {
          tripId.value = newTripId;
        }

        // Update coordinates from trip data
        final pickup = trip['pickup'] as Map?;
        final dropoff = trip['dropoff'] as Map?;
        if (pickup != null) {
          pickupLat.value = (pickup['lat'] as num?)?.toDouble() ?? pickupLat.value;
          pickupLng.value = (pickup['lng'] as num?)?.toDouble() ?? pickupLng.value;
        }
        if (dropoff != null) {
          dropoffLat.value = (dropoff['lat'] as num?)?.toDouble() ?? dropoffLat.value;
          dropoffLng.value = (dropoff['lng'] as num?)?.toDouble() ?? dropoffLng.value;
        }

        // ========== STATE MACHINE: Navigate based on status ==========
        switch (status) {
          case 'bidding':
            // Rider: Stay on bids screen, wait for bids
            // Driver: N/A (drivers see this in available trips)
            Get.log('[RideController] State: BIDDING - waiting for bids');
            if (!isDriver.value) {
              // Ensure bids listener is active
              if (_tripBidsSubscription == null) {
                _startListeningToTripBids(tripIdStr);
              }
            }
            break;

          case 'assigned':
            // Rider: Navigate to waiting screen (driver accepted)
            // Driver: Navigate to pickup map
            Get.log('[RideController] State: ASSIGNED - driver accepted bid');
            if (isDriver.value) {
              // Driver: Navigate to pickup/tracking screen
              Get.log('[RideController] Driver: Navigating to trip tracking');
              if (Get.currentRoute != '/trip-tracking/$tripIdStr') {
                Get.offAllNamed('/trip-tracking/$tripIdStr');
              }
            } else {
              // Rider: Navigate to tracking screen
              Get.log('[RideController] Rider: Navigating to trip tracking');
              if (Get.currentRoute != '/trip-tracking/$tripIdStr') {
                Get.toNamed('/trip-tracking/$tripIdStr');
              }
            }
            // Start location tracking
            if (tripId.value.isNotEmpty && _locationStreamSubscription == null) {
              _startListening();
            }

            // Fetch DIRECTIONS: Driver Location -> Pickup Location
            _fetchDirections();
            break;

          case 'arrived':
            // Rider: Show "Driver has arrived" alert
            // Driver: Show "Start Trip" button
            Get.log('[RideController] State: ARRIVED - driver at pickup');
            if (!isDriver.value) {
              Get.snackbar(
                'السائق وصل',
                'السائق في انتظارك',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 5),
                snackPosition: SnackPosition.TOP,
              );
            }
            break;

          case 'in_progress':
            // Both: Switch to live tracking mode
            Get.log('[RideController] State: IN_PROGRESS - trip started');
            if (Get.currentRoute != '/trip-tracking/$tripIdStr') {
              Get.offAllNamed('/trip-tracking/$tripIdStr');
            }
            // Ensure location tracking is active
            if (tripId.value.isNotEmpty && _locationStreamSubscription == null) {
              _startListening();
            }

            // Fetch DIRECTIONS: Pickup Location -> Dropoff Location
            _fetchDirections();
            break;

          case 'completed':
            // Both: Navigate to rating/payment screen
            Get.log('[RideController] State: COMPLETED - trip finished');
            _stopListening();
            _stopListeningToTripStatus();
            _stopListeningToTripBids();

            if (!isDriver.value) {
              // Rider: Show review screen
              Get.log('[RideController] Rider: Checking for review');
              checkForCompletedTripNeedingReview();
            } else {
              // Driver: Navigate back to dashboard
              Get.log('[RideController] Driver: Navigating to dashboard');
              Get.offAllNamed('/driver-dashboard');
              Get.snackbar(
                'اكتملت الرحلة',
                'تم إكمال الرحلة بنجاح',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            }
            break;

          case 'cancelled':
            Get.log('[RideController] State: CANCELLED - trip cancelled');
            _stopListening();
            _stopListeningToTripStatus();
            _stopListeningToTripBids();
            
            // Clear active trip
            activeTrip.value = null;
            tripId.value = '';
            
            // DON'T auto-navigate - let user stay on current screen
            // They can use back button or the UI will update naturally
            // This prevents controller recreation and excessive API calls
            break;


          default:
            Get.log('[RideController] Unknown status: $status');
        }

        // Trigger UI update
        update(['active_trip', 'trip_status']);
      },
      onError: (error) {
        Get.log(
          '[RideController] Error listening to trip status: $error',
          isError: true,
        );
      },
    );
  }

  /// Stop listening to trip status
  void _stopListeningToTripStatus() {
    _tripStatusSubscription?.cancel();
    _tripStatusSubscription = null;
  }

  /// Start listening to bids for a trip via Firebase RTDB (Hybrid: Live Flow)
  void _startListeningToTripBids(String tripIdStr) {
    // Cancel previous subscription
    _tripBidsSubscription?.cancel();
    _tripBidsSubscription = null;

    Get.log('[RideController] ========== Starting to listen to trip bids: $tripIdStr ==========');
    Get.log('[RideController] Current tripId: ${tripId.value}');
    Get.log('[RideController] Active trip: ${activeTrip.value != null ? activeTrip.value!['id'] : 'null'}');

    try {
      _tripBidsSubscription = _realtimeTrips.streamTripBids(tripIdStr).listen(
        (bidsList) {
          Get.log(
            '[RideController] ========== RTDB BIDS UPDATE: Received ${bidsList.length} bids for trip $tripIdStr ==========',
          );
          if (bidsList.isNotEmpty) {
            for (var bid in bidsList) {
              Get.log(
                '[RideController] Bid: driver_id=${bid['driver_id']}, amount=${bid['amount']}, status=${bid['status']}',
              );
            }
          }
          
          bids.assignAll(bidsList);
          
          // Update activeTrip to reflect bids count (for UI display)
          if (activeTrip.value != null && tripId.value == tripIdStr) {
            final updatedTrip = Map<String, dynamic>.from(activeTrip.value!);
            updatedTrip['bids'] = bidsList;
            updatedTrip['bids_count'] = bidsList.length;
            activeTrip.value = updatedTrip;
            Get.log(
              '[RideController] ✓ Updated activeTrip with ${bidsList.length} bids',
            );
          } else {
            Get.log(
              '[RideController] ⚠ Active trip mismatch: activeTrip=${activeTrip.value != null ? activeTrip.value!['id'] : 'null'}, tripId=${tripId.value}, listeningTo=$tripIdStr',
            );
          }
          
          // Trigger UI update
          update(['bids', 'active_trip']);
          
          // Show notification if new bid received
          if (bidsList.isNotEmpty) {
            Get.log('[RideController] Showing notification for ${bidsList.length} bid(s)');
            // You can add a snackbar here if needed
          }
        },
        onError: (error, stackTrace) {
          Get.log(
            '[RideController] ========== RTDB BIDS STREAM ERROR ==========',
            isError: true,
          );
          Get.log('[RideController] Error: $error', isError: true);
          Get.log('[RideController] Stack trace: $stackTrace', isError: true);
          
          // Try to restart the stream after a delay
          Future.delayed(const Duration(seconds: 3), () {
            if (tripId.value == tripIdStr && _tripBidsSubscription == null) {
              Get.log('[RideController] Attempting to restart bids stream after error...');
              _startListeningToTripBids(tripIdStr);
            }
          });
        },
        onDone: () {
          Get.log(
            '[RideController] ========== RTDB bids stream closed (onDone) ==========',
          );
          _tripBidsSubscription = null;
          
          // Try to restart if still listening to this trip
          if (tripId.value == tripIdStr) {
            Get.log('[RideController] Stream closed but still listening to trip, restarting...');
            Future.delayed(const Duration(seconds: 1), () {
              if (tripId.value == tripIdStr) {
                _startListeningToTripBids(tripIdStr);
              }
            });
          }
        },
        cancelOnError: false, // Don't cancel on error, let onError handle it
      );
      
      Get.log(
        '[RideController] ✓ RTDB bids stream subscription created successfully',
      );
    } catch (e, stackTrace) {
      Get.log(
        '[RideController] ========== EXCEPTION creating RTDB bids stream ==========',
        isError: true,
      );
      Get.log('[RideController] Exception: $e', isError: true);
      Get.log('[RideController] Stack trace: $stackTrace', isError: true);
    }
  }

  /// Stop listening to trip bids
  void _stopListeningToTripBids() {
    _tripBidsSubscription?.cancel();
    _tripBidsSubscription = null;
  }

  /// Request a trip (general)
  Future<void> requestTrip() async {
    // CRITICAL: Prevent multiple simultaneous requests
    if (isRequestingTrip.value || isBusy.value) {
      Get.log(
        '[RideController] Request trip already in progress, ignoring duplicate request',
      );
      return;
    }

    try {
      isRequestingTrip.value = true;
      isBusy.value = true;
      errorMessage.value = null;

      Get.log(
        '[RideController] Requesting trip... - pickup: ${pickupLat.value}, ${pickupLng.value}, dropoff: ${dropoffLat.value}, ${dropoffLng.value}, price: ${offeredPrice.value}',
      );

      final trip = await _trips.requestTrip(
        pickupLat: pickupLat.value,
        pickupLng: pickupLng.value,
        dropoffLat: dropoffLat.value,
        dropoffLng: dropoffLng.value,
        offeredPrice: offeredPrice.value,
      );

      Get.log(
        '[RideController] Trip requested successfully - trip_id: ${trip['id']}',
      );

      tripId.value = trip['id'].toString();
      
      // Set active trip immediately (status: bidding) so UI can show it
      activeTrip.value = {
        ...trip,
        'status': 'bidding',
        'bids': [],
        'bids_count': 0,
      };
      
      // Hybrid: Start listening to RTDB for real-time updates (Live Flow)
      // CRITICAL: Start listening immediately so rider sees bids as they come in
      _startListeningToTripStatus(tripId.value);
      _startListeningToTripBids(tripId.value);
      
      Get.log('[RideController] Started listening to trip ${tripId.value} for bids and status updates');
      
      await loadMyTrips(); // Refresh my trips list (fallback/initial load)
      checkActiveTrip(); // Check for active trip (will update if needed)
      Get.snackbar(
        'نجح',
        'تم طلب الرحلة بنجاح - انتظر العروض',
        backgroundColor: Colors.white,
        colorText: Colors.black,
        borderColor: Colors.grey.shade300,
        borderWidth: 1,
      );
      // Navigate to my trips screen to show waiting message
      Get.toNamed('/my-trips');
    } catch (e) {
      Get.log('[RideController] Error requesting trip: $e', isError: true);
      errorMessage.value = 'network_error'.tr;
      Get.snackbar('خطأ', 'فشل في طلب الرحلة');
    } finally {
      isRequestingTrip.value = false;
      isBusy.value = false;
    }
  }

  /// Request a trip with a specific driver (direct booking)
  Future<void> requestTripWithDriver(String driverId) async {
    try {
      isRequestingTrip.value = true;
      isBusy.value = true;
      errorMessage.value = null;

      Get.log('[RideController] Requesting trip with driver: $driverId');

      // First create the trip
      final trip = await _trips.requestTrip(
        pickupLat: pickupLat.value,
        pickupLng: pickupLng.value,
        dropoffLat: dropoffLat.value,
        dropoffLng: dropoffLng.value,
        offeredPrice: offeredPrice.value,
      );
      tripId.value = trip['id'].toString();

      Get.log(
        '[RideController] Trip created: ${trip['id']}, now sending notification to driver: $driverId',
      );

      // Send FCM notification to the specific driver
      // The backend will handle this automatically when trip is created
      // But we can also explicitly notify this driver

      await loadMyTrips();
      checkActiveTrip();

      Get.snackbar(
        'نجح',
        'تم طلب الرحلة بنجاح. سيتم إشعار السائق.',
        backgroundColor: Colors.white,
        colorText: Colors.green.shade700,
        borderColor: Colors.green.shade300,
        borderWidth: 1,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.log('[RideController] Error requesting trip: $e', isError: true);
      errorMessage.value = 'network_error'.tr;
      Get.snackbar(
        'خطأ',
        'فشل في طلب الرحلة: ${e.toString()}',
        backgroundColor: Colors.white,
        colorText: Colors.red.shade700,
        borderColor: Colors.red.shade300,
        borderWidth: 1,
      );
    } finally {
      isRequestingTrip.value = false;
      isBusy.value = false;
    }
  }

  Future<void> loadMyTrips() async {
    if (isDriver.value) return;
    try {
      isBusy.value = true;
      errorMessage.value = null;
      Get.log('[RideController] ========== Loading my trips ==========');
      final trips = await _trips.getMyTrips();
      Get.log('[RideController] Received ${trips.length} trips from API');

      // Log all trips for debugging
      for (var trip in trips) {
        Get.log(
          '[RideController] Trip ${trip['id']}: status=${trip['status']}, driver_id=${trip['driver_id']}, accepted_price=${trip['accepted_price']}',
        );
      }

      final oldActiveTripId = activeTrip.value?['id']?.toString();
      final oldActiveTripStatus = activeTrip.value?['status']?.toString();

      myTrips.assignAll(trips);
      Get.log(
        '[RideController] myTrips updated, now has ${myTrips.length} trips',
      );

      // Check for active trip after loading
      checkActiveTrip();

      final newActiveTripId = activeTrip.value?['id']?.toString();
      final newActiveTripStatus = activeTrip.value?['status']?.toString();

      if (oldActiveTripId != newActiveTripId ||
          oldActiveTripStatus != newActiveTripStatus) {
        Get.log(
          '[RideController] Active trip changed! Old: $oldActiveTripId ($oldActiveTripStatus) -> New: $newActiveTripId ($newActiveTripStatus)',
        );
      }

      Get.log(
        '[RideController] ========== Finished loading my trips ==========',
      );
    } catch (e, stackTrace) {
      Get.log('[RideController] ERROR loading my trips: $e', isError: true);
      Get.log('[RideController] Stack trace: $stackTrace', isError: true);
      errorMessage.value = 'network_error'.tr;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> refreshBids() async {
    if (tripId.value.isEmpty) return;
    try {
      isBusy.value = true;
      errorMessage.value = null;
      final list = await _trips.listBids(tripId: tripId.value);
      bids.assignAll(list);
    } catch (e) {
      errorMessage.value = 'network_error'.tr;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> loadAvailableTrips() async {
    if (!isDriver.value) return;
    try {
      isBusy.value = true;
      errorMessage.value = null;
      final trips = await _trips.getAvailableTrips();
      availableTrips.assignAll(trips);
    } catch (e) {
      Get.log('[RideController] Error loading trips: $e', isError: true);
      errorMessage.value = 'network_error'.tr;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> placeBid({String? tripIdParam, double? amount}) async {
    final targetTripId = tripIdParam ?? tripId.value;
    final targetAmount = amount ?? bidAmount.value;
    if (targetTripId.isEmpty) return;
    try {
      isBusy.value = true;
      errorMessage.value = null;
      await _trips.placeBid(tripId: targetTripId, amount: targetAmount);
      // Refresh available trips after placing bid
      await loadAvailableTrips();
      Get.snackbar('نجح', 'تم وضع المزايدة بنجاح');
    } catch (e) {
      Get.log('[RideController] Error placing bid: $e', isError: true);
      errorMessage.value = 'network_error'.tr;
      Get.snackbar(
        'خطأ',
        'فشل في وضع المزايدة',
        backgroundColor: Colors.white,
        colorText: Colors.red.shade700,
        borderColor: Colors.red.shade300,
        borderWidth: 1,
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> acceptBid() async {
    Get.log(
      '[RideController] acceptBid called: tripId=${tripId.value}, bidId=${acceptBidId.value}',
    );

    if (tripId.value.isEmpty || acceptBidId.value.isEmpty) {
      Get.log('[RideController] Cannot accept bid: missing tripId or bidId');
      Get.snackbar(
        'خطأ',
        'البيانات غير مكتملة',
        backgroundColor: Colors.white,
        colorText: Colors.red.shade700,
        borderColor: Colors.red.shade300,
        borderWidth: 1,
      );
      return;
    }

    try {
      isBusy.value = true;
      errorMessage.value = null;

      Get.log('[RideController] Calling API to accept bid...');
      final result = await _trips.acceptBid(
        tripId: tripId.value,
        bidId: acceptBidId.value,
      );
      Get.log('[RideController] Bid accepted successfully: $result');

      // Set active trip for floating card
      Get.log('[RideController] Checking for active trip...');
      checkActiveTrip();

      Get.log(
        '[RideController] Active trip after check: ${activeTrip.value != null ? activeTrip.value!['id'] : 'null'}, status: ${activeTrip.value != null ? activeTrip.value!['status'] : 'N/A'}',
      );

      // Start tracking after assignment (family link will use same tripId)
      _startListening();

      Get.snackbar(
        'نجح',
        'تم قبول العرض بنجاح',
        backgroundColor: Colors.white,
        colorText: Colors.black,
        borderColor: Colors.grey.shade300,
        borderWidth: 1,
      );
      Get.back(); // Close bids view

      // Navigate to trip tracking view
      final activeTripData = activeTrip.value;
      if (activeTripData != null) {
        Get.log(
          '[RideController] Navigating to trip tracking with active trip: ${activeTripData['id']}',
        );
        Get.toNamed('/trip-tracking', arguments: {'trip': activeTripData});
      } else {
        Get.log(
          '[RideController] No active trip found after acceptance, staying on current screen',
        );
      }
    } catch (e, stackTrace) {
      Get.log('[RideController] Error accepting bid: $e', isError: true);
      Get.log('[RideController] Stack trace: $stackTrace', isError: true);

      // Handle specific error messages
      String errorMessageText = 'فشل في قبول العرض';
      if (e.toString().contains('debt_limit_exceeded')) {
        errorMessageText =
            'السائق تجاوز حد الدين المسموح. يرجى اختيار سائق آخر.';
      } else if (e.toString().contains('trip_not_biddable')) {
        errorMessageText = 'الرحلة لم تعد متاحة للمزايدة';
      } else if (e.toString().contains('bid_not_found')) {
        errorMessageText = 'العرض غير موجود';
      }

      errorMessage.value = errorMessageText;
      Get.snackbar(
        'خطأ',
        errorMessageText,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isBusy.value = false;
    }
  }

  /// Notify rider that driver has arrived at pickup location
  Future<void> notifyArrival() async {
    if (tripId.value.isEmpty) return;
    try {
      isBusy.value = true;
      errorMessage.value = null;
      Get.log('[RideController] Notifying arrival for trip: ${tripId.value}');
      
      await _trips.notifyArrival(tripId: tripId.value);
      
      // Don't refresh - RTDB will handle the update automatically
      Get.log('[RideController] Arrival notification sent, waiting for RTDB update');
      
      Get.snackbar(
        'تم الإشعار',
        'تم إشعار الراكب بوصولك',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.log('[RideController] Error notifying arrival: $e', isError: true);
      errorMessage.value = 'network_error'.tr;
      Get.snackbar(
        'خطأ',
        'فشل في إرسال الإشعار',
        backgroundColor: Colors.white,
        colorText: Colors.red.shade700,
        borderColor: Colors.red.shade300,
        borderWidth: 1,
      );
    } finally {
      isBusy.value = false;
    }
  }

  /// Start the trip (driver picked up the rider)
  Future<void> startTrip() async {
    if (tripId.value.isEmpty) return;
    try {
      isBusy.value = true;
      errorMessage.value = null;
      await _trips.startTrip(tripId: tripId.value);
      
      // Don't refresh trips - RTDB listener will handle the status update
      // This prevents unnecessary API calls and ensures real-time updates work
      Get.log('[RideController] Trip started, waiting for RTDB status update...');
      
      Get.snackbar('نجح', 'تم بدء الرحلة');
    } catch (e) {
      Get.log('[RideController] Error starting trip: $e', isError: true);
      errorMessage.value = 'network_error'.tr;
      Get.snackbar(
        'خطأ',
        'فشل في بدء الرحلة',
        backgroundColor: Colors.white,
        colorText: Colors.red.shade700,
        borderColor: Colors.red.shade300,
        borderWidth: 1,
      );
    } finally {
      isBusy.value = false;
    }
  }

  /// Complete the trip (driver dropped off the rider)
  Future<void> completeTrip() async {
    if (tripId.value.isEmpty || isCompletingTrip.value) return;

    try {
      isCompletingTrip.value = true;
      isBusy.value = true;
      errorMessage.value = null;
      await _trips.completeTrip(tripId: tripId.value);

      // CRITICAL: Close trip tracking view and all related bottom sheets
      // Close trip tracking view if open
      if (Get.currentRoute == '/trip-tracking') {
        Get.log('[RideController] Closing trip tracking view...');
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Close all trip-related bottom sheets (including DraggableScrollableSheet from trip tracking)
      // We need to close all bottom sheets to ensure clean state
      int closedCount = 0;
      while (Get.isBottomSheetOpen ?? false && closedCount < 3) {
        Get.log('[RideController] Closing trip-related bottom sheet...');
        Get.back();
        closedCount++;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Refresh trips
      await loadMyTrips();
      checkActiveTrip();

      // Clear active trip (trip is now completed) - this will hide trip bottom sheet and show request form
      activeTrip.value = null;

      // Get driver info for review
      final completedTrips = await _trips.getMyTrips();
      final trip = completedTrips.firstWhereOrNull(
        (t) => t['id']?.toString() == tripId.value,
      );

      final driverName = trip?['driver']?['name']?.toString() ?? 'السائق';

      // Clear tripId after getting driver info
      final reviewTripId = tripId.value;
      tripId.value = '';

      // Navigate to home screen (main screen for rider)
      Get.offAllNamed('/home');

      // Wait for navigation to complete
      await Future.delayed(const Duration(milliseconds: 500));

      Get.snackbar(
        'نجح',
        'تم إكمال الرحلة بنجاح',
        backgroundColor: Colors.white,
        colorText: Colors.black,
        borderColor: Colors.grey.shade300,
        borderWidth: 1,
      );

      // Show review bottom sheet after navigation
      await Future.delayed(const Duration(milliseconds: 500));
      Get.bottomSheet(
        ReviewView(tripId: reviewTripId, driverName: driverName),
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
      );
    } catch (e) {
      Get.log('[RideController] Error completing trip: $e', isError: true);
      errorMessage.value = 'network_error'.tr;
      Get.snackbar(
        'خطأ',
        'فشل في إكمال الرحلة',
        backgroundColor: Colors.white,
        colorText: Colors.red.shade700,
        borderColor: Colors.red.shade300,
        borderWidth: 1,
      );
    } finally {
      isCompletingTrip.value = false;
      isBusy.value = false;
    }
  }

  /// Cancel the trip
  Future<void> cancelTrip() async {
    if (tripId.value.isEmpty || isCancellingTrip.value) return;

    try {
      isCancellingTrip.value = true;
      isBusy.value = true;
      errorMessage.value = null;
      
      await _trips.cancelTrip(tripId: tripId.value);

      // RTDB listener will update status to 'cancelled' automatically
      // No need to call loadMyTrips - just clean up local state
      
      // Clear active trip
      activeTrip.value = null;
      tripId.value = '';
      _stopListening();

      // Close ALL bottom sheets and dialogs
      while (Get.isBottomSheetOpen ?? false) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Reset trip data for new request
      pickupAddress.value = '';
      dropoffAddress.value = '';
      pickupLat.value = 0.0;
      pickupLng.value = 0.0;
      dropoffLat.value = 0.0;
      dropoffLng.value = 0.0;
      offeredPrice.value = 0.0;

      // Show success message
      Get.snackbar(
        'تم الإلغاء',
        'يمكنك طلب رحلة جديدة الآن',
        backgroundColor: Colors.white,
        colorText: Colors.black,
        borderColor: Colors.grey.shade300,
        borderWidth: 1,
        duration: const Duration(seconds: 2),
      );
      
      // Navigate to ride map for quick new trip request
      // Clear navigation stack to prevent back button issues
      Get.offAllNamed('/ride-map');
      
    } catch (e) {
      Get.log('[RideController] Error cancelling trip: $e', isError: true);
      errorMessage.value = 'network_error'.tr;
      Get.snackbar(
        'خطأ',
        'فشل في إلغاء الرحلة',
        backgroundColor: Colors.white,
        colorText: Colors.red.shade700,
        borderColor: Colors.red.shade300,
        borderWidth: 1,
      );
    } finally {
      isBusy.value = false;
      isCancellingTrip.value = false;
    }
  }

  Future<void> sendMockDriverLocation() async {
    try {
      isSending.value = true;
      // Simple demo points (Sana'a-ish). Real app will use Geolocator stream.
      final t = DateTime.now().millisecondsSinceEpoch;
      final lat = 15.3694 + ((t % 20) * 0.0001);
      final lng = 44.1910 + ((t % 20) * 0.0001);

      await _tracking.updateDriverLocation(
        tripId: tripId.value,
        lat: lat,
        lng: lng,
        heading: 90,
        speed: 10,
      );
    } finally {
      isSending.value = false;
    }
  }

  /// Submit review for completed trip
  Future<void> submitReview(String tripId) async {
    if (reviewRating.value == 0) {
      Get.snackbar(
        'تنبيه',
        'يرجى اختيار تقييم',
        backgroundColor: Colors.white,
        colorText: Colors.red.shade700,
        borderColor: Colors.red.shade300,
        borderWidth: 1,
      );
      return;
    }

    try {
      isSubmittingReview.value = true;
      await _reviewApi.submitReview(
        tripId: tripId,
        rating: reviewRating.value,
        comment: reviewCommentController.text.trim(),
      );

      // Mark trip as reviewed
      reviewedTripIds.add(tripId);

      // Reset review state
      reviewRating.value = 0;
      reviewCommentController.clear();

      // Close review bottom sheet
      Get.back();

      // Close all bottom sheets
      while (Get.isBottomSheetOpen ?? false) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      Get.snackbar(
        'شكراً لك',
        'تم إرسال التقييم بنجاح',
        backgroundColor: Colors.white,
        colorText: Colors.black,
        borderColor: Colors.grey.shade300,
        borderWidth: 1,
      );

      // Refresh trips to update driver rating
      await loadMyTrips();
    } catch (e) {
      Get.log('[RideController] Error submitting review: $e', isError: true);
      Get.snackbar(
        'خطأ',
        'فشل في إرسال التقييم',
        backgroundColor: Colors.white,
        colorText: Colors.red.shade700,
        borderColor: Colors.red.shade300,
        borderWidth: 1,
      );
    } finally {
      isSubmittingReview.value = false;
    }
  }

  Timer? _driverRefreshTimer;
  bool _isRefreshing = false;
  bool _hasShownNoDriversMessage = false;

  // ========== Step System Helper Methods ==========
  
  /// Move to next step in the request flow
  void goToNextStep() {
    if (currentRequestStep.value == 1) {
      // Validate pickup location
      if (!isPickupSelected.value || pickupLat.value == 0.0 || pickupLng.value == 0.0) {
        Get.snackbar(
          'تنبيه',
          'يرجى تحديد موقع الاستلام أولاً',
          backgroundColor: Colors.white,
          colorText: Colors.orange.shade700,
          borderColor: Colors.orange.shade300,
          borderWidth: 1,
          duration: const Duration(seconds: 2),
        );
        return;
      }
      currentRequestStep.value = 2;
    } else if (currentRequestStep.value == 2) {
      // Validate dropoff location
      if (!isDropoffSelected.value || dropoffLat.value == 0.0 || dropoffLng.value == 0.0) {
        Get.snackbar(
          'تنبيه',
          'يرجى تحديد موقع الوصول أولاً',
          backgroundColor: Colors.white,
          colorText: Colors.orange.shade700,
          borderColor: Colors.orange.shade300,
          borderWidth: 1,
          duration: const Duration(seconds: 2),
        );
        return;
      }
      currentRequestStep.value = 3;
    }
    // Step 3 is the final step (price selection)
  }
  
  /// Go back to previous step
  void goToPreviousStep() {
    if (currentRequestStep.value > 1) {
      currentRequestStep.value--;
    }
  }
  
  /// Select a price chip (1 = economy, 2 = standard, 3 = premium)
  void selectPriceChip(int chipNumber, double price) {
    selectedPriceChip.value = chipNumber;
    offeredPrice.value = price;
    isPriceSelected.value = true;
  }
  
  /// Dismiss tutorial and save preference
  void dismissTutorial() {
    showTutorial.value = false;
    // TODO: Save to GetStorage to persist across app restarts
    // GetStorage().write('hide_map_tutorial', true);
  }

  /// Start listening to rider's active trip for real-time bid count updates
  void _startListeningToMyActiveTrip() {
    if (isDriver.value) return;

    // Find active trip (bidding status)
    final activeBiddingTrip = myTrips.firstWhereOrNull(
      (trip) => trip['status'] == 'bidding',
    );

    if (activeBiddingTrip == null) {
      Get.log('[RideController] No active bidding trip found');
      return;
    }

    final tripIdStr = activeBiddingTrip['id']?.toString() ?? '';
    if (tripIdStr.isEmpty) return;

    _myActiveTripSubscription?.cancel();

    Get.log('[RideController] Rider: Starting to listen to active trip $tripIdStr for bid updates');

    _myActiveTripSubscription = _realtimeTrips.streamTrip(tripIdStr).listen(
      (trip) {
        if (trip == null) return;

        Get.log('[RideController] Rider: Active trip $tripIdStr updated from RTDB');

        // Update the trip in myTrips list
        final tripIndex = myTrips.indexWhere(
          (t) => t['id']?.toString() == tripIdStr,
        );

        if (tripIndex != -1) {
          // Preserve bids from RTDB
          final updatedTrip = Map<String, dynamic>.from(myTrips[tripIndex]);
          updatedTrip['bids'] = trip['bids'] ?? [];
          updatedTrip['bids_count'] = (trip['bids'] as List?)?.length ?? 0;
          updatedTrip['status'] = trip['status'];

          myTrips[tripIndex] = updatedTrip;
          update(['my_trips']);

          Get.log(
            '[RideController] Updated trip $tripIdStr in myTrips: ${updatedTrip['bids_count']} bids',
          );

          // If status changed from bidding, stop listening
          if (trip['status'] != 'bidding') {
            Get.log('[RideController] Trip $tripIdStr status changed to ${trip['status']}, stopping listener');
            _myActiveTripSubscription?.cancel();
            _myActiveTripSubscription = null;
          }
        }
      },
      onError: (error) {
        Get.log(
          '[RideController] Error listening to active trip: $error',
          isError: true,
        );
      },
    );
  }

  /// Stop listening to rider's active trip
  void _stopListeningToMyActiveTrip() {
    _myActiveTripSubscription?.cancel();
    _myActiveTripSubscription = null;
  }

  /// Start listening to available trips for drivers (Real-Time)
  void startListeningToAvailableTrips() {
    if (!isDriver.value) return;

    _availableTripsSubscription?.cancel();

    Get.log('[RideController] Driver: Starting to listen to available trips via RTDB');

    _availableTripsSubscription = _realtimeTrips.streamAvailableTrips().listen(
      (trips) {
        Get.log('[RideController] Driver: Received ${trips.length} available trips from RTDB');
        
        // Check if this is a new trip (show notification)
        final hadTrips = availableTrips.isNotEmpty;
        final newTripsCount = trips.length;
        
        availableTrips.assignAll(trips);
        update(['available_trips']);

        // Show notification if new trip appears
        if (!hadTrips && newTripsCount > 0) {
          Get.snackbar(
            'رحلة جديدة',
            'يوجد ${newTripsCount} رحلة متاحة',
            backgroundColor: Colors.blue,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.TOP,
          );
        } else if (hadTrips && newTripsCount > availableTrips.length) {
          // More trips than before
          Get.snackbar(
            'رحلة جديدة',
            'تمت إضافة رحلة جديدة',
            backgroundColor: Colors.blue,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            snackPosition: SnackPosition.TOP,
          );
        }
      },
      onError: (error) {
        Get.log(
          '[RideController] Error listening to available trips: $error',
          isError: true,
        );
      },
    );
  }

  /// Stop listening to available trips
  void stopListeningToAvailableTrips() {
    _availableTripsSubscription?.cancel();
    _availableTripsSubscription = null;
  }

  @override
  void onClose() {
    _driverRefreshTimer?.cancel();
    _stopListening();
    _stopListeningToTripStatus();
    _stopListeningToTripBids();
    stopListeningToAvailableTrips();
    _stopListeningToMyActiveTrip();
    reviewCommentController.dispose();
    super.onClose();
  }

  /// Fetch directions based on current status
  Future<void> _fetchDirections() async {
    final status = activeTrip.value?['status']?.toString() ?? '';
    
    if (_isFetchingDirections) {
      Get.log('[RideController] _fetchDirections already in progress, skipping');
      return;
    }

    LatLng? origin;
    LatLng? destination;

    if (status == 'assigned') {
      if (lastLocation.value != null && pickupLat.value != 0) {
        origin = LatLng(lastLocation.value!.lat, lastLocation.value!.lng);
        destination = LatLng(pickupLat.value, pickupLng.value);
      }
    } else if (status == 'in_progress') {
      if (pickupLat.value != 0 && dropoffLat.value != 0) {
        origin = LatLng(pickupLat.value, pickupLng.value);
        destination = LatLng(dropoffLat.value, dropoffLng.value);
      }
    }

    if (origin == null || destination == null) {
      Get.log('[RideController] Cannot fetch directions: origin or destination null (status: $status)');
      return;
    }

    // Create a key for the current route to avoid redundant fetches if nothing moved significantly
    // Use 4 decimal places (approx 11 meters) to allow slight movement without re-fetching
    final routeKey = '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}-${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}';
    
    if (routeKey == _lastFetchedRouteKey && routePoints.isNotEmpty) {
      Get.log('[RideController] Route unchanged, skipping fetch');
      return;
    }

    _isFetchingDirections = true;
    try {
      Get.log('[RideController] Fetching directions: $status');
      final points = await _googleMapsService.getDirections(origin, destination);
      
      if (points.isNotEmpty) {
        routePoints.assignAll(points);
        _lastFetchedRouteKey = routeKey;
      }
    } catch (e) {
      Get.log('[RideController] Error fetching directions: $e', isError: true);
    } finally {
      _isFetchingDirections = false;
    }
  }
}
