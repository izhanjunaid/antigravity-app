import 'package:ibex_app/core/models/submission_attachment_model.dart';

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? submissionUrl;
  final DateTime? submittedAt;
  final String? grade;
  final String? feedback;

  // Joined fields
  final String? studentName;
  final String? assignmentTitle;
  final List<SubmissionAttachmentModel> attachments;

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.submissionUrl,
    this.submittedAt,
    this.grade,
    this.feedback,
    this.studentName,
    this.assignmentTitle,
    this.attachments = const [],
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      studentId: json['student_id'] as String,
      submissionUrl: json['submission_url'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      grade: json['grade'] as String?,
      feedback: json['feedback'] as String?,
      studentName: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['name'] as String?
          : null,
      assignmentTitle: json['assignments'] != null
          ? (json['assignments'] as Map<String, dynamic>)['title'] as String?
          : null,
      attachments: json['submission_attachments'] != null
          ? (json['submission_attachments'] as List)
              .map((e) => SubmissionAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'student_id': studentId,
      'submission_url': submissionUrl,
    };
  }

  Map<String, dynamic> toGradeJson() {
    return {'grade': grade, 'feedback': feedback};
  }

  bool get isGraded => grade != null;
}
