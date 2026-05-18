import 'package:get/get.dart';
import '../controllers/driver_controller.dart';
import '../../../core/network/driver_api.dart';
import '../../../core/network/auth_api.dart';
import '../../../core/network/trip_api.dart';
import '../../../core/network/api_client.dart';
import '../../../core/firebase/realtime_tracking_service.dart';
import '../../../core/firebase/realtime_trips_service.dart';
import '../../../core/config/app_config.dart';

class DriverBinding extends Bindings {
  @override
  void dependencies() {
    final apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    final driverApi = DriverApi(apiClient);
    final authApi = AuthApi(apiClient);
    final tripApi = TripApi(apiClient);
    final tracking = RealtimeTrackingService();
    final realtimeTrips = RealtimeTripsService();

    Get.lazyPut(() => DriverController(driverApi, authApi, tripApi, tracking, realtimeTrips));
  }
}
