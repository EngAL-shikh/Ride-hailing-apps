import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/otp_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/ride/bindings/ride_binding.dart';
import '../modules/ride/views/ride_request_view.dart';
import '../modules/ride/views/ride_map_view.dart';
import '../modules/ride/views/my_trips_view.dart';
import '../modules/ride/views/available_trips_view.dart';
import '../modules/ride/views/trip_bids_view.dart';
import '../modules/ride/views/trip_tracking_view.dart';
import '../modules/ride/views/driver_details_view.dart';
import '../modules/driver/bindings/driver_binding.dart';
import '../modules/driver/views/driver_dashboard_view.dart';
import '../modules/driver/views/driver_verification_view.dart';
import '../modules/driver/bindings/driver_verification_binding.dart';
import '../modules/wallet/bindings/wallet_binding.dart';
import '../modules/wallet/views/wallet_view.dart';
import '../core/storage/auth_store.dart';

class AppPages {
  AppPages._();

  static String get initial {
    // Check if user is already logged in
    final token = AuthStore.token;
    final userType = AuthStore.userType;

    if (token != null && token.isNotEmpty) {
      // User is logged in, redirect based on type
      if (userType == 'driver') {
        return Routes.driverDashboard;
      } else {
        return Routes.home;
      }
    }
    return Routes.login;
  }

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.otp,
      page: () => const OtpView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.rideRequest,
      page: () => const RideRequestView(),
      binding: RideBinding(),
    ),
    GetPage(
      name: Routes.rideMap,
      page: () => RideMapView(),
      binding: RideBinding(),
    ),
    GetPage(
      name: Routes.driverDashboard,
      page: () => const DriverDashboardView(),
      binding: DriverBinding(),
    ),
    GetPage(
      name: Routes.wallet,
      page: () => const WalletView(),
      binding: WalletBinding(),
    ),
    GetPage(
      name: Routes.myTrips,
      page: () => const MyTripsView(),
      binding: RideBinding(),
    ),
    GetPage(
      name: Routes.availableTrips,
      page: () => const AvailableTripsView(),
      binding: RideBinding(),
    ),
    GetPage(
      name: Routes.tripBids,
      page: () => const TripBidsView(),
      binding: RideBinding(),
    ),
    GetPage(
      name: Routes.tripTracking,
      page: () => const TripTrackingView(),
      binding: RideBinding(),
    ),
    GetPage(
      name: Routes.driverDetails,
      page: () => const DriverDetailsView(),
      binding: RideBinding(),
    ),
    GetPage(
      name: Routes.driverVerification,
      page: () => const DriverVerificationView(),
      binding: DriverVerificationBinding(),
    ),
  ];
}

class Routes {
  Routes._();

  static const login = '/login';
  static const otp = '/otp';
  static const home = '/home';
  static const rideRequest = '/ride-request';
  static const rideMap = '/ride-map';
  static const driverDashboard = '/driver-dashboard';
  static const wallet = '/wallet';
  static const myTrips = '/my-trips';
  static const availableTrips = '/available-trips';
  static const tripBids = '/trip-bids';
  static const tripTracking = '/trip-tracking';
  static const driverDetails = '/driver-details';
  static const driverVerification = '/driver-verification';
}
