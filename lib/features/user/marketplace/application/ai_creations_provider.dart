import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/user/marketplace/data/ai_creation_repository.dart';
import 'package:ayyy/features/user/marketplace/domain/ai_creation.dart';

// --- Filter State Model ---
class AiCreationsFilter {
  final String searchQuery;
  final String sortBy; // 'newest' | 'oldest' | 'product'

  const AiCreationsFilter({
    this.searchQuery = '',
    this.sortBy = 'newest',
  });

  AiCreationsFilter copyWith({
    String? searchQuery,
    String? sortBy,
  }) {
    return AiCreationsFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class AiCreationsFilterNotifier extends Notifier<AiCreationsFilter> {
  @override
  AiCreationsFilter build() {
    return const AiCreationsFilter();
  }

  void update(AiCreationsFilter Function(AiCreationsFilter state) cb) {
    state = cb(state);
  }
}

final aiCreationsFilterProvider =
    NotifierProvider<AiCreationsFilterNotifier, AiCreationsFilter>(() {
  return AiCreationsFilterNotifier();
});

// --- Gallery Notifier State Model ---
class AiCreationsState {
  final List<AiCreation> creations;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasMore;
  final String? errorMessage;
  final int offset;

  const AiCreationsState({
    this.creations = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.offset = 0,
  });

  AiCreationsState copyWith({
    List<AiCreation>? creations,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    String? errorMessage,
    int? offset,
  }) {
    return AiCreationsState(
      creations: creations ?? this.creations,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
      offset: offset ?? this.offset,
    );
  }
}

// --- Main Creations Gallery Provider ---
class AiCreationsNotifier extends AsyncNotifier<AiCreationsState> {
  static const _limit = 10;

  @override
  Future<AiCreationsState> build() async {
    final filter = ref.watch(aiCreationsFilterProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return const AiCreationsState();
    }

    final repo = ref.read(aiCreationRepositoryProvider);
    final list = await repo.getCreations(
      userId: userId,
      limit: _limit,
      offset: 0,
      searchQuery: filter.searchQuery,
      sortBy: filter.sortBy,
    );

    return AiCreationsState(
      creations: list,
      offset: list.length,
      hasMore: list.length >= _limit,
    );
  }

  /// Lazy loading / pagination
  Future<void> fetchNextPage() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isFetchingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncData(currentState.copyWith(isFetchingMore: true));

    try {
      final filter = ref.read(aiCreationsFilterProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final repo = ref.read(aiCreationRepositoryProvider);
      final nextList = await repo.getCreations(
        userId: userId,
        limit: _limit,
        offset: currentState.offset,
        searchQuery: filter.searchQuery,
        sortBy: filter.sortBy,
      );

      state = AsyncData(currentState.copyWith(
        creations: [...currentState.creations, ...nextList],
        offset: currentState.offset + nextList.length,
        hasMore: nextList.length >= _limit,
        isFetchingMore: false,
      ));
    } catch (e) {
      state = AsyncData(currentState.copyWith(
        isFetchingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }

  /// In-memory delete for instant response (Undo Support)
  void removeCreationFromState(String creationId) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedList =
        currentState.creations.where((c) => c.id != creationId).toList();
    state = AsyncData(currentState.copyWith(
      creations: updatedList,
      offset: updatedList.length,
    ));
  }

  /// In-memory insert to restore creation (Undo Support)
  void insertCreationIntoState(int originalIndex, AiCreation creation) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedList = List<AiCreation>.from(currentState.creations);
    if (originalIndex >= 0 && originalIndex <= updatedList.length) {
      updatedList.insert(originalIndex, creation);
    } else {
      updatedList.add(creation);
    }

    state = AsyncData(currentState.copyWith(
      creations: updatedList,
      offset: updatedList.length,
    ));
  }

  /// Full refresh
  Future<void> refresh() async {
    ref.invalidate(recentCreationsProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final aiCreationsProvider =
    AsyncNotifierProvider<AiCreationsNotifier, AiCreationsState>(() {
  return AiCreationsNotifier();
});

// --- Detail Provider ---
final aiCreationDetailProvider =
    FutureProvider.family<AiCreation, String>((ref, id) {
  final repo = ref.read(aiCreationRepositoryProvider);
  return repo.getCreationById(id);
});

// --- Dashboard Feed Provider ---
final recentCreationsProvider = FutureProvider<List<AiCreation>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final repo = ref.read(aiCreationRepositoryProvider);
  return repo.getCreations(userId: userId, limit: 10, offset: 0);
});

// --- Delete Notifier (State Controller with Undo Support) ---
enum DeleteStatus { idle, loading, success, error }

class DeleteCreationState {
  final DeleteStatus status;
  final String? errorMessage;

  const DeleteCreationState({
    this.status = DeleteStatus.idle,
    this.errorMessage,
  });
}

class DeleteCreationNotifier extends Notifier<DeleteCreationState> {
  Timer? _deleteTimer;
  AiCreation? _pendingDeletion;
  int? _pendingIndex;

  @override
  DeleteCreationState build() {
    return const DeleteCreationState();
  }

  /// Triggers a deletion flow. Instantly hides from UI and pops a SnackBar.
  /// If the SnackBar is not undone in 4 seconds, deletes permanently.
  Future<void> initiateDeletion(
    BuildContext context,
    AiCreation creation,
  ) async {
    // If there is a pending deletion already, finalize it immediately
    _finalizePendingDeleteImmediately();

    final creationsState = ref.read(aiCreationsProvider).value;
    if (creationsState == null) return;

    final index = creationsState.creations.indexWhere((c) => c.id == creation.id);
    if (index == -1) return;

    _pendingDeletion = creation;
    _pendingIndex = index;

    // Immediately update UI for instant feel
    ref.read(aiCreationsProvider.notifier).removeCreationFromState(creation.id);

    // Show undo snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted "${creation.productName}" visual',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFFAAA089), // Premium accent color
          onPressed: () {
            _cancelDeletionFlow();
          },
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // Start background timer
    _deleteTimer = Timer(const Duration(seconds: 4), () {
      _executeDatabaseDeletion();
    });
  }

  void _cancelDeletionFlow() {
    _deleteTimer?.cancel();
    _deleteTimer = null;

    if (_pendingDeletion != null && _pendingIndex != null) {
      // Re-insert into list
      ref
          .read(aiCreationsProvider.notifier)
          .insertCreationIntoState(_pendingIndex!, _pendingDeletion!);
      _pendingDeletion = null;
      _pendingIndex = null;
    }
  }

  void _finalizePendingDeleteImmediately() {
    if (_deleteTimer != null && _deleteTimer!.isActive) {
      _deleteTimer?.cancel();
      _deleteTimer = null;
      _executeDatabaseDeletion();
    }
  }

  Future<void> _executeDatabaseDeletion() async {
    final target = _pendingDeletion;
    if (target == null) return;

    _pendingDeletion = null;
    _pendingIndex = null;

    state = const DeleteCreationState(status: DeleteStatus.loading);

    try {
      final repo = ref.read(aiCreationRepositoryProvider);
      await repo.deleteCreation(
        target.id,
        imageUrlsToDelete: [
          target.generatedImageUrl,
          target.roomImageUrl,
          target.transparentProductUrl,
        ],
      );

      state = const DeleteCreationState(status: DeleteStatus.success);
      ref.invalidate(recentCreationsProvider);
    } catch (e) {
      state = DeleteCreationState(
        status: DeleteStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final deleteCreationProvider =
    NotifierProvider<DeleteCreationNotifier, DeleteCreationState>(() {
  return DeleteCreationNotifier();
});
