import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/designer_earnings_repository.dart';
import '../domain/designer_earning.dart';
import 'package:ayyy/features/designer/requests/application/designer_request_controller.dart';

class DesignerEarningsController extends AsyncNotifier<List<DesignerEarning>> {
  late DesignerEarningsRepository _repository;

  @override
  FutureOr<List<DesignerEarning>> build() async {
    _repository = ref.watch(designerEarningsRepositoryProvider);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    return await _repository.getEarnings(user.id);
  }

  Future<bool> recordCustomEarning(double amount, String notes) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    state = const AsyncLoading();
    try {
      final earning = DesignerEarning(
        id: '',
        designerId: user.id,
        amount: amount,
        status: 'paid',
        createdAt: DateTime.now(),
      );
      await _repository.recordEarning(earning);
      final refreshed = await _repository.getEarnings(user.id);
      state = AsyncData(refreshed);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final designerEarningsProvider =
    AsyncNotifierProvider<DesignerEarningsController, List<DesignerEarning>>(() {
  return DesignerEarningsController();
});

// --- Dynamic Studio Dashboard Statistics ---
class DesignerStats {
  final double totalEarnings;
  final double monthlyRevenue;
  final int activeProjects;
  final int pendingRequests;
  final double averageRating;

  DesignerStats({
    required this.totalEarnings,
    required this.monthlyRevenue,
    required this.activeProjects,
    required this.pendingRequests,
    required this.averageRating,
  });
}

final designerReviewsProvider = FutureProvider<List<double>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  try {
    final response = await Supabase.instance.client
        .from('designer_reviews')
        .select('rating')
        .eq('designer_id', user.id);
    return (response as List<dynamic>).map((e) => (e['rating'] as num).toDouble()).toList();
  } catch (_) {
    return [];
  }
});

final designerStatsProvider = Provider<DesignerStats>((ref) {
  final earnings = ref.watch(designerEarningsProvider).value ?? [];
  final requests = ref.watch(designerRequestsProvider).value ?? [];
  final ratings = ref.watch(designerReviewsProvider).value ?? [];

  double total = 0.0;
  double monthly = 0.0;
  final now = DateTime.now();

  for (final e in earnings) {
    total += e.amount;
    // Check if the earning occurred in the current calendar month
    if (e.createdAt.year == now.year && e.createdAt.month == now.month) {
      monthly += e.amount;
    }
  }

  final activeCount = requests.where((r) => r.status == 'accepted' || r.status == 'in_progress').length;
  final pendingCount = requests.where((r) => r.status == 'pending').length;

  double avgRating = 0.0;
  if (ratings.isNotEmpty) {
    double sum = ratings.reduce((a, b) => a + b);
    avgRating = double.parse((sum / ratings.length).toStringAsFixed(1));
  }

  return DesignerStats(
    totalEarnings: total,
    monthlyRevenue: monthly,
    activeProjects: activeCount,
    pendingRequests: pendingCount,
    averageRating: avgRating,
  );
});
