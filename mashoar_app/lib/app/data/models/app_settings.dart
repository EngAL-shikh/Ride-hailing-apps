class AppSettings {
  final AppConfig app;
  final PricingConfig pricing;
  final DriverConfig driver;
  final RiderConfig rider;
  final PaymentConfig payment;
  final MapsConfig maps;
  final FeaturesConfig features;

  AppSettings({
    required this.app,
    required this.pricing,
    required this.driver,
    required this.rider,
    required this.payment,
    required this.maps,
    required this.features,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      app: AppConfig.fromJson(json['app'] ?? {}),
      pricing: PricingConfig.fromJson(json['pricing'] ?? {}),
      driver: DriverConfig.fromJson(json['driver'] ?? {}),
      rider: RiderConfig.fromJson(json['rider'] ?? {}),
      payment: PaymentConfig.fromJson(json['payment'] ?? {}),
      maps: MapsConfig.fromJson(json['maps'] ?? {}),
      features: FeaturesConfig.fromJson(json['features'] ?? {}),
    );
  }
}

class AppConfig {
  final String name;
  final String supportEmail;
  final String supportPhone;
  final String termsUrl;
  final String privacyUrl;
  final bool maintenanceMode;

  AppConfig({
    required this.name,
    required this.supportEmail,
    required this.supportPhone,
    required this.termsUrl,
    required this.privacyUrl,
    required this.maintenanceMode,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      name: json['app_name'] ?? 'مشوار',
      supportEmail: json['support_email'] ?? '',
      supportPhone: json['support_phone'] ?? '',
      termsUrl: json['terms_url'] ?? '',
      privacyUrl: json['privacy_url'] ?? '',
      maintenanceMode: json['maintenance_mode'] ?? false,
    );
  }
}

class PricingConfig {
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final double surgeMultiplier;
  final double cancellationFee;

  PricingConfig({
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.surgeMultiplier,
    required this.cancellationFee,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    return PricingConfig(
      baseFare: (json['base_fare'] ?? 500).toDouble(),
      perKmRate: (json['per_km_rate'] ?? 100).toDouble(),
      perMinuteRate: (json['per_minute_rate'] ?? 50).toDouble(),
      surgeMultiplier: (json['surge_multiplier'] ?? 1.0).toDouble(),
      cancellationFee: (json['cancellation_fee'] ?? 200).toDouble(),
    );
  }
}

class DriverConfig {
  final double commissionRate;
  final double minRating;
  final int maxConcurrentTrips;
  final int autoAssignTimeout;

  DriverConfig({
    required this.commissionRate,
    required this.minRating,
    required this.maxConcurrentTrips,
    required this.autoAssignTimeout,
  });

  factory DriverConfig.fromJson(Map<String, dynamic> json) {
    return DriverConfig(
      commissionRate: (json['commission_rate'] ?? 0.15).toDouble(),
      minRating: (json['min_rating'] ?? 3.0).toDouble(),
      maxConcurrentTrips: json['max_concurrent_trips'] ?? 1,
      autoAssignTimeout: json['auto_assign_timeout'] ?? 60,
    );
  }
}

class RiderConfig {
  final int maxWaitingTime;
  final int freeCancellationWindow;
  final double maxTripDistance;

  RiderConfig({
    required this.maxWaitingTime,
    required this.freeCancellationWindow,
    required this.maxTripDistance,
  });

  factory RiderConfig.fromJson(Map<String, dynamic> json) {
    return RiderConfig(
      maxWaitingTime: json['max_waiting_time'] ?? 10,
      freeCancellationWindow: json['free_cancellation_window'] ?? 5,
      maxTripDistance: (json['max_trip_distance'] ?? 50).toDouble(),
    );
  }
}

class PaymentConfig {
  final bool cashEnabled;
  final bool walletEnabled;
  final bool cardEnabled;
  final String currency;
  final String currencySymbol;
  final double taxRate;

  PaymentConfig({
    required this.cashEnabled,
    required this.walletEnabled,
    required this.cardEnabled,
    required this.currency,
    required this.currencySymbol,
    required this.taxRate,
  });

  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    return PaymentConfig(
      cashEnabled: json['cash_enabled'] ?? true,
      walletEnabled: json['wallet_enabled'] ?? true,
      cardEnabled: json['card_enabled'] ?? false,
      currency: json['currency'] ?? 'YER',
      currencySymbol: json['currency_symbol'] ?? 'ر.ي',
      taxRate: (json['tax_rate'] ?? 0.0).toDouble(),
    );
  }
}

class MapsConfig {
  final String googleMapsApiKey;
  final double defaultLat;
  final double defaultLng;
  final bool geofencingEnabled;
  final bool enableGoogleDirections;

  MapsConfig({
    required this.googleMapsApiKey,
    required this.defaultLat,
    required this.defaultLng,
    required this.geofencingEnabled,
    required this.enableGoogleDirections,
  });

  factory MapsConfig.fromJson(Map<String, dynamic> json) {
    return MapsConfig(
      googleMapsApiKey: json['google_maps_api_key'] ?? '',
      defaultLat: (json['default_lat'] ?? 15.5527).toDouble(),
      defaultLng: (json['default_lng'] ?? 48.5164).toDouble(),
      geofencingEnabled: json['geofencing_enabled'] ?? false,
      enableGoogleDirections: json['enable_google_directions'] ?? true,
    );
  }
}

class FeaturesConfig {
  final bool rideScheduling;
  final bool favorites;
  final bool tipping;
  final bool sosButton;

  FeaturesConfig({
    required this.rideScheduling,
    required this.favorites,
    required this.tipping,
    required this.sosButton,
  });

  factory FeaturesConfig.fromJson(Map<String, dynamic> json) {
    return FeaturesConfig(
      rideScheduling: json['ride_scheduling'] ?? false,
      favorites: json['favorites'] ?? true,
      tipping: json['tipping'] ?? false,
      sosButton: json['sos_button'] ?? true,
    );
  }
}
