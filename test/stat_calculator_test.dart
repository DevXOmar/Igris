import 'package:flutter_test/flutter_test.dart';

import 'package:igris/core/progression/stat_calculator.dart';

void main() {
  test('calculateStats adds base + allocations', () {
    final out = calculateStats(
      allocations: const {
        'presence': 3,
        'strength': 0,
      },
      allocationBonusByKey: const {},
    );

    expect(out['presence'], 1 + 3);
    expect(out['strength'], 1 + 0);
  });

  test('calculateStats scales allocated portion only', () {
    final out = calculateStats(
      allocations: const {
        'discipline': 10,
      },
      allocationBonusByKey: const {
        'discipline': 0.5, // +50%
      },
    );

    // base=1, allocated=10 -> scaled allocated=15 -> 16
    expect(out['discipline'], 16);
  });

  test('calculateStats clamps to max stat value', () {
    final out = calculateStats(
      allocations: const {
        'intelligence': 999,
      },
      allocationBonusByKey: const {
        'intelligence': 10.0,
      },
    );

    expect(out['intelligence'], 99);
  });
}
