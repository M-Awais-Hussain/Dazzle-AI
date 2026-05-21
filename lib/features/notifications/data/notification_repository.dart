import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/notification.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Stream<List<AppNotification>> watchNotifications(String userId);
}

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _supabase;

  SupabaseNotificationRepository(this._supabase);

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*, profiles:profiles!sender_id(full_name, avatar_url)')
          .eq('receiver_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch notifications: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('receiver_id', userId);
    } catch (e) {
      throw ServerException('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    final controller = StreamController<List<AppNotification>>();

    Future<void> fetchAndEmit() async {
      try {
        final data = await getNotifications(userId);
        if (!controller.isClosed) {
          controller.add(data);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Initial fetch
    fetchAndEmit();

    // Set up Supabase Realtime channel to listen to all notification changes for this receiver
    final channelName = 'notifications_receiver_$userId';
    final channel = _supabase.channel('public:notifications:$channelName');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: userId,
      ),
      callback: (payload) {
        // Trigger a fresh, joined fetch on any realtime update
        fetchAndEmit();
      },
    ).subscribe();

    // Clean up channel and controller on cancel
    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(Supabase.instance.client);
});
