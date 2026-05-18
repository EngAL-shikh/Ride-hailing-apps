import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../../modules/driver/controllers/driver_controller.dart';
import '../../modules/ride/controllers/ride_controller.dart';
import '../network/api_client.dart';
import '../network/auth_api.dart';
import '../storage/auth_store.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Get.log('[FcmService] Background message: ${message.messageId}');
  // Process background message
}

/// FCM Service to handle push notifications
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    // Request permission (iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      Get.log('[FcmService] Notification permission granted');
    } else {
      Get.log('[FcmService] Notification permission denied');
    }

    // Get FCM token (with error handling for FIS_AUTH_ERROR)
    try {
      String? token = await _messaging.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          Get.log('[FcmService] FCM token request timeout');
          return null;
        },
      );
      if (token != null) {
        Get.log('[FcmService] FCM Token: ${token.substring(0, 20)}...');
        // TODO: Send token to backend (already done in AuthController)
      } else {
        Get.log('[FcmService] FCM token is null - Firebase Installations may not be configured');
      }
    } catch (e) {
      Get.log('[FcmService] Failed to get FCM token: $e');
      // Don't crash the app if FCM fails - it's not critical for basic functionality
      if (e.toString().contains('FIS_AUTH_ERROR')) {
        Get.log('[FcmService] FIS_AUTH_ERROR: Please ensure SHA-1/SHA-256 fingerprints are added in Firebase Console');
      }
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }

    // Token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      Get.log('[FcmService] FCM Token refreshed: ${newToken.substring(0, 20)}...');
      // Update token in backend if user is logged in
      try {
        final token = AuthStore.token;
        if (token == null || token.isEmpty) return;

        final authApi =
            Get.isRegistered<AuthApi>() ? Get.find<AuthApi>() : AuthApi(ApiClient());

        authApi.updateFcmToken(fcmToken: newToken).then((_) {
          Get.log('[FcmService] FCM token updated in backend');
        }).catchError((e) {
          Get.log('[FcmService] Failed to update FCM token in backend: $e', isError: true);
        });
      } catch (e) {
        Get.log('[FcmService] Failed to update FCM token in backend: $e', isError: true);
      }
    });
  }

  /// Handle foreground messages (app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    Get.log('[FcmService] Foreground message received: ${message.messageId}');
    _processNotification(message);
  }

  /// Handle background messages (app is in background or terminated)
  void _handleBackgroundMessage(RemoteMessage message) {
    Get.log('[FcmService] Background message received: ${message.messageId}');
    _processNotification(message);
  }

  /// Process notification based on type
  void _processNotification(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    Get.log('[FcmService] ========== Processing FCM Notification ==========');
    Get.log('[FcmService] Message ID: ${message.messageId}');
    Get.log('[FcmService] Notification Type: $type');
    Get.log('[FcmService] Notification Data: $data');
    Get.log('[FcmService] Notification Title: ${message.notification?.title}');
    Get.log('[FcmService] Notification Body: ${message.notification?.body}');

    if (type == null) {
      Get.log('[FcmService] WARNING: Notification type is null, ignoring');
      return;
    }

    Get.log('[FcmService] Routing to handler for type: $type');
    switch (type) {
      case 'new_trip':
        // New trip available for driver
        _handleNewTrip(data);
        break;
      case 'new_bid':
        // New bid placed on rider's trip
        _handleNewBid(data);
        break;
      case 'your_bid_accepted':
        // Driver's bid was accepted
        _handleBidAccepted(data);
        break;
      case 'bid_accepted':
        // Rider's trip was accepted
        _handleRiderBidAccepted(data);
        break;
      case 'trip_started':
        // Trip has started
        _handleTripStarted(data);
        break;
      case 'trip_completed':
        // Trip completed
        _handleTripCompleted(data);
        break;
      default:
        Get.log('[FcmService] Unknown notification type: $type');
    }
  }

  /// Handle new trip notification (for drivers)
  void _handleNewTrip(Map<String, dynamic> data) {
    Get.log('[FcmService] ========== Handling new_trip notification ==========');
    Get.log('[FcmService] Data: $data');
    final tripId = data['trip_id'] as String?;
    final offeredPrice = data['offered_price'] as String?;
    
    // Only refresh available trips (smart update - no unnecessary API calls)
    try {
      Get.log('[FcmService] Checking if DriverController is registered...');
      final isRegistered = Get.isRegistered<DriverController>();
      Get.log('[FcmService] DriverController registered: $isRegistered');
      
      if (!isRegistered) {
        Get.log('[FcmService] WARNING: DriverController not registered yet. This might happen if notification arrives before driver dashboard is loaded.');
        Get.log('[FcmService] Attempting to register DriverController...');
        // Try to register DriverController if not already registered
        // This might happen if notification arrives before user navigates to driver dashboard
        try {
          // Import and use DriverBinding to register
          // Note: This requires importing DriverBinding
          Get.log('[FcmService] Cannot auto-register DriverController - user must navigate to driver dashboard first');
          // Show notification anyway
          Get.snackbar(
            'رحلة جديدة متاحة',
            offeredPrice != null
                ? 'رحلة جديدة بسعر $offeredPrice ريال - اضغط للمزايدة'
                : tripId != null
                    ? 'رحلة جديدة #$tripId - اضغط للمزايدة'
                    : 'رحلة جديدة متاحة - اضغط للمزايدة',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            icon: const Icon(Icons.directions_bike, color: Colors.green),
            margin: const EdgeInsets.all(16),
          );
          return;
        } catch (e) {
          Get.log('[FcmService] Failed to register DriverController: $e', isError: true);
          return;
        }
      }
      
      Get.log('[FcmService] Finding DriverController...');
      final driverController = Get.find<DriverController>();
      Get.log('[FcmService] DriverController found - isOnline: ${driverController.isOnline.value}, hasLocation: ${driverController.hasLocationPermission.value}');
      
      // CRITICAL: Always refresh available trips when new trip notification arrives
      // This ensures the driver sees the new trip immediately, regardless of online status
      // (The backend already filtered to only send to online drivers, so we can trust this)
      Get.log('[FcmService] Loading available trips (notification received means driver is online)...');
      
      // Force refresh available trips
      driverController.loadAvailableTrips().then((_) {
        Get.log('[FcmService] Available trips loaded - count: ${driverController.availableTrips.length}');
        
        // Show snackbar to notify driver about new trip
        Get.snackbar(
          'رحلة جديدة متاحة',
          offeredPrice != null
              ? 'رحلة جديدة بسعر $offeredPrice ريال - اضغط للمزايدة'
              : tripId != null
                  ? 'رحلة جديدة #$tripId - اضغط للمزايدة'
                  : 'رحلة جديدة متاحة - اضغط للمزايدة',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          icon: const Icon(Icons.directions_bike, color: Colors.green),
          margin: const EdgeInsets.all(16),
        );
        Get.log('[FcmService] Snackbar shown to driver');
      }).catchError((e, stackTrace) {
        Get.log('[FcmService] Error loading trips: $e', isError: true);
        Get.log('[FcmService] Stack trace: $stackTrace', isError: true);
      });
    } catch (e, stackTrace) {
      Get.log('[FcmService] ERROR: DriverController not found: $e', isError: true);
      Get.log('[FcmService] Stack trace: $stackTrace', isError: true);
    }
    Get.log('[FcmService] ========== Finished handling new_trip ==========');
  }

  /// Handle new bid notification (for riders)
  void _handleNewBid(Map<String, dynamic> data) {
    Get.log('[FcmService] ========== Handling new_bid notification ==========');
    Get.log('[FcmService] Data: $data');
    final tripId = data['trip_id'] as String?;
    final driverName = data['driver_name'] as String?;
    final bidAmount = data['bid_amount'] as String?;
    Get.log('[FcmService] Trip ID: $tripId, Driver: $driverName, Amount: $bidAmount');
    
    // RTDB listener already handles bid updates - no need to refresh trips
    // Just show notification to user
    Get.log('[FcmService] RTDB listener will handle bid update, showing notification only');
    
    // Show snackbar to notify user
    Get.snackbar(
      'مزايدة جديدة',
      driverName != null && bidAmount != null
        ? 'السائق $driverName عرض $bidAmount ريال'
        : tripId != null 
          ? 'تم استلام مزايدة جديدة على رحلتك #$tripId'
          : 'تم استلام مزايدة جديدة على رحلتك',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade900,
    );
    Get.log('[FcmService] Snackbar shown to rider');
    Get.log('[FcmService] ========== Finished handling new_bid ==========');
  }

  /// Handle bid accepted notification (for driver)
  void _handleBidAccepted(Map<String, dynamic> data) {
    Get.log('[FcmService] ========== Handling your_bid_accepted notification ==========');
    Get.log('[FcmService] Data: $data');
    final tripId = data['trip_id'] as String?;
    final acceptedPrice = data['accepted_price'] as String?;
    Get.log('[FcmService] Trip ID: $tripId, Accepted Price: $acceptedPrice');
    
    if (tripId == null) {
      Get.log('[FcmService] WARNING: Trip ID is null, cannot proceed');
      return;
    }

    // Smart update: refresh both available trips and assigned trips
    try {
      Get.log('[FcmService] Finding DriverController...');
      final driverController = Get.find<DriverController>();
      Get.log('[FcmService] DriverController found, isOnline: ${driverController.isOnline.value}');
      
      // Refresh available trips (trip is no longer available for bidding)
      if (driverController.isOnline.value) {
        Get.log('[FcmService] Driver is online, refreshing available trips...');
        driverController.loadAvailableTrips();
        Get.log('[FcmService] Available trips refreshed');
      }
      
      // Refresh driver trips to get the newly assigned trip
      Get.log('[FcmService] Refreshing driver trips...');
      driverController.refreshDriverTrips();
      Get.log('[FcmService] Driver trips refreshed');
      
      // Wait for API response and retry if trip not found (max 3 retries)
      Get.log('[FcmService] Waiting for trip to be loaded and showing bottom sheet...');
      _waitAndShowBottomSheet(driverController, tripId, retryCount: 0);
    } catch (e, stackTrace) {
      Get.log('[FcmService] ERROR: DriverController not found: $e', isError: true);
      Get.log('[FcmService] Stack trace: $stackTrace', isError: true);
    }
    Get.log('[FcmService] ========== Finished handling your_bid_accepted ==========');
  }

  /// Wait for trip to be loaded and show bottom sheet with retry logic
  void _waitAndShowBottomSheet(DriverController controller, String tripId, {int retryCount = 0}) {
    const maxRetries = 3;
    const delayMs = 1000; // Increased delay for API response
    
    Get.log('[FcmService] Waiting ${delayMs}ms before checking trip (retry $retryCount/$maxRetries)...');
    
    Future.delayed(Duration(milliseconds: delayMs), () {
      // Check if trip is now in activeTrip
      final activeTrip = controller.activeTrip.value;
      Get.log('[FcmService] Checking active trip: ${activeTrip?['id']?.toString()} (looking for: $tripId)');
      
      if (activeTrip != null && activeTrip['id']?.toString() == tripId) {
        // Trip found, show bottom sheet
        Get.log('[FcmService] ✓ Trip found! Showing bottom sheet...');
        controller.showTripAcceptedBottomSheet(tripId);
        Get.log('[FcmService] Bottom sheet shown successfully');
      } else if (retryCount < maxRetries) {
        // Trip not found yet, refresh again and retry
        Get.log('[FcmService] ✗ Trip not found yet, retrying... (${retryCount + 1}/$maxRetries)');
        controller.refreshDriverTrips();
        _waitAndShowBottomSheet(controller, tripId, retryCount: retryCount + 1);
      } else {
        // Max retries reached, show bottom sheet anyway (will show error if trip not found)
        Get.log('[FcmService] ⚠ Max retries reached, showing bottom sheet anyway');
        controller.showTripAcceptedBottomSheet(tripId);
      }
    });
  }

  /// Handle rider bid accepted notification
  void _handleRiderBidAccepted(Map<String, dynamic> data) {
    Get.log('[FcmService] ========== Handling bid_accepted notification (rider) ==========');
    Get.log('[FcmService] Data received: $data');
    final tripId = data['trip_id'] as String?;
    Get.log('[FcmService] Trip ID: $tripId');
    
    // RTDB listener already handles status updates - no need to refresh trips
    Get.log('[FcmService] RTDB listener will handle bid acceptance update automatically');
    Get.log('[FcmService] ========== Finished handling bid_accepted (rider) ==========');
  }

  /// Handle trip started notification
  void _handleTripStarted(Map<String, dynamic> data) {
    Get.log('[FcmService] ========== Handling trip_started notification ==========');
    Get.log('[FcmService] Data received: $data');
    final tripId = data['trip_id'] as String?;
    Get.log('[FcmService] Trip ID: $tripId');
    
    // RTDB listener already handles trip started status - just show notification
    Get.log('[FcmService] RTDB listener will handle trip started update, showing notification only');
    
    // Show notification to rider
    Get.snackbar(
      'بدأت الرحلة',
      tripId != null 
        ? 'السائق وصل وبدأت الرحلة #$tripId'
        : 'السائق وصل وبدأت الرحلة',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
    );
    Get.log('[FcmService] Snackbar shown to rider');
    Get.log('[FcmService] ========== Finished handling trip_started ==========');
  }

  /// Handle trip completed notification
  void _handleTripCompleted(Map<String, dynamic> data) {
    Get.log('[FcmService] ========== Handling trip_completed notification ==========');
    Get.log('[FcmService] Data received: $data');
    final tripId = data['trip_id'] as String?;
    final finalPrice = data['final_price'] as String?;
    Get.log('[FcmService] Trip ID: $tripId, Final Price: $finalPrice');
    
    // Smart update: refresh trips for rider only (driver already knows)
    try {
      Get.log('[FcmService] Finding RideController...');
      final rideController = Get.find<RideController>();
      Get.log('[FcmService] RideController found, loading trips...');
      
      // Close any existing bottom sheets first
      _closeAllBottomSheets();
      
      // Navigate to home screen for rider (if not already there)
      if (!rideController.isDriver.value) {
        // Close trip tracking view if open
        if (Get.currentRoute == '/trip-tracking') {
          Get.log('[FcmService] Closing trip tracking view...');
          Get.back();
        }
        
        // Navigate to home screen
        Get.log('[FcmService] Navigating to home screen...');
        Get.offAllNamed('/home');
        
        // Wait for navigation to complete
        Future.delayed(const Duration(milliseconds: 500), () {
          // Force refresh trips to get latest status
          rideController.loadMyTrips().then((_) {
            Get.log('[FcmService] Trips loaded, checking active trip...');
            rideController.checkActiveTrip();
            Get.log('[FcmService] Active trip check completed');
            Get.log('[FcmService] Active trip status: ${rideController.activeTrip.value?['status']}');
            
            // Show review bottom sheet for completed trip (only once, via FCM)
            // This is the ONLY place where review should be shown
            Get.log('[FcmService] Checking for completed trip needing review...');
            rideController.checkForCompletedTripNeedingReview();
            
            // Show notification to rider
            Get.snackbar(
              'اكتملت الرحلة',
              finalPrice != null 
                ? 'شكراً لاستخدامك مشوار - المبلغ: $finalPrice ريال'
                : 'شكراً لاستخدامك مشوار',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.blue.shade100,
              colorText: Colors.blue.shade900,
            );
            Get.log('[FcmService] Snackbar shown to rider');
          }).catchError((e) {
            Get.log('[FcmService] Error loading trips: $e', isError: true);
          });
        });
      } else {
        // For driver, just refresh trips
        rideController.loadMyTrips().catchError((e) {
          Get.log('[FcmService] Error loading trips: $e', isError: true);
        });
      }
    } catch (e, stackTrace) {
      Get.log('[FcmService] ERROR: RideController not found: $e', isError: true);
      Get.log('[FcmService] Stack trace: $stackTrace', isError: true);
    }
    Get.log('[FcmService] ========== Finished handling trip_completed ==========');
  }

  /// Close all bottom sheets
  void _closeAllBottomSheets() {
    int count = 0;
    while ((Get.isBottomSheetOpen ?? false) && count < 5) {
      Get.back();
      count++;
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
