import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/auth/application/auth_controller.dart';
import 'package:ayyy/features/common/dashboard/application/dashboard_controller.dart';

class UserStudioStats {
  final int aiCreationsCount;
  final int activeConsultationsCount;
  final int pendingBookingsCount;
  final int activeOrdersCount;

  UserStudioStats({
    required this.aiCreationsCount,
    required this.activeConsultationsCount,
    required this.pendingBookingsCount,
    required this.activeOrdersCount,
  });

  factory UserStudioStats.zero() {
    return UserStudioStats(
      aiCreationsCount: 0,
      activeConsultationsCount: 0,
      pendingBookingsCount: 0,
      activeOrdersCount: 0,
    );
  }

  UserStudioStats copyWith({
    int? aiCreationsCount,
    int? activeConsultationsCount,
    int? pendingBookingsCount,
    int? activeOrdersCount,
  }) {
    return UserStudioStats(
      aiCreationsCount: aiCreationsCount ?? this.aiCreationsCount,
      activeConsultationsCount: activeConsultationsCount ?? this.activeConsultationsCount,
      pendingBookingsCount: pendingBookingsCount ?? this.pendingBookingsCount,
      activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount,
    );
  }
}

Future<UserStudioStats> _fetchStats(SupabaseClient supabase, String userId) async {
  // Fetch Design Generations count
  final aiResponse = await supabase
      .from('ai_generations')
      .select('id')
      .eq('user_id', userId);
  final aiCount = (aiResponse as List).length;

  // Fetch Room Generations count
  int aiRoomCount = 0;
  try {
    final aiRoomResponse = await supabase
        .from('ai_room_generations')
        .select('id')
        .eq('user_id', userId);
    aiRoomCount = (aiRoomResponse as List).length;
  } catch (e) {
    // Fallback if table doesn't exist yet
    aiRoomCount = 0;
  }

  // Fetch Design Creations count
  int aiCreationCount = 0;
  try {
    final aiCreationResponse = await supabase
        .from('ai_creations')
        .select('id')
        .eq('user_id', userId);
    aiCreationCount = (aiCreationResponse as List).length;
  } catch (e) {
    aiCreationCount = 0;
  }

  // Fetch Designer Requests
  final requestsResponse = await supabase
      .from('designer_requests')
      .select('status')
      .eq('user_id', userId);
  
  final requestsList = requestsResponse as List;
  final activeConsultations = requestsList
      .where((r) => r['status'] == 'accepted' || r['status'] == 'in_progress')
      .length;
  final pendingBookings = requestsList
      .where((r) => r['status'] == 'pending')
      .length;

  // Fetch Marketplace Orders
  final ordersResponse = await supabase
      .from('orders')
      .select('status')
      .eq('user_id', userId);
  final ordersList = ordersResponse as List;
  final activeOrders = ordersList
      .where((o) => o['status'] != 'Delivered' && o['status'] != 'Cancelled')
      .length;

  return UserStudioStats(
    aiCreationsCount: aiCount + aiRoomCount + aiCreationCount,
    activeConsultationsCount: activeConsultations,
    pendingBookingsCount: pendingBookings,
    activeOrdersCount: activeOrders,
  );
}

final userStudioStatsStreamProvider = StreamProvider<UserStudioStats>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final userId = profileAsync.value?.id;
  if (userId == null) {
    return Stream.value(UserStudioStats.zero());
  }

  final supabase = Supabase.instance.client;
  final controller = StreamController<UserStudioStats>();

  Future<void> fetchAndEmit() async {
    try {
      final stats = await _fetchStats(supabase, userId);
      if (!controller.isClosed) {
        controller.add(stats);
      }
    } catch (e, st) {
      if (!controller.isClosed) {
        controller.addError(e, st);
      }
    }
  }

  // Initial fetch
  fetchAndEmit();

  // Listen to channels
  final channelName = 'user_studio_stats_$userId';
  final channel = supabase.channel('public:studio_stats:$channelName');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'ai_generations',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: userId,
    ),
    callback: (payload) {
      fetchAndEmit();
      ref.invalidate(dashboardControllerProvider);
    },
  ).onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'ai_room_generations',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: userId,
    ),
    callback: (payload) {
      fetchAndEmit();
      ref.invalidate(dashboardControllerProvider);
    },
  ).onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'ai_creations',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: userId,
    ),
    callback: (payload) {
      fetchAndEmit();
      ref.invalidate(dashboardControllerProvider);
    },
  ).onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'designer_requests',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: userId,
    ),
    callback: (payload) {
      fetchAndEmit();
    },
  ).onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'orders',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: userId,
    ),
    callback: (payload) {
      fetchAndEmit();
    },
  ).subscribe();

  controller.onCancel = () {
    supabase.removeChannel(channel);
    controller.close();
  };

  return controller.stream;
});
