import 'package:get/get.dart';

import '../controllers/ride_controller.dart';
import '../../../core/firebase/realtime_tracking_service.dart';
import '../../../core/firebase/realtime_trips_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/trip_api.dart';
import '../../../core/network/driver_api.dart';
import '../../../core/network/review_api.dart';
import '../../../core/services/google_maps_service.dart';
import '../../../data/services/settings_service.dart';

class RideBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiClient>(() => ApiClient());
    Get.lazyPut<SettingsService>(() => SettingsService());
    Get.lazyPut<GoogleMapsService>(() => GoogleMapsService());
    Get.lazyPut<RealtimeTrackingService>(() => RealtimeTrackingService());
    Get.lazyPut<RealtimeTripsService>(() => RealtimeTripsService());
    Get.lazyPut<TripApi>(() => TripApi(Get.find<ApiClient>()));
    Get.lazyPut<DriverApi>(() => DriverApi(Get.find<ApiClient>()));
    Get.lazyPut<ReviewApi>(() => ReviewApi(Get.find<ApiClient>()));
    Get.lazyPut<RideController>(() => RideController(
          Get.find<RealtimeTrackingService>(),
          Get.find<RealtimeTripsService>(),
          Get.find<TripApi>(),
          Get.find<DriverApi>(),
          Get.find<ReviewApi>(),
        ));
  }
}
