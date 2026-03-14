class AttendanceModel {
  final String id;
  final String classId;
  final String studentId;
  final DateTime date;
  final String status; // present, absent, late

  // Joined fields
  final String? studentName;
  final String? studentPic;

  AttendanceModel({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.date,
    required this.status,
    this.studentName,
    this.studentPic,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      studentId: json['student_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      studentName: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['name'] as String?
          : null,
      studentPic: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['profile_pic'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'student_id': studentId,
      'date': date.toIso8601String().split('T')[0],
      'status': status,
    };
  }

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isLate => status == 'late';
}
