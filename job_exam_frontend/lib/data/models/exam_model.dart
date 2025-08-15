class ExamModel {
  final int id;
  final String title;
  final int positionId;
  final String positionTitle;
  final bool isPaid;
  final double price;
  final int questionCount;
  final String createdAt;

  ExamModel({
    required this.id,
    required this.title,
    required this.positionId,
    required this.positionTitle,
    required this.isPaid,
    required this.price,
    required this.questionCount,
    required this.createdAt,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      positionId: int.parse(json['position_id'].toString()),
      positionTitle: json['position_title'] ?? '',
      isPaid: json['is_paid'] ?? false,
      price: double.parse(json['price'].toString()),
      questionCount: int.parse(json['question_count'].toString()),
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'position_id': positionId,
      'position_title': positionTitle,
      'is_paid': isPaid,
      'price': price,
      'question_count': questionCount,
      'created_at': createdAt,
    };
  }
}

class ExamsResponseModel {
  final List<ExamModel> exams;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  ExamsResponseModel({
    required this.exams,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory ExamsResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle both response structures:
    // 1. Admin API: json['data'] is directly a List
    // 2. Public API: json['data']['data'] is the List, json['data']['pagination'] has pagination info

    List<dynamic> data;
    Map<String, dynamic> pagination;

    if (json['data'] is List) {
      // Admin API structure
      data = json['data'] as List;
      pagination = {
        'current_page': json['current_page'],
        'total_pages': json['total_pages'],
        'total_items': json['total_items'],
        'items_per_page': json['items_per_page'],
      };
    } else if (json['data'] is Map) {
      // Public API structure
      final dataMap = json['data'] as Map<String, dynamic>;
      data = dataMap['data'] as List;
      pagination = dataMap['pagination'] as Map<String, dynamic>;
    } else {
      throw Exception('Invalid data structure in response');
    }

    final exams = data.map((exam) => ExamModel.fromJson(exam)).toList();

    return ExamsResponseModel(
      exams: exams,
      currentPage: int.parse(pagination['current_page'].toString()),
      totalPages: int.parse(pagination['total_pages'].toString()),
      totalItems: int.parse(pagination['total_records']?.toString() ??
          pagination['total_items'].toString()),
      itemsPerPage: int.parse(pagination['per_page']?.toString() ??
          pagination['items_per_page'].toString()),
    );
  }
}
