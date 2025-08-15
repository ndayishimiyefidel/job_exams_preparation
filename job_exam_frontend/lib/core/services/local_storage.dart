import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../config/env_config.dart';
import '../../data/models/user_model.dart';

class LocalStorageService {
  static const String _userBox = 'user_box';
  static const String _cacheBox = 'cache_box';
  static const String _settingsBox = 'settings_box';

  static Future<void> init() async {
    // Register adapters
    Hive.registerAdapter(UserModelAdapter());

    // Open boxes
    await Hive.openBox<UserModel>(_userBox);
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_settingsBox);
  }

  // User data
  static Future<void> saveUser(UserModel user) async {
    final box = Hive.box<UserModel>(_userBox);
    try {
      await box.put('current_user', user);
      print('✅ [STORAGE] User saved successfully: ${user.name}');
    } catch (e) {
      print('❌ [STORAGE] Error saving user: $e');
      throw Exception('Failed to save user data: $e');
    }
  }

  static UserModel? getUser() {
    final box = Hive.box<UserModel>(_userBox);
    try {
      return box.get('current_user');
    } catch (e) {
      print('❌ [STORAGE] Error getting user: $e');
      // Clear corrupted user data
      try {
        box.delete('current_user');
      } catch (clearError) {
        print('❌ [STORAGE] Error clearing corrupted user data: $clearError');
      }
      return null;
    }
  }

  static Future<void> clearUser() async {
    final box = Hive.box<UserModel>(_userBox);
    await box.delete('current_user');
  }

  // Auth token
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(EnvConfig.authTokenKey, token);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(EnvConfig.authTokenKey);
  }

  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(EnvConfig.authTokenKey);
  }

  // Cache data
  static Future<void> cacheData(String key, Map<String, dynamic> data) async {
    final box = Hive.box(_cacheBox);
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await box.put(key, jsonEncode(cacheData));
  }

  static Map<String, dynamic>? getCachedData(String key) {
    final box = Hive.box(_cacheBox);
    final cached = box.get(key);
    if (cached == null) return null;

    try {
      final cacheData = jsonDecode(cached as String);
      final timestamp = cacheData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if cache is expired (24 hours)
      if (now - timestamp > EnvConfig.cacheExpiryHours * 60 * 60 * 1000) {
        box.delete(key);
        return null;
      }

      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      box.delete(key);
      return null;
    }
  }

  static Future<void> clearCache() async {
    final box = Hive.box(_cacheBox);
    await box.clear();
  }

  // Settings
  static Future<void> saveThemeMode(String themeMode) async {
    final box = Hive.box(_settingsBox);
    await box.put(EnvConfig.themeKey, themeMode);
  }

  static String getThemeMode() {
    final box = Hive.box(_settingsBox);
    return box.get(EnvConfig.themeKey, defaultValue: 'light');
  }

  static Future<void> saveLanguage(String language) async {
    final box = Hive.box(_settingsBox);
    await box.put(EnvConfig.languageKey, language);
  }

  static String getLanguage() {
    final box = Hive.box(_settingsBox);
    return box.get(EnvConfig.languageKey, defaultValue: 'en');
  }

  // Clear all data
  static Future<void> clearAll() async {
    await clearUser();
    await clearAuthToken();
    await clearCache();

    final settingsBox = Hive.box(_settingsBox);
    await settingsBox.clear();
  }
}

// Hive adapter for UserModel
class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    return UserModel(
      id: reader.readInt(),
      name: reader.readString(),
      email: reader.readString(),
      phone: reader.readString(),
      role: reader.readString(),
      createdAt: _parseDateTime(reader.readString()),
      updatedAt: _parseDateTime(reader.readString()),
    );
  }

  DateTime? _parseDateTime(String dateString) {
    if (dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print('⚠️ [STORAGE] Failed to parse date: $dateString, error: $e');
      return null;
    }
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.email);
    writer.writeString(obj.phone ?? '');
    writer.writeString(obj.role);
    writer.writeString(obj.createdAt?.toIso8601String() ?? '');
    writer.writeString(obj.updatedAt?.toIso8601String() ?? '');
  }
}
