import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/navigation_provider.dart';
import '../calendar/calendar_screen.dart';
import '../domains/domains_screen.dart';
import '../profile/system_profile_screen.dart';
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
      body: Stack(
        children: [
          _getBody(navState.currentIndex),
          // Persistent settings icon in the top-right corner, aligned with
          // the AppBar actions area of each inner screen.
          if (navState.currentIndex != 4)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, right: 4),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.neonBlue,
                    iconSize: 22,
                    tooltip: 'Settings',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
              icon: Icon(Icons.radar),
              label: 'Rivals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.military_tech),
              label: 'Profile',
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
        return const RivalBoardScreen();
      case 4:
        return const SystemProfileScreen();
      default:
        return const HomeContent();
    }
  }
}
