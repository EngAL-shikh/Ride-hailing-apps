import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../models/app_settings.dart';
import 'package:get_storage/get_storage.dart';

/// Service to fetch and cache app settings from dashboard
class SettingsService extends GetxService {
  final ApiClient apiClient = Get.find();
  final storage = GetStorage();
  
  final settings = Rx<AppSettings?>(null);
  final isLoading = false.obs;
  final lastFetchTime = Rx<DateTime?>(null);

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadCachedSettings();
    await fetchSettings();
  }

  /// Load settings from local cache
  Future<void> loadCachedSettings() async {
    try {
      final cached = storage.read('app_settings');
      if (cached != null) {
        settings.value = AppSettings.fromJson(cached);
        lastFetchTime.value = DateTime.tryParse(storage.read('settings_fetch_time') ?? '');
      }
    } catch (e) {
      Get.log('[SettingsService] Error loading cached settings: $e', isError: true);
    }
  }

  /// Fetch fresh settings from API
  Future<void> fetchSettings() async {
    try {
      isLoading.value = true;
      
      final data = await apiClient.getJson('/settings');
      settings.value = AppSettings.fromJson(data);
      
      // Cache locally
      await storage.write('app_settings', data);
      await storage.write('settings_fetch_time', DateTime.now().toIso8601String());
      
      lastFetchTime.value = DateTime.now();
      
      Get.log('[SettingsService] Settings fetched successfully');
    } catch (e) {
      Get.log('[SettingsService] Error fetching settings: $e', isError: true);
      // Use cached settings as fallback
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if settings need refresh (older than 1 hour)
  bool get needsRefresh {
    if (lastFetchTime.value == null) return true;
    return DateTime.now().difference(lastFetchTime.value!).inHours >= 1;
  }

  // Getters for common settings
  String get appName => settings.value?.app.name ?? 'مشوار';
  String get supportEmail => settings.value?.app.supportEmail ?? '';
  String get supportPhone => settings.value?.app.supportPhone ?? '';
  
  double get baseFare => settings.value?.pricing.baseFare ?? 500.0;
  double get perKmRate => settings.value?.pricing.perKmRate ?? 100.0;
  double get perMinuteRate => settings.value?.pricing.perMinuteRate ?? 50.0;
  double get surgeMultiplier => settings.value?.pricing.surgeMultiplier ?? 1.0;
  double get cancellationFee => settings.value?.pricing.cancellationFee ?? 200.0;
  
  double get driverCommissionRate => settings.value?.driver.commissionRate ?? 0.15;
  double get minDriverRating => settings.value?.driver.minRating ?? 3.0;
  
  int get maxWaitingTime => settings.value?.rider.maxWaitingTime ?? 10;
  int get freeCancellationWindow => settings.value?.rider.freeCancellationWindow ?? 5;
  
  bool get cashEnabled => settings.value?.payment.cashEnabled ?? true;
  bool get walletEnabled => settings.value?.payment.walletEnabled ?? true;
  bool get cardEnabled => settings.value?.payment.cardEnabled ?? false;
  String get currency => settings.value?.payment.currency ?? 'YER';
  String get currencySymbol => settings.value?.payment.currencySymbol ?? 'ر.ي';
  
  String get googleMapsApiKey => settings.value?.maps.googleMapsApiKey ?? '';
  bool get enableDirections => settings.value?.maps.enableGoogleDirections ?? true;
  
  bool get rideSchedulingEnabled => settings.value?.features.rideScheduling ?? false;
  bool get favoritesEnabled => settings.value?.features.favorites ?? true;
  bool get tippingEnabled => settings.value?.features.tipping ?? false;
  bool get sosButtonEnabled => settings.value?.features.sosButton ?? true;
}
