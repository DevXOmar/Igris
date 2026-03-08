import 'package:hive/hive.dart';

import '../models/rival.dart';

/// Hive-backed storage for Rival entries.
class RivalService {
  static const String _boxName = 'rivalsBox';

  Box<Rival> get _box => Hive.box<Rival>(_boxName);

  List<Rival> getAllRivals() {
    final rivals = _box.values.toList();
    rivals.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return rivals;
  }

  Future<void> addRival(Rival rival) async {
    await _box.put(rival.id, rival);
  }

  Future<void> updateRival(Rival rival) async {
    await _box.put(rival.id, rival);
  }

  Future<void> deleteRival(String id) async {
    await _box.delete(id);
  }
}
