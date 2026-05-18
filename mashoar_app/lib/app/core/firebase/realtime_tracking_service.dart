import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import '../../../firebase_options.dart';

// Writes/reads trip tracking data directly to Firebase Realtime Database.
class RealtimeTrackingService {
  final FirebaseDatabase _db;

  RealtimeTrackingService({FirebaseDatabase? db}) 
      : _db = db ?? FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL!,
        );

  DatabaseReference _tripDriverRef(String tripId) {
    // Use driver_loc path as per plan (Phase 5.2)
    return _db.ref('trips/$tripId/driver_loc');
  }

  Future<void> updateDriverLocation({
    required String tripId,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
  }) async {
    try {
      final ref = _tripDriverRef(tripId);
      final data = {
        'lat': lat,
        'lng': lng,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        'ts': ServerValue.timestamp,
      };
      
      print('[RealtimeTrackingService] Writing to Firebase RTDB: trips/$tripId/driver_loc');
      print('[RealtimeTrackingService] Data: $data');
      
      await ref.set(data);
      
      print('[RealtimeTrackingService] Successfully wrote to Firebase RTDB');
    } catch (e, stackTrace) {
      print('[RealtimeTrackingService] Error writing to Firebase RTDB: $e');
      print('[RealtimeTrackingService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<DriverLocation?> streamDriverLocation(String tripId) {
    // Use driver_loc path as per plan
    final ref = _db.ref('trips/$tripId/driver_loc');
    Get.log('[RealtimeTrackingService] Starting to listen to Firebase RTDB: trips/$tripId/driver_loc');
    Get.log('[RealtimeTrackingService] Database URL: ${_db.databaseURL}');
    
    return ref.onValue.map((event) {
      Get.log('[RealtimeTrackingService] Received event from Firebase RTDB');
      final v = event.snapshot.value;
      Get.log('[RealtimeTrackingService] Snapshot value: $v');
      
      if (v is! Map) {
        Get.log('[RealtimeTrackingService] Value is not a Map, returning null');
        return null;
      }
      
      final lat = (v['lat'] as num?)?.toDouble();
      final lng = (v['lng'] as num?)?.toDouble();
      
      if (lat == null || lng == null) {
        Get.log('[RealtimeTrackingService] Missing lat/lng, returning null');
        return null;
      }
      
      Get.log('[RealtimeTrackingService] Parsed location: lat=$lat, lng=$lng');
      return DriverLocation(
        lat: lat,
        lng: lng,
        heading: (v['heading'] as num?)?.toDouble(),
        speed: (v['speed'] as num?)?.toDouble(),
        timestampMs: (v['ts'] as num?)?.toInt(),
      );
    }).handleError((error) {
      Get.log('[RealtimeTrackingService] Stream error: $error', isError: true);
    });
  }
}

class DriverLocation {
  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final int? timestampMs;

  const DriverLocation({
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    this.timestampMs,
  });
}

