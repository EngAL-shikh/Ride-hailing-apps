import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ar': _arTranslations,
        'en': _enTranslations,
      };

  static Map<String, String> _arTranslations = {};
  static Map<String, String> _enTranslations = {};

  static Future<void> loadTranslations() async {
    try {
      final arJson = await rootBundle.loadString('lib/app/translations/ar.json');
      _arTranslations = Map<String, String>.from(json.decode(arJson));

      try {
        final enJson = await rootBundle.loadString('lib/app/translations/en.json');
        _enTranslations = Map<String, String>.from(json.decode(enJson));
      } catch (_) {
        _enTranslations = _arTranslations;
      }
    } catch (_) {
      _arTranslations = {};
      _enTranslations = {};
    }
  }
}
