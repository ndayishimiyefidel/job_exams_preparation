import 'question_model.dart';

class QuestionsResponseModel {
  final List<QuestionModel> questions;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int limit;

  QuestionsResponseModel({
    required this.questions,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.limit,
  });

  factory QuestionsResponseModel.fromJson(Map<String, dynamic> json) {
    return QuestionsResponseModel(
      questions: (json['data'] as List<dynamic>)
          .map((question) => QuestionModel.fromJson(question))
          .toList(),
      totalRecords: int.parse((json['total_records'] ?? '0').toString()),
      totalPages: int.parse((json['total_pages'] ?? '0').toString()),
      currentPage: int.parse((json['current_page'] ?? '1').toString()),
      limit: int.parse((json['limit'] ?? '10').toString()),
    );
  }
}
