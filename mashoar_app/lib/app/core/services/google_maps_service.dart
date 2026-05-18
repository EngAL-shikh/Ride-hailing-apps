import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../config/app_config.dart';
import '../../data/services/settings_service.dart';

class GoogleMapsService extends GetxService {
  final SettingsService _settings = Get.find<SettingsService>();

  /// Fetch directions from Google Maps API
  Future<List<LatLng>> getDirections(LatLng origin, LatLng destination) async {
    // 1. Check Kill Switch
    if (!_settings.enableDirections) {
      Get.log('[GoogleMapsService] Directions disabled via Kill Switch. Returning straight line.');
      return [origin, destination];
    }

    final apiKey = _settings.googleMapsApiKey.isNotEmpty 
        ? _settings.googleMapsApiKey 
        : AppConfig.googleMapsApiKey;

    if (apiKey.isEmpty) {
      Get.log('[GoogleMapsService] No API Key provided. Returning straight line.', isError: true);
      return [origin, destination];
    }

    final url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'key=$apiKey';

    try {
      Get.log('[GoogleMapsService] Fetching directions: ${origin.latitude},${origin.longitude} -> ${destination.latitude},${destination.longitude}');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final points = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(points);
        } else {
          Get.log('[GoogleMapsService] Google API Error: ${data['status']} - ${data['error_message'] ?? ''}', isError: true);
        }
      } else {
        Get.log('[GoogleMapsService] HTTP Error: ${response.statusCode}', isError: true);
        Get.log('[GoogleMapsService] Response: ${response.body}', isError: true);
      }
    } catch (e) {
      Get.log('[GoogleMapsService] Exception: $e', isError: true);
    }

    // Fallback to straight line
    return [origin, destination];
  }

  /// Decode Google Polyline algorithm
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    Get.log('[GoogleMapsService] Decoded ${points.length} points from polyline');
    return points;
  }
}
