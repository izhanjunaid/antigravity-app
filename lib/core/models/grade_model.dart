class GradeModel {
  final String id;
  final String name;
  final DateTime? createdAt;

  GradeModel({required this.id, required this.name, this.createdAt});

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
