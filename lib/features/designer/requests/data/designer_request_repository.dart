import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/designer_request.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class DesignerRequestRepository {
  Future<List<DesignerRequest>> getRequestsForDesigner(String designerId);
  Future<List<DesignerRequest>> getRequestsForUser(String userId);
  Future<DesignerRequest?> getRequestById(String requestId);
  Future<void> createRequest(DesignerRequest request);
  Future<void> updateRequestStatus(String requestId, String status);
  Future<void> updateRequestBudget(String requestId, String newBudget);
}

class SupabaseDesignerRequestRepository implements DesignerRequestRepository {
  final SupabaseClient _supabase;

  SupabaseDesignerRequestRepository(this._supabase);

  @override
  Future<DesignerRequest?> getRequestById(String requestId) async {
    try {
      final response = await _supabase
          .from('designer_requests')
          .select('*, profiles:profiles!user_id(full_name, avatar_url)')
          .eq('id', requestId)
          .maybeSingle();

      if (response == null) return null;
      return DesignerRequest.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<DesignerRequest>> getRequestsForDesigner(String designerId) async {
    try {
      // Query designer_requests and join profiles (user info)
      final response = await _supabase
          .from('designer_requests')
          .select('*, profiles:profiles!user_id(full_name, avatar_url)')
          .eq('designer_id', designerId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((e) => DesignerRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<DesignerRequest>> getRequestsForUser(String userId) async {
    try {
      final response = await _supabase
          .from('designer_requests')
          .select('*, profiles:profiles!designer_id(full_name, avatar_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((e) => DesignerRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> createRequest(DesignerRequest request) async {
    try {
      await _supabase.from('designer_requests').insert({
        'user_id': request.userId,
        'designer_id': request.designerId,
        'budget': request.budget,
        'preferences': request.preferences,
        'room_type': request.roomType,
        'attachments': request.attachments,
        'access_level': request.accessLevel,
        'status': request.status,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _supabase
          .from('designer_requests')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateRequestBudget(String requestId, String newBudget) async {
    try {
      await _supabase
          .from('designer_requests')
          .update({'budget': newBudget, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

final designerRequestRepositoryProvider = Provider<DesignerRequestRepository>((ref) {
  return SupabaseDesignerRequestRepository(Supabase.instance.client);
});
