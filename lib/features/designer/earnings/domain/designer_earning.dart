class DesignerEarning {
  final String id;
  final String designerId;
  final String? requestId;
  final double amount;
  final String status;
  final DateTime createdAt;

  DesignerEarning({
    required this.id,
    required this.designerId,
    this.requestId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory DesignerEarning.fromJson(Map<String, dynamic> json) {
    return DesignerEarning(
      id: json['id'] as String,
      designerId: json['designer_id'] as String,
      requestId: json['request_id'] as String?,
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'designer_id': designerId,
      'request_id': requestId,
      'amount': amount,
      'status': status,
    };
  }

  DesignerEarning copyWith({
    String? id,
    String? designerId,
    String? requestId,
    double? amount,
    String? status,
    DateTime? createdAt,
  }) {
    return DesignerEarning(
      id: id ?? this.id,
      designerId: designerId ?? this.designerId,
      requestId: requestId ?? this.requestId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
