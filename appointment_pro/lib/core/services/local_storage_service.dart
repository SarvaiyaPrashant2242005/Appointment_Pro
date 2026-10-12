import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService([this._preferences]);

  SharedPreferences? _preferences;

  static const String _userProfileKey = 'appointmentpro_user_profile';
  static const String _isRegisteredKey = 'appointmentpro_is_registered';
  static const String _isLoggedInKey = 'appointmentpro_is_logged_in';
  static const String _currentUserEmailKey = 'appointmentpro_current_user_email';

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

  Future<bool> isLoggedIn() async {
    final prefs = await _instance;
    try {
      await prefs.reload();
    } catch (_) {}
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await _instance;
    await prefs.setBool(_isLoggedInKey, value);
  }

  Future<String?> getCurrentUserEmail() async {
    return getString(_currentUserEmailKey);
  }

  Future<String?> getCurrentUserName() async {
    final profileJson = await getUserProfile();
    if (profileJson == null) return null;
    try {
      final data = jsonDecode(profileJson) as Map<String, dynamic>;
      return data['fullName'] as String?;
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final existingProfileJson = await getUserProfile();
    if (existingProfileJson == null) {
      throw Exception('No account found. Please register first.');
    }

    final data = jsonDecode(existingProfileJson) as Map<String, dynamic>;
    final savedEmail = (data['email'] as String? ?? '').trim().toLowerCase();
    final savedPassword = data['password'] as String? ?? '';

    if (savedEmail != email.trim().toLowerCase()) {
      throw Exception('No account registered with this email address.');
    }

    if (savedPassword != password) {
      throw Exception('Incorrect password. Please try again.');
    }

    final prefs = await _instance;
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_currentUserEmailKey, savedEmail);
    return data;
  }

  Future<void> logout() async {
    final prefs = await _instance;
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_currentUserEmailKey);
  }

  Future<void> clearUserProfile() async {
    final prefs = await _instance;
    await prefs.remove(_userProfileKey);
    await prefs.remove(_isRegisteredKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_currentUserEmailKey);
  }
}
