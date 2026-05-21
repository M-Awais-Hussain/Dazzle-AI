import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/designer_profile_repository.dart';
import '../domain/designer_profile.dart';

class DesignerProfileController extends AsyncNotifier<DesignerProfile?> {
  late DesignerProfileRepository _repository;

  @override
  FutureOr<DesignerProfile?> build() async {
    _repository = ref.watch(designerProfileRepositoryProvider);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return await _repository.getProfile(user.id);
  }

  Future<bool> updateBio(String bio) async {
    final current = state.value;
    if (current == null) return false;

    state = const AsyncLoading();
    try {
      final updated = current.copyWith(bio: bio);
      await _repository.updateProfile(updated);
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateAvailability(bool isAvailable) async {
    final current = state.value;
    if (current == null) return false;

    state = const AsyncLoading();
    try {
      final updated = current.copyWith(isAvailable: isAvailable);
      await _repository.updateProfile(updated);
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updatePricing(double price) async {
    final current = state.value;
    if (current == null) return false;

    state = const AsyncLoading();
    try {
      final updated = current.copyWith(consultationPrice: price);
      await _repository.updateProfile(updated);
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateExpertiseAndDetails({
    required int experienceYears,
    required List<String> expertise,
    required List<String> certifications,
    required String responseTime,
  }) async {
    final current = state.value;
    if (current == null) return false;

    state = const AsyncLoading();
    try {
      final updated = current.copyWith(
        experienceYears: experienceYears,
        expertise: expertise,
        certifications: certifications,
        responseTime: responseTime,
      );
      await _repository.updateProfile(updated);
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final designerProfileControllerProvider =
    AsyncNotifierProvider<DesignerProfileController, DesignerProfile?>(() {
  return DesignerProfileController();
});
