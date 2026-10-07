// WeatherCodeMapper: PRD Appendix A coverage + unknown-code degradation
// (FM-13 / US-7 AC1: "Unknown conditions" + neutral icon, never a crash).
//
// NOTE: the PRD Appendix A table enumerates 28 codes (the "29" in the QA
// gate does not match the PRD table); this test pins the implementation
// to the PRD table verbatim. If the PRD gains a 29th code, add it here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/common/weather_code_mapper.dart';

/// Every code in the PRD Appendix A table, in table order.
const List<int> appendixACodes = <int>[
  0, 1, 2, 3, 45, 48, 51, 53, 55, 77, 80, 81, 82, 96,
  56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 85, 86, 95, 99,
];

void main() {
  test('Appendix A enumerates the PRD table (28 codes)', () {
    expect(appendixACodes, hasLength(28));
    expect(appendixACodes.toSet(), hasLength(28)); // no duplicates
  });

  group('known codes', () {
    for (final int code in appendixACodes) {
      test('code $code is known and never gets the neutral icon', () {
        expect(WeatherCodeMapper.isKnown(code), isTrue, reason: '$code');
        expect(WeatherCodeMapper.iconFor(code, isDay: true),
            isNot(Icons.help_outline),
            reason: '$code day');
        expect(WeatherCodeMapper.iconFor(code, isDay: false),
            isNot(Icons.help_outline),
            reason: '$code night');
      });
    }
  });

  group('unknown codes degrade (FM-13)', () {
    for (final int? code in <int?>[null, -1, 4, 44, 100, 999]) {
      test('code $code -> neutral icon, not known', () {
        expect(WeatherCodeMapper.isKnown(code), isFalse, reason: '$code');
        expect(WeatherCodeMapper.iconFor(code, isDay: true),
            Icons.help_outline,
            reason: '$code day');
        expect(WeatherCodeMapper.iconFor(code, isDay: false),
            Icons.help_outline,
            reason: '$code night');
      });
    }
  });
}
