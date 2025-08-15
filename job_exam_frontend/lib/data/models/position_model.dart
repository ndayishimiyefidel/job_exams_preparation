class PositionModel {
  final int id;
  final String title;
  final String description;
  final int examCount;
  final int freeExamCount;
  final int paidExamCount;
  final String createdAt;

  PositionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.examCount,
    required this.freeExamCount,
    required this.paidExamCount,
    required this.createdAt,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      examCount: int.parse(json['exam_count'].toString()),
      freeExamCount: int.parse(json['free_exam_count'].toString()),
      paidExamCount: int.parse(json['paid_exam_count'].toString()),
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'exam_count': examCount,
      'free_exam_count': freeExamCount,
      'paid_exam_count': paidExamCount,
      'created_at': createdAt,
    };
  }
}

class PositionsResponseModel {
  final List<PositionModel> positions;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  PositionsResponseModel({
    required this.positions,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory PositionsResponseModel.fromJson(Map<String, dynamic> json) {
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
    
    final positions = data.map((position) => PositionModel.fromJson(position)).toList();

    return PositionsResponseModel(
      positions: positions,
      currentPage: int.parse(pagination['current_page'].toString()),
      totalPages: int.parse(pagination['total_pages'].toString()),
      totalItems: int.parse(pagination['total_records']?.toString() ?? pagination['total_items'].toString()),
      itemsPerPage: int.parse(pagination['per_page']?.toString() ?? pagination['items_per_page'].toString()),
    );
  }
}
