import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/auth/application/auth_controller.dart';
import 'package:ayyy/features/auth/domain/app_user.dart';

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(currentUserProfileProvider).value;
});
