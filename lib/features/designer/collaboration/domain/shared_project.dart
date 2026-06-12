import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_project.freezed.dart';
part 'shared_project.g.dart';

@freezed
abstract class SharedProject with _$SharedProject {
  const factory SharedProject({
    required String id,
    @JsonKey(name: 'request_id') String? requestId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'designer_id') required String designerId,
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'room_image') required String roomImage,
    @JsonKey(name: 'current_canvas_state') Map<String, dynamic>? currentCanvasState,
    @JsonKey(name: 'final_design_image') String? finalDesignImage,
    @Default('pending') String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _SharedProject;

  factory SharedProject.fromJson(Map<String, dynamic> json) =>
      _$SharedProjectFromJson(json);
}

@freezed
abstract class ProjectTransformation with _$ProjectTransformation {
  const factory ProjectTransformation({
    required String id,
    @JsonKey(name: 'project_id') required String projectId,
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
    @JsonKey(name: 'perspective_origin_y') @Default(0.0) double perspectiveOriginY,
    @JsonKey(name: 'selected_variant') String? selectedVariant,
    @JsonKey(name: 'layout_type') String? layoutType,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ProjectTransformation;

  factory ProjectTransformation.fromJson(Map<String, dynamic> json) =>
      _$ProjectTransformationFromJson(json);
}
