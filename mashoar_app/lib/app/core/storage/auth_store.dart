import 'package:get_storage/get_storage.dart';

// Simple auth storage using GetStorage.
class AuthStore {
  static final GetStorage _box = GetStorage();

  static const _kToken = 'auth_token';
  static const _kUserType = 'user_type';
  static const _kPhone = 'phone';
  static const _kName = 'user_name'; // Store user name
  static const _kDriverOnline = 'driver_online'; // Store driver online status

  static String? get token => _box.read<String>(_kToken);
  static String? get userType => _box.read<String>(_kUserType); // rider|driver
  static String? get phone => _box.read<String>(_kPhone);
  static String? get name => _box.read<String>(_kName);
  static bool get driverOnline => _box.read<bool>(_kDriverOnline) ?? false;

  static Future<void> saveSession({
    required String token,
    required String userType,
    required String phone,
    String? name,
  }) async {
    await _box.write(_kToken, token);
    await _box.write(_kUserType, userType);
    await _box.write(_kPhone, phone);
    if (name != null) {
      await _box.write(_kName, name);
    }
  }

  static Future<void> setDriverOnline(bool online) async {
    await _box.write(_kDriverOnline, online);
  }

  static Future<void> clear() async {
    await _box.remove(_kToken);
    await _box.remove(_kUserType);
    await _box.remove(_kPhone);
    await _box.remove(_kName);
    await _box.remove(_kDriverOnline);
  }
}

