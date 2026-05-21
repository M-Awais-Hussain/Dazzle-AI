class ServicePackage {
  final String id;
  final String designerId;
  final String name;
  final String description;
  final double price;
  final List<String> features;
  final DateTime createdAt;

  ServicePackage({
    required this.id,
    required this.designerId,
    required this.name,
    required this.description,
    required this.price,
    required this.features,
    required this.createdAt,
  });

  factory ServicePackage.fromJson(Map<String, dynamic> json) {
    return ServicePackage(
      id: json['id'] as String,
      designerId: json['designer_id'] as String,
      name: json['name'] as String? ?? 'Custom Package',
      description: json['description'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      features: (json['features'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'designer_id': designerId,
      'name': name,
      'description': description,
      'price': price,
      'features': features,
    };
  }

  ServicePackage copyWith({
    String? id,
    String? designerId,
    String? name,
    String? description,
    double? price,
    List<String>? features,
    DateTime? createdAt,
  }) {
    return ServicePackage(
      id: id ?? this.id,
      designerId: designerId ?? this.designerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      features: features ?? this.features,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
