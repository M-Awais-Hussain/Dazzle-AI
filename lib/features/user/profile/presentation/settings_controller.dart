import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/auth/application/auth_controller.dart';
import 'package:ayyy/features/auth/data/auth_repository.dart';

class SettingsState {
  final bool isUpdatingName;
  final bool isUpdatingPassword;
  final String? nameError;
  final String? passwordError;
  final String? nameSuccess;
  final String? passwordSuccess;

  SettingsState({
    this.isUpdatingName = false,
    this.isUpdatingPassword = false,
    this.nameError,
    this.passwordError,
    this.nameSuccess,
    this.passwordSuccess,
  });

  SettingsState copyWith({
    bool? isUpdatingName,
    bool? isUpdatingPassword,
    String? nameError,
    String? passwordError,
    String? nameSuccess,
    String? passwordSuccess,
  }) {
    return SettingsState(
      isUpdatingName: isUpdatingName ?? this.isUpdatingName,
      isUpdatingPassword: isUpdatingPassword ?? this.isUpdatingPassword,
      nameError: nameError,
      passwordError: passwordError,
      nameSuccess: nameSuccess,
      passwordSuccess: passwordSuccess,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => SettingsState();

  void reset() {
    state = SettingsState();
  }

  Future<void> updateName(String newName) async {
    if (newName.trim().isEmpty) {
      state = state.copyWith(nameError: 'Name cannot be empty.');
      return;
    }
    
    state = state.copyWith(isUpdatingName: true, nameError: null, nameSuccess: null);
    try {
      final user = ref.read(currentUserProfileProvider).value;
      if (user == null) {
        throw Exception('No active user session found.');
      }
      
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateProfileName(user.id, newName.trim());
      
      // Force Riverpod to update user profile
      ref.invalidate(currentUserProfileProvider);
      await ref.read(currentUserProfileProvider.future);
      
      state = state.copyWith(isUpdatingName: false, nameSuccess: 'Name updated successfully!');
    } catch (e) {
      state = state.copyWith(isUpdatingName: false, nameError: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updatePassword(String newPassword, String confirmPassword) async {
    if (newPassword.isEmpty) {
      state = state.copyWith(passwordError: 'New password cannot be empty.');
      return;
    }
    if (newPassword.length < 6) {
      state = state.copyWith(passwordError: 'Password must be at least 6 characters.');
      return;
    }
    if (newPassword != confirmPassword) {
      state = state.copyWith(passwordError: 'Passwords do not match.');
      return;
    }

    state = state.copyWith(isUpdatingPassword: true, passwordError: null, passwordSuccess: null);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updatePassword(newPassword);
      state = state.copyWith(isUpdatingPassword: false, passwordSuccess: 'Password updated successfully!');
    } catch (e) {
      state = state.copyWith(isUpdatingPassword: false, passwordError: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final settingsControllerProvider = NotifierProvider<SettingsController, SettingsState>(() {
  return SettingsController();
});
