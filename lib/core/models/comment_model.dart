class CommentModel {
  final String id;
  final String classId;
  final String? postId;
  final String? classworkId;
  final String userId;
  final String? parentId;
  final String content;
  final DateTime? createdAt;

  // Joined fields
  final String? userName;
  final String? userRole;
  final String? userPic;

  CommentModel({
    required this.id,
    required this.classId,
    this.postId,
    this.classworkId,
    required this.userId,
    this.parentId,
    required this.content,
    this.createdAt,
    this.userName,
    this.userRole,
    this.userPic,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      postId: json['post_id'] as String?,
      classworkId: json['classwork_id'] as String?,
      userId: json['user_id'] as String,
      parentId: json['parent_id'] as String?,
      content: json['content'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      userName: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['name'] as String?
          : null,
      userRole: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['role'] as String?
          : null,
      userPic: json['users'] != null
          ? (json['users'] as Map<String, dynamic>)['profile_pic'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'post_id': postId,
      'classwork_id': classworkId,
      'user_id': userId,
      'parent_id': parentId,
      'content': content,
    };
  }
}
