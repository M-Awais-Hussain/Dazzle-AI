class DesignerProfile {
  final String id;
  final String bio;
  final int experienceYears;
  final List<String> expertise;
  final Map<String, dynamic> socialLinks;
  final List<String> certifications;
  final bool isAvailable;
  final double consultationPrice;
  final String responseTime;

  DesignerProfile({
    required this.id,
    required this.bio,
    required this.experienceYears,
    required this.expertise,
    required this.socialLinks,
    required this.certifications,
    required this.isAvailable,
    required this.consultationPrice,
    required this.responseTime,
  });

  factory DesignerProfile.fromJson(Map<String, dynamic> json) {
    return DesignerProfile(
      id: json['id'] as String,
      bio: json['bio'] as String? ?? 'Luxury minimalist interior architect & design specialist.',
      experienceYears: json['experience_years'] as int? ?? 0,
      expertise: (json['expertise'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      socialLinks: json['social_links'] as Map<String, dynamic>? ?? {},
      certifications: (json['certifications'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isAvailable: json['is_available'] as bool? ?? true,
      consultationPrice: double.tryParse(json['consultation_price']?.toString() ?? '') ?? 0.0,
      responseTime: json['response_time'] as String? ?? 'Within a few hours',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bio': bio,
      'experience_years': experienceYears,
      'expertise': expertise,
      'social_links': socialLinks,
      'certifications': certifications,
      'is_available': isAvailable,
      'consultation_price': consultationPrice,
      'response_time': responseTime,
    };
  }

  DesignerProfile copyWith({
    String? id,
    String? bio,
    int? experienceYears,
    List<String>? expertise,
    Map<String, dynamic>? socialLinks,
    List<String>? certifications,
    bool? isAvailable,
    double? consultationPrice,
    String? responseTime,
  }) {
    return DesignerProfile(
      id: id ?? this.id,
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      expertise: expertise ?? this.expertise,
      socialLinks: socialLinks ?? this.socialLinks,
      certifications: certifications ?? this.certifications,
      isAvailable: isAvailable ?? this.isAvailable,
      consultationPrice: consultationPrice ?? this.consultationPrice,
      responseTime: responseTime ?? this.responseTime,
    );
  }
}
