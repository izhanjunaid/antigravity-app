class SectionModel {
  final String id;
  final String gradeId;
  final String name;
  final String? headTeacherId;
  final DateTime? createdAt;

  // Joined fields
  final String? gradeName;
  final String? headTeacherName;

  SectionModel({
    required this.id,
    required this.gradeId,
    required this.name,
    this.headTeacherId,
    this.createdAt,
    this.gradeName,
    this.headTeacherName,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] as String,
      gradeId: json['grade_id'] as String,
      name: json['name'] as String,
      headTeacherId: json['head_teacher_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      gradeName: json['grades'] != null
          ? (json['grades'] as Map<String, dynamic>)['name'] as String?
          : null,
      headTeacherName: json['head_teacher'] != null
          ? (json['head_teacher'] as Map<String, dynamic>)['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grade_id': gradeId,
      'name': name,
      'head_teacher_id': headTeacherId,
    };
  }

  String get displayName => gradeName != null ? '$gradeName - $name' : name;
}
