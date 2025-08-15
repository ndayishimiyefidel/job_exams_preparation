import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageUtils {
  // Clear all Hive boxes
  static Future<void> clearAllHiveData() async {
    try {
      print('🧹 [STORAGE] Clearing all Hive data...');

      // Clear user box
      if (Hive.isBoxOpen('user_box')) {
        final userBox = Hive.box('user_box');
        await userBox.clear();
        print('✅ [STORAGE] User box cleared');
      } else {
        print('⚠️ [STORAGE] User box not open, skipping');
      }

      // Clear cache box
      if (Hive.isBoxOpen('cache_box')) {
        final cacheBox = Hive.box('cache_box');
        await cacheBox.clear();
        print('✅ [STORAGE] Cache box cleared');
      } else {
        print('⚠️ [STORAGE] Cache box not open, skipping');
      }

      // Clear settings box
      if (Hive.isBoxOpen('settings_box')) {
        final settingsBox = Hive.box('settings_box');
        await settingsBox.clear();
        print('✅ [STORAGE] Settings box cleared');
      } else {
        print('⚠️ [STORAGE] Settings box not open, skipping');
      }

      print('✅ [STORAGE] All Hive data cleared successfully');
    } catch (e) {
      print('❌ [STORAGE] Error clearing Hive data: $e');
    }
  }

  // Clear SharedPreferences
  static Future<void> clearSharedPreferences() async {
    try {
      print('🧹 [STORAGE] Clearing SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ [STORAGE] SharedPreferences cleared');
    } catch (e) {
      print('❌ [STORAGE] Error clearing SharedPreferences: $e');
    }
  }

  // Clear all storage (Hive + SharedPreferences)
  static Future<void> clearAllStorage() async {
    print('🧹 [STORAGE] Starting complete storage cleanup...');
    await clearAllHiveData();
    await clearSharedPreferences();
    print('✅ [STORAGE] Complete storage cleanup finished');
  }

  // Reset app to fresh state
  static Future<void> resetApp() async {
    print('🔄 [STORAGE] Resetting app to fresh state...');
    await clearAllStorage();
    print('✅ [STORAGE] App reset complete - all data cleared');
  }

  // Check storage health
  static Future<void> checkStorageHealth() async {
    try {
      print('🔍 [STORAGE] Checking storage health...');

      // Check user box
      if (Hive.isBoxOpen('user_box')) {
        final userBox = Hive.box('user_box');
        final userCount = userBox.length;
        print('📊 [STORAGE] User box: $userCount items');
      } else {
        print('📊 [STORAGE] User box: not open');
      }

      // Check cache box
      if (Hive.isBoxOpen('cache_box')) {
        final cacheBox = Hive.box('cache_box');
        final cacheCount = cacheBox.length;
        print('📊 [STORAGE] Cache box: $cacheCount items');
      } else {
        print('📊 [STORAGE] Cache box: not open');
      }

      // Check settings box
      if (Hive.isBoxOpen('settings_box')) {
        final settingsBox = Hive.box('settings_box');
        final settingsCount = settingsBox.length;
        print('📊 [STORAGE] Settings box: $settingsCount items');
      } else {
        print('📊 [STORAGE] Settings box: not open');
      }

      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefsKeys = prefs.getKeys();
      print('📊 [STORAGE] SharedPreferences: ${prefsKeys.length} keys');

      print('✅ [STORAGE] Storage health check complete');
    } catch (e) {
      print('❌ [STORAGE] Error checking storage health: $e');
    }
  }
}
