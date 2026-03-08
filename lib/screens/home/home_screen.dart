import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/navigation_provider.dart';
import '../calendar/calendar_screen.dart';
import '../domains/domains_screen.dart';
import '../rival_board/rival_board_screen.dart';
import '../settings/settings_screen.dart';
import 'home_content.dart';

/// Main screen with bottom navigation bar
/// Refactored with Igris styling for navigation bar
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    
    return Scaffold(
      body: _getBody(navState.currentIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          border: Border(
            top: BorderSide(
              color: AppColors.neonBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.backgroundSurface,
          currentIndex: navState.currentIndex,
          onTap: (index) => ref.read(navigationProvider.notifier).setIndex(index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.neonBlue,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: TextStyle(
            color: AppColors.bloodRed,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Domains',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radar),
              label: 'Rivals',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return const HomeContent();
      case 1:
        return const CalendarScreen();
      case 2:
        return const DomainsScreen();
      case 3:
        return const SettingsScreen();
      case 4:
        return const RivalBoardScreen();
      default:
        return const HomeContent();
    }
  }
}
