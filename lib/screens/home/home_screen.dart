import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart';
import '../calendar/calendar_screen.dart';
import '../domains/domains_screen.dart';
import '../settings/settings_screen.dart';
import 'home_content.dart';

/// Main screen with bottom navigation bar
/// Handles navigation between Home, Calendar, Domains, and Settings
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    
    return Scaffold(
      body: _getBody(navState.currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navState.currentIndex,
        onTap: (index) => ref.read(navigationProvider.notifier).setIndex(index),
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
        ],
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
      default:
        return const HomeContent();
    }
  }
}
