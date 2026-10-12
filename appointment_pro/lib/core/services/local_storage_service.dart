import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService([this._preferences]);

  SharedPreferences? _preferences;

  static const String _userProfileKey = 'appointmentpro_user_profile';
  static const String _isRegisteredKey = 'appointmentpro_is_registered';

  Future<SharedPreferences> get _instance async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<bool> setString(String key, String value) async {
    return (await _instance).setString(key, value);
  }

  Future<String?> getString(String key) async {
    return (await _instance).getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return (await _instance).setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    return (await _instance).getBool(key);
  }

  Future<bool> remove(String key) async {
    return (await _instance).remove(key);
  }

  Future<bool> clear() async {
    return (await _instance).clear();
  }

  Future<void> saveUserProfile(String json) async {
    final prefs = await _instance;
    await prefs.setString(_userProfileKey, json);
    await prefs.setBool(_isRegisteredKey, true);
  }

  Future<String?> getUserProfile() async {
    return getString(_userProfileKey);
  }

  Future<bool> isEmailRegistered(String email) async {
    final existingProfileJson = await getUserProfile();
    if (existingProfileJson == null) return false;
    try {
      final data = jsonDecode(existingProfileJson);
      if (data is Map<String, dynamic>) {
        final existingEmail = data['email'] as String? ?? '';
        return existingEmail.trim().toLowerCase() == email.trim().toLowerCase();
      }
    } catch (_) {}
    return false;
  }

  Future<bool> isRegistered() async {
    return await getBool(_isRegisteredKey) ?? false;
  }

  Future<void> clearUserProfile() async {
    final prefs = await _instance;
    await prefs.remove(_userProfileKey);
    await prefs.remove(_isRegisteredKey);
  }
}
