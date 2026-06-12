import 'package:freezed_annotation/freezed_annotation.dart';

part 'designer_project.freezed.dart';
part 'designer_project.g.dart';

@freezed
abstract class DesignerProject with _$DesignerProject {
  const factory DesignerProject({
    required String id,
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'designer_id') required String designerId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'room_image_url') required String roomImageUrl,
    @JsonKey(name: 'final_image_url') String? finalImageUrl,
    @Default('draft') String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _DesignerProject;

  factory DesignerProject.fromJson(Map<String, dynamic> json) =>
      _$DesignerProjectFromJson(json);
}

@freezed
abstract class DesignerProjectItem with _$DesignerProjectItem {
  const factory DesignerProjectItem({
    required String id,
    @JsonKey(name: 'project_id') required String projectId,
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'position_x') @Default(0.0) double positionX,
    @JsonKey(name: 'position_y') @Default(0.0) double positionY,
    @Default(1.0) double scale,
    @Default(0.0) double rotation,
    @JsonKey(name: 'tilt_x') @Default(0.0) double tiltX,
    @JsonKey(name: 'tilt_y') @Default(0.0) double tiltY,
    @JsonKey(name: 'depth_scale') @Default(1.0) double depthScale,
    @JsonKey(name: 'shadow_opacity') @Default(0.3) double shadowOpacity,
    @JsonKey(name: 'shadow_blur') @Default(8.0) double shadowBlur,
    @JsonKey(name: 'shadow_offset_x') @Default(0.0) double shadowOffsetX,
    @JsonKey(name: 'shadow_offset_y') @Default(4.0) double shadowOffsetY,
    @JsonKey(name: 'layer_order') @Default(0) int layerOrder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _DesignerProjectItem;

  factory DesignerProjectItem.fromJson(Map<String, dynamic> json) =>
      _$DesignerProjectItemFromJson(json);
}
