/// Weekly live-fixture regeneration (B-4 / AppSec MEDIUM-2).
///
/// Run: `dart tool/regen_fixtures.dart`
/// Then: `flutter test test/contract` — the contract test must pass before
/// committing the regenerated fixtures. Unknown keys are ignored by the
/// parsers at runtime (R-1) and surfaced via onDrift; this job catches
/// STRUCTURAL drift early.
///
/// Pure `dart:io` + `dart:convert` only — no package:weather_app imports, so
/// it runs with plain `dart` (no Flutter SDK project context needed beyond
/// the repo checkout).
library;

import 'dart:convert';
import 'dart:io';

const String _forecastUrl = 'https://api.open-meteo.com/v1/forecast'
    '?latitude=52.52&longitude=13.41'
    '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,'
    'precipitation,weather_code,cloud_cover,pressure_msl,'
    'wind_speed_10m,wind_direction_10m,wind_gusts_10m'
    '&hourly=temperature_2m,precipitation_probability,weather_code'
    '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,'
    'uv_index_max,precipitation_probability_max'
    '&timezone=auto&forecast_days=7';

const String _geocodingUrl =
    'https://geocoding-api.open-meteo.com/v1/search'
    '?name=Berlin&count=8&language=en&format=json';

const String _bigDataCloudUrl =
    'https://api.bigdatacloud.net/data/reverse-geocode-client'
    '?latitude=52.52&longitude=13.41&localityLanguage=en';

Future<Map<String, dynamic>> _get(String url) async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest req = await client.getUrl(Uri.parse(url));
    req.headers.set('User-Agent', 'weather-app/fixture-regen');
    final HttpClientResponse res = await req.close();
    if (res.statusCode != 200) {
      throw StateError('GET $url -> ${res.statusCode}');
    }
    final String body = await res.transform(utf8.decoder).join();
    final Object? json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      throw StateError('GET $url -> root is not an object');
    }
    return json;
  } finally {
    client.close();
  }
}

/// Stable, sorted-key pretty print so diffs are reviewable.
String _stableJson(Object? json) {
  Object? sort(Object? v) {
    if (v is Map) {
      final Map<String, Object?> out = <String, Object?>{};
      final List<String> keys =
          v.keys.map((dynamic k) => k.toString()).toList()..sort();
      for (final String k in keys) {
        out[k] = sort(v[k]);
      }
      return out;
    }
    if (v is List) return v.map(sort).toList();
    return v;
  }

  return const JsonEncoder.withIndent('  ').convert(sort(json));
}

Future<void> _write(String name, Map<String, dynamic> json) async {
  final File f = File('test/fixtures/$name');
  await f.writeAsString('$_stableJson(json)\n');
  stdout.writeln('wrote ${f.path}');
}

Future<void> main() async {
  stdout.writeln('Regenerating contract fixtures from the live APIs…');
  final Map<String, dynamic> forecast = await _get(_forecastUrl);
  // Sanity: the parsers' required top-level keys must be present.
  for (final String k in <String>[
    'current',
    'hourly',
    'daily',
    'utc_offset_seconds',
    'timezone'
  ]) {
    if (!forecast.containsKey(k)) {
      throw StateError('forecast fixture missing top-level key: $k');
    }
  }
  await _write('forecast_valid.json', forecast);

  final Map<String, dynamic> geocoding = await _get(_geocodingUrl);
  if (geocoding['results'] is! List ||
      (geocoding['results'] as List).isEmpty) {
    throw StateError('geocoding fixture has no results');
  }
  await _write('geocoding_valid.json', geocoding);
  await _write('geocoding_empty.json', <String, dynamic>{
    'generationtime_ms': 0.0,
    'results': <Object?>[],
  });

  final Map<String, dynamic> bdc = await _get(_bigDataCloudUrl);
  if (bdc['city'] == null && bdc['locality'] == null) {
    throw StateError('bigdatacloud fixture has no city/locality');
  }
  await _write('bigdatacloud_valid.json', bdc);

  stdout.writeln(
      'Done. Now run `flutter test test/contract` — commit only on green.');
}
