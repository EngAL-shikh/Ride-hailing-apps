import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import '../../../firebase_options.dart';

/// Service to listen to Firebase Realtime Database for trip updates.
/// Handles real-time streams for:
/// - Available trips (for drivers)
/// - Trip status changes (for riders and drivers)
/// - Bids updates (for riders)
class RealtimeTripsService {
  final FirebaseDatabase _db;

  RealtimeTripsService({FirebaseDatabase? db})
    : _db =
          db ??
          FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL!,
          );

  /// Stream of available trips for drivers.
  /// Listens to /trips/available and emits new/updated trips.
  Stream<List<Map<String, dynamic>>> streamAvailableTrips() {
    final ref = _db.ref('trips/available');
    Get.log(
      '[RealtimeTripsService] ========== Starting RTDB stream: trips/available ==========',
    );
    Get.log('[RealtimeTripsService] Database URL: ${_db.databaseURL}');

    return ref.onValue
        .map((event) {
          final snapshot = event.snapshot;
          final value = snapshot.value;

          Get.log(
            '[RealtimeTripsService] ========== RTDB Event Received ==========',
          );
          Get.log('[RealtimeTripsService] Event type: ${event.type}');
          Get.log('[RealtimeTripsService] Has data: ${value != null}');

          if (value == null) {
            Get.log(
              '[RealtimeTripsService] No available trips (empty database)',
            );
            return <Map<String, dynamic>>[];
          }

          if (value is! Map) {
            Get.log(
              '[RealtimeTripsService] ✗ Invalid data format: ${value.runtimeType}',
              isError: true,
            );
            return <Map<String, dynamic>>[];
          }

          final trips = <Map<String, dynamic>>[];
          value.forEach((tripId, tripData) {
            if (tripData is Map) {
              trips.add({...Map<String, dynamic>.from(tripData), 'id': tripId});
              Get.log(
                '[RealtimeTripsService] Parsed trip: $tripId (status: ${tripData['status']})',
              );
            } else {
              Get.log(
                '[RealtimeTripsService] Skipping invalid trip data for $tripId: ${tripData.runtimeType}',
              );
            }
          });

          // Sort trips by created_at (newest first) - الأحدث في البداية
          trips.sort((a, b) {
            final aCreated = a['created_at']?.toString() ?? '';
            final bCreated = b['created_at']?.toString() ?? '';
            if (aCreated.isEmpty && bCreated.isEmpty) return 0;
            if (aCreated.isEmpty) return 1; // Put empty dates at end
            if (bCreated.isEmpty) return -1;
            // Compare dates (newest first = descending order)
            return bCreated.compareTo(aCreated);
          });

          Get.log(
            '[RealtimeTripsService] ✓ Successfully parsed ${trips.length} available trips (sorted: newest first)',
          );
          Get.log(
            '[RealtimeTripsService] Trip IDs: ${trips.map((t) => t['id']).join(', ')}',
          );
          return trips;
        })
        .handleError((error, stackTrace) {
          Get.log(
            '[RealtimeTripsService] ========== RTDB STREAM ERROR ==========',
            isError: true,
          );
          Get.log('[RealtimeTripsService] Error: $error', isError: true);
          Get.log(
            '[RealtimeTripsService] Stack trace: $stackTrace',
            isError: true,
          );
          return <Map<String, dynamic>>[];
        });
  }

  /// Stream of a specific trip's status and data.
  /// Listens to /trips/{trip_id} and emits updates.
  Stream<Map<String, dynamic>?> streamTrip(String tripId) {
    final ref = _db.ref('trips/$tripId');
    Get.log('[RealtimeTripsService] Starting to listen to trip: $tripId');

    return ref.onValue
        .map((event) {
          final snapshot = event.snapshot;
          final value = snapshot.value;

          if (value == null) {
            Get.log('[RealtimeTripsService] Trip $tripId not found');
            return null;
          }

          if (value is! Map) {
            Get.log(
              '[RealtimeTripsService] Invalid trip data format',
              isError: true,
            );
            return null;
          }

          final trip = Map<String, dynamic>.from(value);
          trip['id'] = tripId;

          Get.log(
            '[RealtimeTripsService] Trip $tripId updated: status=${trip['status']}',
          );
          return trip;
        })
        .handleError((error) {
          Get.log(
            '[RealtimeTripsService] Error listening to trip $tripId: $error',
            isError: true,
          );
          return null;
        });
  }

  /// Stream of bids for a specific trip.
  /// Listens to /trips/{trip_id}/bids and emits new/updated bids.
  Stream<List<Map<String, dynamic>>> streamTripBids(String tripId) {
    final ref = _db.ref('trips/$tripId/bids');
    Get.log(
      '[RealtimeTripsService] ========== Starting RTDB stream: trips/$tripId/bids ==========',
    );
    Get.log('[RealtimeTripsService] Database URL: ${_db.databaseURL}');

    return ref.onValue
        .map((event) {
          final snapshot = event.snapshot;
          final value = snapshot.value;

          Get.log(
            '[RealtimeTripsService] ========== RTDB Bids Event Received for trip $tripId ==========',
          );
          Get.log('[RealtimeTripsService] Event type: ${event.type}');
          Get.log('[RealtimeTripsService] Has data: ${value != null}');

          if (value == null) {
            Get.log(
              '[RealtimeTripsService] No bids for trip $tripId (empty node)',
            );
            return <Map<String, dynamic>>[];
          }

          if (value is! Map) {
            Get.log(
              '[RealtimeTripsService] ✗ Invalid bids data format: ${value.runtimeType}',
              isError: true,
            );
            return <Map<String, dynamic>>[];
          }

          final bids = <Map<String, dynamic>>[];
          value.forEach((driverId, bidData) {
            if (bidData is Map) {
              bids.add({
                ...Map<String, dynamic>.from(bidData),
                'driver_id': driverId,
              });
              Get.log(
                '[RealtimeTripsService] Parsed bid: driver_id=$driverId, amount=${bidData['amount']}',
              );
            } else {
              Get.log(
                '[RealtimeTripsService] Skipping invalid bid data for driver $driverId: ${bidData.runtimeType}',
              );
            }
          });

          // Sort by amount (lowest first) or created_at
          bids.sort((a, b) {
            final aAmount = (a['amount'] as num?)?.toDouble() ?? 0.0;
            final bAmount = (b['amount'] as num?)?.toDouble() ?? 0.0;
            return aAmount.compareTo(bAmount);
          });

          Get.log(
            '[RealtimeTripsService] ✓ Successfully parsed ${bids.length} bids for trip $tripId',
          );
          if (bids.isNotEmpty) {
            Get.log(
              '[RealtimeTripsService] Bid amounts: ${bids.map((b) => b['amount']).join(', ')}',
            );
          }
          return bids;
        })
        .handleError((error, stackTrace) {
          Get.log(
            '[RealtimeTripsService] ========== RTDB BIDS STREAM ERROR ==========',
            isError: true,
          );
          Get.log(
            '[RealtimeTripsService] Error listening to bids for trip $tripId: $error',
            isError: true,
          );
          Get.log(
            '[RealtimeTripsService] Stack trace: $stackTrace',
            isError: true,
          );
          return <Map<String, dynamic>>[];
        });
  }

  /// Stream of new bids (child_added) for a specific trip.
  /// Useful for showing notifications when a new bid arrives.
  Stream<Map<String, dynamic>> streamNewBids(String tripId) {
    final ref = _db.ref('trips/$tripId/bids');
    Get.log(
      '[RealtimeTripsService] Starting to listen to new bids for trip: $tripId',
    );

    return ref.onChildAdded
        .map((event) {
          final snapshot = event.snapshot;
          final value = snapshot.value;

          if (value == null || value is! Map) {
            Get.log(
              '[RealtimeTripsService] Invalid new bid data',
              isError: true,
            );
            return <String, dynamic>{};
          }

          final bid = Map<String, dynamic>.from(value);
          bid['driver_id'] = snapshot.key;

          Get.log(
            '[RealtimeTripsService] New bid received for trip $tripId: driver=${bid['driver_id']}, amount=${bid['amount']}',
          );
          return bid;
        })
        .handleError((error) {
          Get.log(
            '[RealtimeTripsService] Error listening to new bids: $error',
            isError: true,
          );
          return <String, dynamic>{};
        });
  }
}
