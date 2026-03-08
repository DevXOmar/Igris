import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for navigation
class NavigationState {
  final int currentIndex;
  
  NavigationState({
    required this.currentIndex,
  });
  
  NavigationState copyWith({
    int? currentIndex,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

/// Notifier for managing bottom navigation state
/// Tracks which tab is currently selected
class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    return NavigationState(currentIndex: 0);
  }
  
  /// Set the current navigation index
  void setIndex(int index) {
    if (state.currentIndex != index) {
      state = state.copyWith(currentIndex: index);
    }
  }
  
  /// Navigate to home screen
  void goToHome() => setIndex(0);
  
  /// Navigate to calendar screen
  void goToCalendar() => setIndex(1);
  
  /// Navigate to domains screen
  void goToDomains() => setIndex(2);
  
  /// Navigate to settings screen
  void goToSettings() => setIndex(3);

  /// Navigate to rival board screen
  void goToRivalBoard() => setIndex(4);
}

/// Global provider for navigation state
final navigationProvider = NotifierProvider<NavigationNotifier, NavigationState>(() {
  return NavigationNotifier();
});

