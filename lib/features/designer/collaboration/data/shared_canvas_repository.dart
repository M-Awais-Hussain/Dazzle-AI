import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/designer/collaboration/domain/shared_project.dart';

final sharedCanvasRepositoryProvider = Provider<SharedCanvasRepository>((ref) {
  return SharedCanvasRepository(Supabase.instance.client);
});

class SharedCanvasRepository {
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  SharedCanvasRepository(this._client);

  Future<SharedProject> createSharedProject({
    String? requestId,
    required String designerId,
    required String productId,
    required String roomImage,
    required Map<String, dynamic> currentCanvasState,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client.from('designer_shared_projects').insert({
        'request_id': requestId,
        'user_id': userId,
        'designer_id': designerId,
        'product_id': productId,
        'room_image': roomImage,
        'current_canvas_state': currentCanvasState,
        'status': 'pending',
      }).select().single();
      
      final project = SharedProject.fromJson(response);
      
      // Initialize transformation based on canvas state
      await _client.from('designer_project_transformations').insert({
        'project_id': project.id,
        'position_x': currentCanvasState['dx'] ?? 0.0,
        'position_y': currentCanvasState['dy'] ?? 0.0,
        'scale': currentCanvasState['scale'] ?? 1.0,
        'rotation': currentCanvasState['rotation'] ?? 0.0,
        'selected_variant': currentCanvasState['variantImageUrl'],
      });

      return project;
    } catch (e) {
      throw Exception('Failed to create shared project: $e');
    }
  }

  Future<SharedProject?> getSharedProject(String projectId) async {
    try {
      final response = await _client
          .from('designer_shared_projects')
          .select()
          .eq('id', projectId)
          .maybeSingle();
      if (response != null) {
        return SharedProject.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get shared project: $e');
    }
  }

  Future<SharedProject?> getSharedProjectByRequestId(String requestId) async {
    try {
      final response = await _client
          .from('designer_shared_projects')
          .select()
          .eq('request_id', requestId)
          .maybeSingle();
      if (response != null) {
        return SharedProject.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get shared project by request: $e');
    }
  }

  Future<List<SharedProject>> getSharedProjectsForDesigner(String designerId) async {
    try {
      final response = await _client
          .from('designer_shared_projects')
          .select()
          .eq('designer_id', designerId)
          .order('created_at', ascending: false);
      return response.map((json) => SharedProject.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get designer projects: $e');
    }
  }
  
  Future<List<SharedProject>> getSharedProjectsForUser(String userId) async {
    try {
      final response = await _client
          .from('designer_shared_projects')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response.map((json) => SharedProject.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user projects: $e');
    }
  }

  Future<SharedProject> updateProjectStatus(String projectId, String status, {String? finalDesignImage}) async {
    try {
      final updates = <String, dynamic>{'status': status};
      if (finalDesignImage != null) {
        updates['final_design_image'] = finalDesignImage;
      }
      final response = await _client
          .from('designer_shared_projects')
          .update(updates)
          .eq('id', projectId)
          .select()
          .single();
      return SharedProject.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update project status: $e');
    }
  }

  Future<void> saveTransformation(ProjectTransformation transformation) async {
    try {
      await _client.from('designer_project_transformations').upsert({
        'id': transformation.id,
        'project_id': transformation.projectId,
        'position_x': transformation.positionX,
        'position_y': transformation.positionY,
        'scale': transformation.scale,
        'rotation': transformation.rotation,
        'tilt_x': transformation.tiltX,
        'tilt_y': transformation.tiltY,
        'depth_scale': transformation.depthScale,
        'shadow_opacity': transformation.shadowOpacity,
        'shadow_blur': transformation.shadowBlur,
        'shadow_offset_x': transformation.shadowOffsetX,
        'shadow_offset_y': transformation.shadowOffsetY,
        'perspective_origin_y': transformation.perspectiveOriginY,
        'selected_variant': transformation.selectedVariant,
        'layout_type': transformation.layoutType,
      }, onConflict: 'project_id');
    } catch (e) {
      debugPrint('Failed to save transformation: $e');
    }
  }

  Stream<ProjectTransformation?> streamTransformation(String projectId) {
    return _client
        .from('designer_project_transformations')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .map((data) => data.isNotEmpty ? ProjectTransformation.fromJson(data.first) : null);
  }

  void setupBroadcastChannel(
    String projectId, {
    required void Function(ProjectTransformation) onTransformationReceived,
  }) {
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }

    _channel = _client.channel('shared_project_$projectId',
      opts: const RealtimeChannelConfig(
        self: false,
      ),
    );

    _channel!.onBroadcast(
        event: 'transformation_sync',
        callback: (payload) {
          final data = payload['payload'];
          if (data != null) {
            final item = ProjectTransformation.fromJson(data);
            onTransformationReceived(item);
          }
        });

    _channel!.subscribe();
  }

  void broadcastTransformation(ProjectTransformation transformation) {
    if (_channel != null) {
      _channel!.sendBroadcastMessage(
        event: 'transformation_sync',
        payload: transformation.toJson(),
      );
    }
  }

  void dispose() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
  }
}
