class AssignmentAttachmentModel {
  final String id;
  final String assignmentId;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final int? fileSize;
  final DateTime? uploadedAt;

  AssignmentAttachmentModel({
    required this.id,
    required this.assignmentId,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.fileSize,
    this.uploadedAt,
  });

  factory AssignmentAttachmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentAttachmentModel(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : null,
    );
  }

  String get sizeLabel {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
