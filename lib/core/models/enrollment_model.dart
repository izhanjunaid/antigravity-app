class EnrollmentModel {
  final String id;
  final String userId;
  final String classId;
  final String roleInClass;
  final DateTime? joinedAt;

  // Joined fields
  final String? userName;
  final String? className;

  EnrollmentModel({
    required this.id,
    required this.userId,
    required this.classId,
    required this.roleInClass,
    this.joinedAt,
    this.userName,
    this.className,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      classId: json['class_id'] as String,
      roleInClass: json['role_in_class'] as String,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      userName: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['name'] as String?
          : null,
      className: json['classes'] != null
          ? (json['classes'] as Map<String, dynamic>)['subject_name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'class_id': classId,
      'role_in_class': roleInClass,
    };
  }
}
