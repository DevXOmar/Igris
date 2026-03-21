/// Domain → stat contribution helpers.
///
/// Rules:
/// - max 3 stats per domain
/// - weights sum to 1.0
/// - stable stat keys: presence, strength, agility, intelligence, discipline, endurance
library;

const List<String> kCoreStatKeys = <String>[
  'presence',
  'strength',
  'agility',
  'intelligence',
  'discipline',
  'endurance',
];

const Map<String, double> kDefaultStatWeights = <String, double>{
  'discipline': 0.5,
  'intelligence': 0.5,
};

final RegExp studyRe = RegExp(
  r'\b(study|studies|learn|learning|school|college|university|academics?|reading|read|book|course|exam|ds|data\s*science)\b',
  caseSensitive: false,
);

final RegExp workRe = RegExp(
  r'\b(work|job|career|business|project|projects|internship|internships|office|startup|hackathon|hackathons)\b',
  caseSensitive: false,
);

final RegExp fitnessRe = RegExp(
  r'\b(fitness|workout|gym|health|run|running|cardio|strength\s*training|training|physique|physiqu?e)\b',
  caseSensitive: false,
);

final RegExp speakingRe = RegExp(
  r'\b(speaking|speech|present(ation)?|pr|public\s*relations|communication|debate|interview)\b',
  caseSensitive: false,
);

final RegExp sportsRe = RegExp(
  r'\b(boxing|sport|sports|mma|kickboxing|wrestling|basketball|football|soccer|cricket|tennis)\b',
  caseSensitive: false,
);

Map<String, double> inferStatWeights(String domainName) {
  final name = domainName.trim().toLowerCase();
  if (name.isEmpty) return Map<String, double>.from(kDefaultStatWeights);

  if (studyRe.hasMatch(name)) {
    return normalizeStatWeights(const {
      'intelligence': 0.7,
      'discipline': 0.3,
    });
  }

  if (fitnessRe.hasMatch(name)) {
    return normalizeStatWeights(const {
      'strength': 0.5,
      'endurance': 0.3,
      'discipline': 0.2,
    });
  }

  if (speakingRe.hasMatch(name)) {
    return normalizeStatWeights(const {
      'presence': 0.6,
      'intelligence': 0.2,
      'discipline': 0.2,
    });
  }

  if (workRe.hasMatch(name)) {
    return normalizeStatWeights(const {
      'intelligence': 0.4,
      'discipline': 0.3,
      'presence': 0.3,
    });
  }

  if (sportsRe.hasMatch(name)) {
    // Boxing/sports example has 4 stats; drop to top 3 by weight and normalize.
    return normalizeStatWeights(const {
      'agility': 0.4,
      'strength': 0.3,
      'endurance': 0.2,
      'discipline': 0.1,
    });
  }

  return Map<String, double>.from(kDefaultStatWeights);
}

Map<String, double> normalizeStatWeights(
  Map<String, double>? weights, {
  int maxStats = 3,
}) {
  final input = weights ?? const <String, double>{};

  // Filter to known keys and positive weights.
  final entries = <MapEntry<String, double>>[];
  for (final e in input.entries) {
    final k = e.key;
    final v = e.value;
    if (!kCoreStatKeys.contains(k)) continue;
    if (v.isNaN || v.isInfinite) continue;
    if (v <= 0) continue;
    entries.add(MapEntry(k, v));
  }

  if (entries.isEmpty) {
    return Map<String, double>.from(kDefaultStatWeights);
  }

  entries.sort((a, b) => b.value.compareTo(a.value));
  final kept = entries.take(maxStats).toList(growable: false);

  var sum = 0.0;
  for (final e in kept) {
    sum += e.value;
  }

  if (sum <= 0) {
    return Map<String, double>.from(kDefaultStatWeights);
  }

  final out = <String, double>{};
  for (final e in kept) {
    out[e.key] = e.value / sum;
  }
  return out;
}

List<String> topStatKeys(Map<String, double> weights) {
  final normalized = normalizeStatWeights(weights);
  final list = normalized.entries.toList(growable: false)
    ..sort((a, b) => b.value.compareTo(a.value));
  return list.map((e) => e.key).toList(growable: false);
}

String formatStatKey(String key) {
  switch (key) {
    case 'presence':
      return 'Presence';
    case 'strength':
      return 'Strength';
    case 'agility':
      return 'Agility';
    case 'intelligence':
      return 'Intelligence';
    case 'discipline':
      return 'Discipline';
    case 'endurance':
      return 'Endurance';
    default:
      return key;
  }
}
