class PortfolioProject {
  final String id;
  final String designerId;
  final String title;
  final String description;
  final List<String> images;
  final List<String> styleTags;
  final double pricing;
  final String projectType;
  final String completionTime;
  final DateTime createdAt;

  PortfolioProject({
    required this.id,
    required this.designerId,
    required this.title,
    required this.description,
    required this.images,
    required this.styleTags,
    required this.pricing,
    required this.projectType,
    required this.completionTime,
    required this.createdAt,
  });

  factory PortfolioProject.fromJson(Map<String, dynamic> json) {
    String sanitize(String? input) {
      if (input == null) return '';
      return input.replaceAll(RegExp(r'\bAI\b', caseSensitive: false), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    return PortfolioProject(
      id: json['id'] as String,
      designerId: json['designer_id'] as String,
      title: sanitize(json['title'] as String? ?? 'Untitled Project').isEmpty ? 'Untitled Project' : sanitize(json['title'] as String? ?? 'Untitled Project'),
      description: sanitize(json['description'] as String? ?? ''),
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      styleTags: (json['style_tags'] as List<dynamic>?)?.map((e) => sanitize(e as String)).where((e) => e.isNotEmpty).toList() ?? [],
      pricing: double.tryParse(json['pricing']?.toString() ?? '') ?? 0.0,
      projectType: sanitize(json['project_type'] as String? ?? 'Interior Design').isEmpty ? 'Interior Design' : sanitize(json['project_type'] as String? ?? 'Interior Design'),
      completionTime: json['completion_time'] as String? ?? 'Unknown',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'designer_id': designerId,
      'title': title,
      'description': description,
      'images': images,
      'style_tags': styleTags,
      'pricing': pricing,
      'project_type': projectType,
      'completion_time': completionTime,
    };
  }

  PortfolioProject copyWith({
    String? id,
    String? designerId,
    String? title,
    String? description,
    List<String>? images,
    List<String>? styleTags,
    double? pricing,
    String? projectType,
    String? completionTime,
    DateTime? createdAt,
  }) {
    return PortfolioProject(
      id: id ?? this.id,
      designerId: designerId ?? this.designerId,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      styleTags: styleTags ?? this.styleTags,
      pricing: pricing ?? this.pricing,
      projectType: projectType ?? this.projectType,
      completionTime: completionTime ?? this.completionTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
