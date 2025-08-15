import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/position_model.dart';
import '../config/env_config.dart';
import '../services/local_storage.dart';

class PositionsService {
  // Public method for users browsing positions without authentication
  static Future<PositionsResponseModel> getPublicPositions({
    int page = 1,
    int limit = 10,
    String search = '',
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse(EnvConfig.positionsEndpoint)
          .replace(queryParameters: queryParams);

      print('🔍 [POSITIONS] Making public request to: ${uri.toString()}');
      print('🔍 [POSITIONS] Base URL: ${EnvConfig.baseUrl}');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - server not responding');
        },
      );

      print('🔍 [POSITIONS] Response status: ${response.statusCode}');
      print('🔍 [POSITIONS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('🔍 [POSITIONS] Parsing response data');
          try {
            return PositionsResponseModel.fromJson(data);
          } catch (e) {
            print('🔴 [POSITIONS] Error parsing position data: $e');
            rethrow;
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch positions');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('🔴 [POSITIONS] Error fetching positions: $e');
      rethrow;
    }
  }

  // Admin method for admin dashboard with authentication
  static Future<PositionsResponseModel> getPositions({
    int page = 1,
    int limit = 10,
    String search = '',
  }) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse(EnvConfig.adminPositionsEndpoint + '/read.php')
          .replace(queryParameters: queryParams);

      print('🔍 [POSITIONS] Making admin request to: ${uri.toString()}');
      print('🔍 [POSITIONS] Base URL: ${EnvConfig.baseUrl}');
      print('🔍 [POSITIONS] Admin URL: ${EnvConfig.adminUrl}');
      print('🔍 [POSITIONS] Token: ${token.substring(0, 10)}...');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - server not responding');
        },
      );

      print('🔍 [POSITIONS] Response status: ${response.statusCode}');
      print('🔍 [POSITIONS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('🔍 [POSITIONS] Parsing response data');
          try {
            return PositionsResponseModel.fromJson(data);
          } catch (e) {
            print('🔴 [POSITIONS] Error parsing position data: $e');
            rethrow;
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch positions');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('🔴 [POSITIONS] Error fetching positions: $e');
      rethrow;
    }
  }

  static Future<PositionModel> createPosition({
    required String title,
    required String description,
  }) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse(EnvConfig.adminPositionsEndpoint + '/create.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return PositionModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create position');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('🔴 [POSITIONS] Error creating position: $e');
      rethrow;
    }
  }

  static Future<PositionModel> updatePosition({
    required int id,
    required String title,
    required String description,
  }) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse(EnvConfig.adminPositionsEndpoint + '/update.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id': id,
          'title': title,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return PositionModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update position');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('🔴 [POSITIONS] Error updating position: $e');
      rethrow;
    }
  }

  static Future<bool> deletePosition(int id) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final uri = Uri.parse(EnvConfig.adminPositionsEndpoint + '/delete.php')
          .replace(queryParameters: {'id': id.toString()});

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('🔴 [POSITIONS] Error deleting position: $e');
      rethrow;
    }
  }
}
