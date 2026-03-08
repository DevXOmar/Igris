import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/rival.dart';
import '../services/rival_service.dart';

class RivalState {
  final List<Rival> rivals;

  RivalState({required this.rivals});

  RivalState copyWith({List<Rival>? rivals}) =>
      RivalState(rivals: rivals ?? this.rivals);
}

class RivalNotifier extends Notifier<RivalState> {
  final RivalService _service = RivalService();

  @override
  RivalState build() {
    return RivalState(rivals: _service.getAllRivals());
  }

  void _reload() => state = RivalState(rivals: _service.getAllRivals());

  Future<void> addRival(Rival rival) async {
    await _service.addRival(rival);
    _reload();
  }

  Future<void> updateRival(Rival rival) async {
    await _service.updateRival(rival);
    _reload();
  }

  Future<void> deleteRival(String id) async {
    await _service.deleteRival(id);
    _reload();
  }

  /// Shortcut to update only the last achievement + timestamp.
  Future<void> updateAchievement(String id, String achievement) async {
    final rival = state.rivals.firstWhere((r) => r.id == id);
    await updateRival(
      rival.copyWith(
        lastAchievement: achievement,
        lastUpdated: DateTime.now(),
      ),
    );
  }
}

final rivalProvider = NotifierProvider<RivalNotifier, RivalState>(() {
  return RivalNotifier();
});
