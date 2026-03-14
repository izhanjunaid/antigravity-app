class ClassModel {
  final String id;
  final String sectionId;
  final String subjectName;
  final String teacherId;
  final String classCode;
  final DateTime? createdAt;

  // Joined fields
  final String? sectionName;
  final String? gradeName;
  final String? teacherName;
  final int? studentCount;

  ClassModel({
    required this.id,
    required this.sectionId,
    required this.subjectName,
    required this.teacherId,
    required this.classCode,
    this.createdAt,
    this.sectionName,
    this.gradeName,
    this.teacherName,
    this.studentCount,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    // Handle nested section → grade
    String? sectionName;
    String? gradeName;
    if (json['sections'] != null) {
      final section = json['sections'] as Map<String, dynamic>;
      sectionName = section['name'] as String?;
      if (section['grades'] != null) {
        gradeName =
            (section['grades'] as Map<String, dynamic>)['name'] as String?;
      }
    }

    // Handle nested teacher
    String? teacherName;
    if (json['teacher'] != null) {
      teacherName =
          (json['teacher'] as Map<String, dynamic>)['name'] as String?;
    }

    return ClassModel(
      id: json['id'] as String,
      sectionId: json['section_id'] as String,
      subjectName: json['subject_name'] as String,
      teacherId: json['teacher_id'] as String,
      classCode: json['class_code'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      sectionName: sectionName,
      gradeName: gradeName,
      teacherName: teacherName,
      studentCount: json['student_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section_id': sectionId,
      'subject_name': subjectName,
      'teacher_id': teacherId,
    };
  }

  String get displayTitle =>
      gradeName != null ? '$gradeName - $subjectName' : subjectName;

  String get subtitle => sectionName != null ? 'Section $sectionName' : '';
}
