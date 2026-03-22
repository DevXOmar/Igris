import '../../models/player_profile.dart';

/// Pure stat derivation.
///
/// Stored state should only include stat allocations (spent points) and
/// unspent points. Final rendered stats are derived at read time.
///
/// Rules:
/// - Base stats come from [PlayerProfile.defaultStats] (min 1).
/// - Allocations are added on top of base.
/// - Allocation bonuses (from titles / conditions) scale ONLY the allocated
///   portion, never the base.
/// - Output is clamped to [PlayerProfile.defaultMaxStatValue].
Map<String, int> calculateStats({
  required Map<String, int> allocations,
  required Map<String, double> allocationBonusByKey,
}) {
  const maxStat = PlayerProfile.defaultMaxStatValue;

  final normalizedAllocations = <String, int>{
    for (final k in PlayerProfile.defaultStats.keys) k: 0,
  };
  for (final e in allocations.entries) {
    final key = e.key;
    if (!normalizedAllocations.containsKey(key)) continue;
    final v = e.value;
    normalizedAllocations[key] = v < 0 ? 0 : v;
  }

  final out = <String, int>{};
  for (final baseEntry in PlayerProfile.defaultStats.entries) {
    final key = baseEntry.key;
    final base = baseEntry.value;
    final allocated = normalizedAllocations[key] ?? 0;
    final bonus = (allocationBonusByKey[key] ?? 0.0);
    final scaledAllocated = (allocated * (1.0 + (bonus < 0 ? 0.0 : bonus))).round();
    out[key] = (base + scaledAllocated).clamp(0, maxStat);
  }

  return out;
}
