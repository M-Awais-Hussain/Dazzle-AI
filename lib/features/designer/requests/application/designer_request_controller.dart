import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/designer_request_repository.dart';
import '../domain/designer_request.dart';
import 'package:ayyy/features/designer/earnings/data/designer_earnings_repository.dart';
import 'package:ayyy/features/designer/earnings/domain/designer_earning.dart';
import 'package:ayyy/features/user/chat/data/chat_repository.dart';

class DesignerRequestsController extends AsyncNotifier<List<DesignerRequest>> {
  late DesignerRequestRepository _repository;

  @override
  FutureOr<List<DesignerRequest>> build() async {
    _repository = ref.watch(designerRequestRepositoryProvider);
    return _fetchRequests();
  }

  Future<List<DesignerRequest>> _fetchRequests() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    return await _repository.getRequestsForDesigner(user.id);
  }

  Future<bool> acceptRequest(String requestId) async {
    state = const AsyncLoading();
    try {
      await _repository.updateRequestStatus(requestId, 'accepted');
      
      // Auto-create private chat room
      final request = await _repository.getRequestById(requestId);
      if (request != null) {
        await ref.read(chatRepositoryProvider).createOrGetChatRoom(
          userId: request.userId,
          designerId: request.designerId,
          requestId: requestId,
        );
      }

      final refreshed = await _fetchRequests();
      state = AsyncData(refreshed);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    state = const AsyncLoading();
    try {
      await _repository.updateRequestStatus(requestId, 'rejected');
      final refreshed = await _fetchRequests();
      state = AsyncData(refreshed);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateRequestStatus(String requestId, String status) async {
    state = const AsyncLoading();
    try {
      await _repository.updateRequestStatus(requestId, status);
      
      if (status == 'accepted') {
        final request = await _repository.getRequestById(requestId);
        if (request != null) {
          await ref.read(chatRepositoryProvider).createOrGetChatRoom(
            userId: request.userId,
            designerId: request.designerId,
            requestId: requestId,
          );
        }
      }

      // If the request is completed, we automatically credit earnings for tracking!
      if (status == 'completed') {
        final request = state.value?.firstWhere((r) => r.id == requestId);
        if (request != null) {
          final double amount = double.tryParse(request.budget.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 199.0;
          final earning = DesignerEarning(
            id: '',
            designerId: request.designerId,
            requestId: requestId,
            amount: amount,
            status: 'paid',
            createdAt: DateTime.now(),
          );
          await ref.read(designerEarningsRepositoryProvider).recordEarning(earning);
        }
      }

      final refreshed = await _fetchRequests();
      state = AsyncData(refreshed);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> negotiateBudget(String requestId, String newBudget) async {
    state = const AsyncLoading();
    try {
      await _repository.updateRequestBudget(requestId, newBudget);
      final refreshed = await _fetchRequests();
      state = AsyncData(refreshed);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final designerRequestsProvider =
    AsyncNotifierProvider<DesignerRequestsController, List<DesignerRequest>>(() {
  return DesignerRequestsController();
});
