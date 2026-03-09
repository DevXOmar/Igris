import 'package:hive/hive.dart';
import '../models/player_profile.dart';

/// Low-level persistence helper for [PlayerProfile].
///
/// There is exactly ONE profile in the box, stored under [_profileKey].
/// All higher-level logic lives in [ProgressionNotifier].
class ProgressionService {
  static const String boxName = 'playerProfileBox';
  static const String _profileKey = 'profile';

  Box<PlayerProfile> get _box => Hive.box<PlayerProfile>(boxName);

  /// Returns the persisted profile, or a fresh default if none exists.
  PlayerProfile getProfile() {
    return _box.get(_profileKey) ?? const PlayerProfile();
  }

  /// Persists [profile] to Hive.
  Future<void> saveProfile(PlayerProfile profile) async {
    await _box.put(_profileKey, profile);
  }
}
