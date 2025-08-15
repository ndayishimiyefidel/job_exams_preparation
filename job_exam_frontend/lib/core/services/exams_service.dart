import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/exam_model.dart';
import '../config/env_config.dart';
import '../services/local_storage.dart';

class ExamsService {
  // Public method for users browsing exams without authentication
  static Future<ExamsResponseModel> getPublicExams({
    int? positionId,
    int page = 1,
    int limit = 10,
    bool freeOnly = false,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (positionId != null) {
        queryParams['position_id'] = positionId.toString();
      }

      if (freeOnly) {
        queryParams['free_only'] = 'true';
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(EnvConfig.examsEndpoint)
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print(
          '🔍 [EXAMS] Public API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return ExamsResponseModel.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load exams: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EXAMS] Error: $e');
      throw Exception('Failed to load exams: $e');
    }
  }

  // Admin method for admin dashboard with authentication
  static Future<ExamsResponseModel> getExams({
    int? positionId,
    int page = 1,
    int limit = 10,
    bool freeOnly = false,
    String? search,
  }) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (positionId != null) {
        queryParams['position_id'] = positionId.toString();
      }

      if (freeOnly) {
        queryParams['free_only'] = 'true';
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(EnvConfig.adminExamsEndpoint + '/read.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print(
          '🔍 [EXAMS] Admin API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return ExamsResponseModel.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load exams: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [EXAMS] Error: $e');
      throw Exception('Failed to load exams: $e');
    }
  }

  static Future<ExamsResponseModel> getExamsByPosition(
    int positionId, {
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    return getPublicExams(
      positionId: positionId,
      page: page,
      limit: limit,
      search: search,
    );
  }

  static Future<ExamsResponseModel> getFreeExams({
    int? positionId,
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    return getPublicExams(
      positionId: positionId,
      page: page,
      limit: limit,
      freeOnly: true,
      search: search,
    );
  }

  static Future<ExamModel> createExam({
    required int positionId,
    required String title,
    required bool isPaid,
    required double price,
  }) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final baseUrl = EnvConfig.baseUrl;
      final adminUrl = '$baseUrl/admin';
      final uri = Uri.parse('$adminUrl/exams/create.php');

      final response = await http
          .post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'position_id': positionId,
          'title': title,
          'is_paid': isPaid,
          'price': price,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ExamModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create exam');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ [EXAMS] Create error: $e');
      rethrow;
    }
  }

  static Future<ExamModel> updateExam({
    required int id,
    required int positionId,
    required String title,
    required bool isPaid,
    required double price,
  }) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final baseUrl = EnvConfig.baseUrl;
      final adminUrl = '$baseUrl/admin';
      final uri = Uri.parse('$adminUrl/exams/update.php');

      final response = await http
          .put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id': id,
          'position_id': positionId,
          'title': title,
          'is_paid': isPaid,
          'price': price,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ExamModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update exam');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ [EXAMS] Update error: $e');
      rethrow;
    }
  }

  static Future<void> deleteExam(int id) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final baseUrl = EnvConfig.baseUrl;
      final adminUrl = '$baseUrl/admin';
      final uri = Uri.parse('$adminUrl/exams/delete.php')
          .replace(queryParameters: {'id': id.toString()});

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete exam');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ [EXAMS] Delete error: $e');
      rethrow;
    }
  }
}
