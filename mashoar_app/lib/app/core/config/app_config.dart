class AppConfig {
  // Backend base URL. For Android emulator use 10.0.2.2 instead of localhost.
  static const String apiBaseUrl =
     String.fromEnvironment('API_BASE_URL', defaultValue: 'http://YOUR_LOCAL_IP:8000');
     // String.fromEnvironment('API_BASE_URL', defaultValue: 'https://your-domain.com');

  // Google Maps API Key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
}

