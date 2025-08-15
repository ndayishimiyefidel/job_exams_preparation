class DashboardStatsModel {
  final int totalPositions;
  final int totalExams;
  final int totalQuestions;
  final int totalUsers;
  final int recentPositions;
  final int recentExams;
  final int recentQuestions;
  final int recentUsers;

  DashboardStatsModel({
    required this.totalPositions,
    required this.totalExams,
    required this.totalQuestions,
    required this.totalUsers,
    required this.recentPositions,
    required this.recentExams,
    required this.recentQuestions,
    required this.recentUsers,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalPositions: int.parse(json['total_positions'].toString()),
      totalExams: int.parse(json['total_exams'].toString()),
      totalQuestions: int.parse(json['total_questions'].toString()),
      totalUsers: int.parse(json['total_users'].toString()),
      recentPositions: int.parse(json['recent_positions'].toString()),
      recentExams: int.parse(json['recent_exams'].toString()),
      recentQuestions: int.parse(json['recent_questions'].toString()),
      recentUsers: int.parse(json['recent_users'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_positions': totalPositions,
      'total_exams': totalExams,
      'total_questions': totalQuestions,
      'total_users': totalUsers,
      'recent_positions': recentPositions,
      'recent_exams': recentExams,
      'recent_questions': recentQuestions,
      'recent_users': recentUsers,
    };
  }
}
