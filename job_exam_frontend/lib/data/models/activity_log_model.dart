class ActivityLogModel {
  final int id;
  final int? userId;
  final String userName;
  final String userEmail;
  final String action;
  final String? details;
  final String? ipAddress;
  final String? userAgent;
  final String createdAt;

  ActivityLogModel({
    required this.id,
    this.userId,
    required this.userName,
    required this.userEmail,
    required this.action,
    this.details,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: int.parse(json['id'].toString()),
      userId: json['user_id'] != null ? int.parse(json['user_id'].toString()) : null,
      userName: json['user_name'] ?? 'System',
      userEmail: json['user_email'] ?? '',
      action: json['action'] ?? '',
      details: json['details'],
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'action': action,
      'details': details,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt,
    };
  }
}
