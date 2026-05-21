import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/common/dashboard/data/dashboard_repository.dart';
import 'package:ayyy/features/common/dashboard/domain/project.dart';

class DashboardController extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    return ref.read(dashboardRepositoryProvider).getRecentProjects();
  }
}

final dashboardControllerProvider = AsyncNotifierProvider<DashboardController, List<Project>>(() {
  return DashboardController();
});
