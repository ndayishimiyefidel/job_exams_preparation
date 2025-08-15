import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../../data/models/questions_response_model.dart';
import '../services/local_storage.dart';
import '../config/env_config.dart';

class QuestionsService {
  static Future<QuestionsResponseModel> getQuestions({
    int page = 1,
    int limit = 10,
    String search = '',
    int examId = 0,
  }) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (examId > 0) {
        queryParams['exam_id'] = examId.toString();
      }

      final uri = Uri.parse('${EnvConfig.adminQuestionsEndpoint}/read.php')
          .replace(queryParameters: queryParams);

      print('🔍 [QUESTIONS] Requesting: $uri');
      print('🔍 [QUESTIONS] Token: ${token.substring(0, 10)}...');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('🔍 [QUESTIONS] Response status: ${response.statusCode}');
      print('🔍 [QUESTIONS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return QuestionsResponseModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load questions');
        }
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getQuestions: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createQuestion({
    required int examId,
    required String questionText,
    required int questionMarks,
    required List<Map<String, dynamic>> choices,
    String? questionImageUrl,
  }) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http
          .post(
            Uri.parse('${EnvConfig.adminQuestionsEndpoint}/create.php'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'exam_id': examId,
              'question_text': questionText,
              'question_marks': questionMarks,
              'choices': choices,
              if (questionImageUrl != null)
                'questionImageUrl': questionImageUrl,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to create question');
        }
      } else {
        throw Exception('Failed to create question: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createQuestion: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateQuestion({
    required int id,
    required int examId,
    required String questionText,
    required int questionMarks,
    required List<Map<String, dynamic>> choices,
    String? questionImageUrl,
  }) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http
          .put(
            Uri.parse('${EnvConfig.adminQuestionsEndpoint}/update.php'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'id': id,
              'exam_id': examId,
              'question_text': questionText,
              'question_marks': questionMarks,
              'choices': choices,
              if (questionImageUrl != null)
                'questionImageUrl': questionImageUrl,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to update question');
        }
      } else {
        throw Exception('Failed to update question: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateQuestion: $e');
      rethrow;
    }
  }

  static Future<void> deleteQuestion(int id) async {
    try {
      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('${EnvConfig.adminQuestionsEndpoint}/delete.php?id=$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete question');
        }
      } else {
        throw Exception('Failed to delete question: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteQuestion: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> uploadBulkQuestions({
    required int examId,
    required PlatformFile file,
  }) async {
    try {
      print('🔍 [UPLOAD] Starting bulk upload for exam: $examId');
      print('🔍 [UPLOAD] File name: ${file.name}');
      print('🔍 [UPLOAD] File size: ${file.size}');
      print('🔍 [UPLOAD] Has bytes: ${file.bytes != null}');
      // Don't check file.path on web as it throws an exception

      final token = await LocalStorageService.getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${EnvConfig.adminQuestionsEndpoint}/upload_bulk.php'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['exam_id'] = examId.toString();

      // Handle file upload for both web and mobile
      if (file.bytes != null) {
        print('🔍 [UPLOAD] Using bytes for web upload');
        // Web - use bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else {
        // Try to use path for mobile/desktop, but catch web exceptions
        try {
          if (file.path != null) {
            print('🔍 [UPLOAD] Using path for mobile/desktop upload');
            // Mobile/Desktop - use file path
            request.files.add(
              await http.MultipartFile.fromPath('file', file.path!),
            );
          } else {
            print('🔍 [UPLOAD] No file data available');
            throw Exception('No file data available');
          }
        } catch (e) {
          print('🔍 [UPLOAD] Path access failed (likely web): $e');
          print('🔍 [UPLOAD] No file data available');
          throw Exception('No file data available');
        }
      }

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to upload questions');
        }
      } else {
        throw Exception('Failed to upload questions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in uploadBulkQuestions: $e');
      rethrow;
    }
  }
}
