class FeeModel {
  final String id;
  final String studentId;
  final double amount;
  final DateTime dueDate;
  final String status; // paid, unpaid, overdue
  final DateTime? createdAt;

  FeeModel({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.createdAt,
  });

  factory FeeModel.fromJson(Map<String, dynamic> json) {
    return FeeModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'amount': amount,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'status': status,
    };
  }

  bool get isPaid => status == 'paid';
  bool get isUnpaid => status == 'unpaid';
  bool get isOverdue => status == 'overdue';
}
