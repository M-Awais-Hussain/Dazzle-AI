import 'package:freezed_annotation/freezed_annotation.dart';

part 'marketplace_profile.freezed.dart';
part 'marketplace_profile.g.dart';

@freezed
abstract class MarketplaceProfile with _$MarketplaceProfile {
  const factory MarketplaceProfile({
    required String id,
    @JsonKey(name: 'store_name') @Default('') String storeName,
    @JsonKey(name: 'store_description') @Default('') String storeDescription,
    @JsonKey(name: 'store_logo_url') String? storeLogoUrl,
    @JsonKey(name: 'store_banner_url') String? storeBannerUrl,
    @JsonKey(name: 'contact_phone') @Default('') String contactPhone,
    @JsonKey(name: 'contact_email') @Default('') String contactEmail,
    @Default('') String address,
    @JsonKey(name: 'social_links') @Default({}) Map<String, dynamic> socialLinks,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MarketplaceProfile;

  factory MarketplaceProfile.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceProfileFromJson(json);
}
