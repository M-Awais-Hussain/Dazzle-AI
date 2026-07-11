import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/common/dashboard/domain/project.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class DashboardRepository {
  Future<List<Project>> getRecentProjects();
}

class SupabaseDashboardRepository implements DashboardRepository {
  final SupabaseClient _supabase;

  SupabaseDashboardRepository(this._supabase);

  @override
  Future<List<Project>> getRecentProjects() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Fetch from ai_generations
      final responseGen = await _supabase
          .from('ai_generations')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(10);

      // Fetch from ai_room_generations
      List responseRoom = [];
      try {
        responseRoom = await _supabase
            .from('ai_room_generations')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(10);
      } catch (e) {
        // Fallback if table doesn't exist or empty
        responseRoom = [];
      }

      final listGen = responseGen as List;
      final listRoom = responseRoom;

      final projects = <Project>[];

      for (final json in listGen) {
        projects.add(Project(
          id: json['id'] as String,
          title: json['prompt_used'] as String? ?? 'Design Generation',
          thumbnail: json['generated_image_url'] as String? ?? json['original_image_url'] as String? ?? '',
          updatedAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        ));
      }

      for (final json in listRoom) {
        projects.add(Project(
          id: json['id'] as String,
          title: json['product_description'] as String? ?? 'Room Design',
          thumbnail: json['generated_image'] as String? ?? json['room_image'] as String? ?? '',
          updatedAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        ));
      }

      // Sort by updatedAt descending, and limit to 10
      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (projects.length > 10) {
        return projects.sublist(0, 10);
      }
      return projects;
    } catch (e) {
      throw ServerException('Failed to fetch recent projects: $e');
    }
  }
}

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<List<Project>> getRecentProjects() async {
    await Future.delayed(const Duration(seconds: 1)); // Network simulation
    return [
      Project(
        id: '1',
        title: 'Modern Living Room',
        thumbnail: 'https://via.placeholder.com/150',
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Project(
        id: '2',
        title: 'Minimalist Kitchen',
        thumbnail: 'https://via.placeholder.com/150',
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return SupabaseDashboardRepository(Supabase.instance.client);
});
