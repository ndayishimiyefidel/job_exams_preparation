import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../services/local_storage.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/models/activity_log_model.dart';

class DashboardService {
  static Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${EnvConfig.baseUrl}/admin/dashboard/stats.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return DashboardStatsModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load dashboard stats');
        }
      } else {
        throw Exception(
            'Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading dashboard stats: $e');
    }
  }

  static Future<List<ActivityLogModel>> getRecentActivity() async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${EnvConfig.baseUrl}/admin/dashboard/recent_activity.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> activitiesJson = data['data'];
          return activitiesJson
              .map((json) => ActivityLogModel.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load recent activity');
        }
      } else {
        throw Exception(
            'Failed to load recent activity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading recent activity: $e');
    }
  }
}
