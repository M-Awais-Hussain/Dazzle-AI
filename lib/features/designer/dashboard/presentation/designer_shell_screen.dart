import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'designer_dashboard_screen.dart';
import 'package:ayyy/features/designer/portfolio/presentation/portfolio_list_screen.dart';
import 'package:ayyy/features/designer/requests/presentation/designer_requests_screen.dart';
import 'package:ayyy/features/designer/chat/presentation/designer_chat_list_screen.dart';
import 'package:ayyy/features/designer/profile/presentation/designer_profile_screen.dart';

/// Designer Shell — IndexedStack-based state-preserving navigation
class DesignerShellScreen extends ConsumerWidget {
  const DesignerShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(designerTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          DesignerDashboardScreen(),
          PortfolioListScreen(),
          DesignerRequestsScreen(),
          DesignerChatListScreen(),
          DesignerProfileScreen(),
        ],
      ),
      bottomNavigationBar: DazzleBottomNav(
        currentIndex: currentIndex,
      ),
    );
  }
}
