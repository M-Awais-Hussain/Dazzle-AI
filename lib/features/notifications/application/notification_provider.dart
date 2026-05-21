import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification.dart';
import '../data/notification_repository.dart';
import 'package:ayyy/features/auth/application/auth_controller.dart';

/// Realtime notification stream provider
final notificationStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final userId = profileAsync.value?.id;
  if (userId == null) {
    return const Stream.empty();
  }

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchNotifications(userId);
});

/// Unread badge count provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationStreamProvider);
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

/// Controller for notification actions
class NotificationController extends AsyncNotifier<void> {
  late NotificationRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(notificationRepositoryProvider);
  }

  Future<void> markAsRead(String id) async {
    state = const AsyncLoading();
    try {
      await _repository.markAsRead(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile == null) return;

    state = const AsyncLoading();
    try {
      await _repository.markAllAsRead(profile.id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, void>(() {
  return NotificationController();
});
