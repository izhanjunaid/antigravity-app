import 'package:ibex_app/core/models/assignment_attachment_model.dart';

class AssignmentModel {
  final String id;
  final String classId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? attachmentUrl;
  final DateTime? createdAt;
  final int? points;
  final String? topic;

  // Joined fields
  final String? className;
  final int? submissionCount;
  final int? totalStudents;
  final List<AssignmentAttachmentModel> attachments;

  AssignmentModel({
    required this.id,
    required this.classId,
    required this.title,
    this.description,
    this.dueDate,
    this.attachmentUrl,
    this.createdAt,
    this.points,
    this.topic,
    this.className,
    this.submissionCount,
    this.totalStudents,
    this.attachments = const [],
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      points: json['points'] as int?,
      topic: json['topic'] as String?,
      className: json['classes'] != null
          ? (json['classes'] as Map<String, dynamic>)['subject_name'] as String?
          : null,
      submissionCount: json['submission_count'] as int?,
      totalStudents: json['total_students'] as int?,
      attachments: json['assignment_attachments'] != null
          ? (json['assignment_attachments'] as List)
              .map((e) => AssignmentAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'attachment_url': attachmentUrl,
      'points': points,
      'topic': topic,
    };
  }

  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now());

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }
}
