class AnnouncementModel {
  final String id;
  final String? classId;
  final String? sectionId;
  final String posterId;
  final String content;
  final String? attachmentUrl;
  final DateTime? createdAt;

  // Joined fields
  final String? posterName;
  final String? posterRole;
  final String? posterPic;
  final String? className;

  AnnouncementModel({
    required this.id,
    this.classId,
    this.sectionId,
    required this.posterId,
    required this.content,
    this.attachmentUrl,
    this.createdAt,
    this.posterName,
    this.posterRole,
    this.posterPic,
    this.className,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      classId: json['class_id'] as String?,
      sectionId: json['section_id'] as String?,
      posterId: json['poster_id'] as String,
      content: json['content'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      posterName: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['name'] as String?
          : null,
      posterRole: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['role'] as String?
          : null,
      posterPic: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['profile_pic'] as String?
          : null,
      className: json['classes'] != null
          ? (json['classes'] as Map<String, dynamic>)['subject_name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'section_id': sectionId,
      'poster_id': posterId,
      'content': content,
      'attachment_url': attachmentUrl,
    };
  }

  bool get isClassLevel => classId != null;
  bool get isSectionLevel => sectionId != null && classId == null;
  bool get isGlobal => classId == null && sectionId == null;
}
