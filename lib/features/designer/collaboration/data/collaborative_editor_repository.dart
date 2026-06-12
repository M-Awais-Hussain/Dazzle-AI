import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/designer/collaboration/domain/designer_project.dart';

final collaborativeEditorRepositoryProvider = Provider<CollaborativeEditorRepository>((ref) {
  return CollaborativeEditorRepository(Supabase.instance.client);
});

class CollaborativeEditorRepository {
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  CollaborativeEditorRepository(this._client);

  Future<DesignerProject?> getProjectByRequestId(String requestId) async {
    try {
      final response = await _client
          .from('designer_projects')
          .select()
          .eq('request_id', requestId)
          .maybeSingle();
      if (response != null) {
        return DesignerProject.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get project: $e');
    }
  }

  Future<DesignerProject> createProject({
    required String requestId,
    required String designerId,
    required String userId,
    required String roomImageUrl,
  }) async {
    try {
      final response = await _client.from('designer_projects').insert({
        'request_id': requestId,
        'designer_id': designerId,
        'user_id': userId,
        'room_image_url': roomImageUrl,
      }).select().single();
      return DesignerProject.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  Future<DesignerProject> updateProjectStatus(String projectId, String status, {String? finalImageUrl}) async {
    try {
      final updates = <String, dynamic>{'status': status};
      if (finalImageUrl != null) {
        updates['final_image_url'] = finalImageUrl;
      }
      final response = await _client
          .from('designer_projects')
          .update(updates)
          .eq('id', projectId)
          .select()
          .single();
      return DesignerProject.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  Future<DesignerProjectItem> addItemToProject(String projectId, String productId) async {
    try {
      final response = await _client.from('designer_project_items').insert({
        'project_id': projectId,
        'product_id': productId,
        'position_x': 0.0,
        'position_y': 0.0,
        'scale': 1.0,
        'rotation': 0.0,
      }).select().single();
      return DesignerProjectItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await _client.from('designer_project_items').delete().eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to remove item: $e');
    }
  }

  Future<void> saveItemTransformation(DesignerProjectItem item) async {
    try {
      await _client.from('designer_project_items').update({
        'position_x': item.positionX,
        'position_y': item.positionY,
        'scale': item.scale,
        'rotation': item.rotation,
        'tilt_x': item.tiltX,
        'tilt_y': item.tiltY,
        'depth_scale': item.depthScale,
        'shadow_opacity': item.shadowOpacity,
        'shadow_blur': item.shadowBlur,
        'shadow_offset_x': item.shadowOffsetX,
        'shadow_offset_y': item.shadowOffsetY,
      }).eq('id', item.id);
    } catch (e) {
      // Background save error
      debugPrint('Failed to save item transformation: $e');
    }
  }

  // --- Realtime Broadcast Methods ---

  Stream<List<DesignerProjectItem>> streamProjectItems(String projectId) {
    return _client
        .from('designer_project_items')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .map((data) => data.map((json) => DesignerProjectItem.fromJson(json)).toList());
  }

  void setupBroadcastChannel(
    String projectId, {
    required void Function(DesignerProjectItem) onTransformationReceived,
  }) {
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }

    _channel = _client.channel('project_$projectId',
      opts: const RealtimeChannelConfig(
        self: false,
      ),
    );

    _channel!.onBroadcast(
        event: 'transformation_sync',
        callback: (payload) {
          final data = payload['payload'];
          if (data != null) {
            final item = DesignerProjectItem.fromJson(data);
            onTransformationReceived(item);
          }
        });

    _channel!.subscribe();
  }

  void broadcastTransformation(DesignerProjectItem item) {
    if (_channel != null) {
      _channel!.sendBroadcastMessage(
        event: 'transformation_sync',
        payload: item.toJson(),
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
