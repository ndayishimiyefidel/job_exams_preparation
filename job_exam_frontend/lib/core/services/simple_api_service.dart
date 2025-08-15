import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:job_exam_frontend/core/services/local_storage.dart';
import '../config/env_config.dart';

class SimpleApiService {
  static const String baseUrl = EnvConfig.baseUrl;

  // Authentication
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.loginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Login failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Login API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password, String? phone) async {
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.registerEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }),
      );

      print('Register API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Registration failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Register API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.logoutEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Logout API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Logout failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Logout API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Positions
  static Future<Map<String, dynamic>> getPositions(
      {int? page, int? limit, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse('${EnvConfig.positionsEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print(
          'Get Positions API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get positions: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Get Positions API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Exams
  static Future<Map<String, dynamic>> getExams(
      {int? positionId, int? page, int? limit, bool? freeOnly}) async {
    try {
      final queryParams = <String, String>{};
      if (positionId != null)
        queryParams['position_id'] = positionId.toString();
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (freeOnly != null) queryParams['free_only'] = freeOnly.toString();

      final uri = Uri.parse('${EnvConfig.examsEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print(
          'Get Exams API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get exams: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Get Exams API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Questions
  static Future<Map<String, dynamic>> getQuestions(int examId) async {
    try {
      final uri = Uri.parse('${EnvConfig.questionsEndpoint}')
          .replace(queryParameters: {'exam_id': examId.toString()});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print(
          'Get Questions API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get questions: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Get Questions API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Submit Results
  static Future<Map<String, dynamic>> submitResults(
      Map<String, dynamic> results) async {
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.submitResultsEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(results),
      );

      print(
          'Submit Results API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to submit results: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Submit Results API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Resources
  static Future<Map<String, dynamic>> getResources(
      {int? positionId, int? page, int? limit}) async {
    try {
      final queryParams = <String, String>{};
      if (positionId != null)
        queryParams['position_id'] = positionId.toString();
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('${EnvConfig.resourcesEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print(
          'Get Resources API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get resources: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Get Resources API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Payments
  static Future<Map<String, dynamic>> processPayment(
      Map<String, dynamic> paymentData) async {
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.paymentsEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(paymentData),
      );

      print(
          'Process Payment API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Payment failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Process Payment API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Profile Management
  static Future<Map<String, dynamic>> updateProfile(
      String name, String email, String? phone) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.put(
        Uri.parse('${EnvConfig.baseUrl}/api/profile/update.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }),
      );

      print(
          'Update Profile API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to update profile: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Update Profile API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.put(
        Uri.parse('${EnvConfig.baseUrl}/api/profile/change_password.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      print(
          'Change Password API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to change password: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Change Password API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.delete(
        Uri.parse('${EnvConfig.baseUrl}/api/profile/delete_account.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password': password,
        }),
      );

      print(
          'Delete Account API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to delete account: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Delete Account API Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
