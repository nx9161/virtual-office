// ForecastDto: two-tier validation (R-1) implementing PRD §7.2 literally.
//
// Tier 1 — structural -> AppFailure.schemaViolation, fail closed:
//   * body not a JSON object
//   * `current` missing or not an object
//   * `hourly` / `daily` missing or not objects (R-1 binding: unusable
//     hourly/daily fails closed; PRD §7.2's drop-section is overridden)
//   * non-array where an array is expected
//   * any Tier-1 array empty after equalization (B-6)
//   * latitude/longitude echo out of range (LOW-1: never outOfRange w/ values)
//
// Tier 2 — field-level -> null / degraded default, entity still constructed:
//   * every scalar per the PRD §7.2 "On violation" column ("—" == null here)
//   * unknown WMO code -> degraded label (kept as int; mapper handles it)
//   * daily max<min -> BOTH null (B-6 struck PRD's swap-and-flag)
//
// Unknown keys are IGNORED (R-1); schema drift is surfaced via the onDrift
// callback (field path only) -> Sentry breadcrumb aggregated as an issue
// (B-4), and the CI contract test.

import 'dart:convert';
import 'dart:math' show min;

import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/logging/app_logger.dart';
import 'package:weather_app/core/validation/validators.dart';
import 'package:weather_app/domain/entities/forecast.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

String _typeName(Object? v) => v == null ? 'null' : v.runtimeType.toString();

void _drift(
  Map<dynamic, dynamic> m,
  Set<String> known,
  String scope,
  void Function(String field)? onDrift,
) {
  if (onDrift == null) return;
  for (final dynamic k in m.keys) {
    if (k is String && !known.contains(k)) onDrift('$scope.$k');
  }
}

Map<dynamic, dynamic> _requiredObject(
    Map<dynamic, dynamic> parent, String key) {
  final Object? v = parent[key];
  if (v is! Map) {
    AppLogger.validationFailure(
        field: key, reason: 'missing-or-not-object', valueType: _typeName(v));
    throw AppFailure.schemaViolation(key, 'missing-or-not-object');
  }
  return v;
}

/// Tier-2 ranged double: wrong type or out of range -> null ("—").
double? _ranged(
    Map<dynamic, dynamic> m, String field, double minV, double maxV) {
  final Object? raw = m[field];
  final double? v = asDouble(raw);
  if (v == null) {
    if (raw != null) {
      AppLogger.validationFailure(
          field: field, reason: 'wrong-type', valueType: _typeName(raw));
    }
    return null;
  }
  if (v < minV || v > maxV) {
    AppLogger.validationFailure(
        field: field, reason: 'out-of-range', valueType: 'double');
    return null;
  }
  return v;
}

double? _rangedAt(
    List<dynamic> list, int index, String field, double minV, double maxV) {
  final Object? raw = list[index];
  final double? v = asDouble(raw);
  if (v == null) {
    if (raw != null) {
      AppLogger.validationFailure(
          field: field, reason: 'wrong-type', valueType: _typeName(raw));
    }
    return null;
  }
  if (v < minV || v > maxV) {
    AppLogger.validationFailure(
        field: field, reason: 'out-of-range', valueType: 'double');
    return null;
  }
  return v;
}

double? _nonNegative(Map<dynamic, dynamic> m, String field) {
  final Object? raw = m[field];
  final double? v = asDouble(raw);
  if (v == null) {
    if (raw != null) {
      AppLogger.validationFailure(
          field: field, reason: 'wrong-type', valueType: _typeName(raw));
    }
    return null;
  }
  if (v < 0) {
    // PRD §7.2: precipitation/wind >= 0, no upper bound (C-2: the
    // architecture's invented caps are rejected).
    AppLogger.validationFailure(
        field: field, reason: 'negative', valueType: 'double');
    return null;
  }
  return v;
}

double? _nonNegativeAt(List<dynamic> list, int index, String field) {
  final Object? raw = list[index];
  final double? v = asDouble(raw);
  if (v == null || v < 0) {
    if (raw != null) {
      AppLogger.validationFailure(
          field: field,
          reason: v == null ? 'wrong-type' : 'negative',
          valueType: _typeName(raw));
    }
    return null;
  }
  return v;
}

DateTime? _parseIso(String field, Object? raw) {
  if (raw is! String) {
    if (raw != null) {
      AppLogger.validationFailure(
          field: field, reason: 'wrong-type', valueType: _typeName(raw));
    }
    return null;
  }
  try {
    return DateTime.parse(raw);
  } on FormatException {
    AppLogger.validationFailure(
        field: field, reason: 'unparseable-iso', valueType: 'String');
    return null;
  }
}

abstract final class ForecastDto {
  static const Set<String> _rootKeys = <String>{
    'latitude',
    'longitude',
    'utc_offset_seconds',
    'timezone',
    'timezone_abbreviation',
    'elevation', // documented, unused
    'generationtime_ms', // documented, unused
    'current',
    'hourly',
    'daily',
  };
  static const Set<String> _currentKeys = <String>{
    'time',
    'temperature_2m',
    'relative_humidity_2m',
    'apparent_temperature',
    'is_day',
    'precipitation',
    'weather_code',
    'cloud_cover',
    'pressure_msl',
    'wind_speed_10m',
    'wind_direction_10m',
    'wind_gusts_10m',
  };
  static const Set<String> _hourlyKeys = <String>{
    'time',
    'temperature_2m',
    'precipitation_probability',
    'weather_code',
  };
  static const Set<String> _dailyKeys = <String>{
    'time',
    'weather_code',
    'temperature_2m_max',
    'temperature_2m_min',
    'sunrise',
    'sunset',
    'uv_index_max',
    'precipitation_probability_max',
  };

  /// Parses + validates a decoded JSON body. Throws AppFailure.schemaViolation
  /// on Tier-1 structural problems.
  static Forecast parse({
    required Object? json,
    required GeoPlace place,
    required DateTime fetchedAtUtc,
    void Function(String field)? onDrift,
  }) {
    if (json is! Map) {
      throw const AppFailure.schemaViolation('<body>', 'root-not-object');
    }
    final Map<dynamic, dynamic> root = json;
    _drift(root, _rootKeys, '<root>', onDrift);
    _validateEcho(root);

    final Map<dynamic, dynamic> current = _requiredObject(root, 'current');
    final Map<dynamic, dynamic> hourly = _requiredObject(root, 'hourly');
    final Map<dynamic, dynamic> daily = _requiredObject(root, 'daily');

    return Forecast(
      place: place,
      current: _parseCurrent(current, onDrift),
      hourly: _parseHourly(hourly, onDrift),
      daily: _parseDaily(daily, onDrift),
      utcOffsetSeconds: _parseUtcOffset(root),
      timezone: asCleanStringOrOmit(root['timezone'], maxLength: 64),
      fetchedAtUtc: fetchedAtUtc,
    );
  }

  /// LOW-1: echo failures -> schemaViolation (Tier 1). Never outOfRange with
  /// coordinate values. Echo is optional; when present it must be sane.
  static void _validateEcho(Map<dynamic, dynamic> root) {
    final double? lat = asDouble(root['latitude']);
    final double? lon = asDouble(root['longitude']);
    if (lat != null && (lat < -90 || lat > 90)) {
      throw const AppFailure.schemaViolation('latitude', 'echo-out-of-range');
    }
    if (lon != null && (lon < -180 || lon > 180)) {
      throw const AppFailure.schemaViolation('longitude', 'echo-out-of-range');
    }
  }

  static CurrentConditions _parseCurrent(
      Map<dynamic, dynamic> c, void Function(String field)? onDrift) {
    _drift(c, _currentKeys, 'current', onDrift);

    final DateTime? time = _parseIso('current.time', c['time']);
    // PRD: unparseable current.time -> device clock fallback (done by caller
    // via fetchedAtUtc); is_day violation -> assume 1.
    int isDay = 1;
    final Object? isDayRaw = c['is_day'];
    if (isDayRaw != null) {
      final int? v = asInt(isDayRaw);
      if (v == 0 || v == 1) {
        isDay = v!;
      } else {
        AppLogger.validationFailure(
            field: 'current.is_day',
            reason: 'not-in-{0,1}-assume-1',
            valueType: _typeName(isDayRaw));
      }
    }

    return CurrentConditions(
      time: time,
      temperatureC: _ranged(c, 'current.temperature_2m', -90, 60),
      apparentTemperatureC: _ranged(c, 'current.apparent_temperature', -90, 60),
      weatherCode: asInt(c['weather_code']),
      humidityPct: _ranged(c, 'current.relative_humidity_2m', 0, 100),
      precipitationMm: _nonNegative(c, 'current.precipitation'),
      cloudCoverPct: _ranged(c, 'current.cloud_cover', 0, 100),
      pressureHpa: _ranged(c, 'current.pressure_msl', 800, 1100),
      windSpeedKmh: _nonNegative(c, 'current.wind_speed_10m'),
      windDirectionDeg: _ranged(c, 'current.wind_direction_10m', 0, 360),
      windGustsKmh: _nonNegative(c, 'current.wind_gusts_10m'),
      isDay: isDay,
    );
  }

  static List<HourlyPoint> _parseHourly(
      Map<dynamic, dynamic> h, void Function(String field)? onDrift) {
    _drift(h, _hourlyKeys, 'hourly', onDrift);
    final Object? timeRaw = h['time'];
    final Object? tempRaw = h['temperature_2m'];
    final Object? probRaw = h['precipitation_probability'];
    final Object? codeRaw = h['weather_code'];
    if (timeRaw is! List ||
        tempRaw is! List ||
        probRaw is! List ||
        codeRaw is! List) {
      throw const AppFailure.schemaViolation('hourly', 'expected-array');
    }
    final List<dynamic> times = timeRaw;
    final List<dynamic> temps = tempRaw;
    final List<dynamic> probs = probRaw;
    final List<dynamic> codes = codeRaw;

    // B-6: equalize ALL arrays to the shortest length FIRST, then drop
    // unparseable-time rows consistently across every array. Filtering
    // `time` into an index list and indexing that into the UNTRUNCATED
    // sibling arrays was a RangeError (attacker-triggerable via MITM).
    // PRD §7.2: an unparseable time drops its row (kept here per-row).
    int n = times.length;
    n = min(n, temps.length);
    n = min(n, probs.length);
    n = min(n, codes.length);
    n = min(n, AppConstants.hourlyApiParseCap); // B1: keep up to 48 raw;
    // the view-mapping layer slices 24 from the current local hour (US-5 AC1)
    // and raises the FM-17 "Some hours unavailable" note when fewer remain.
    final List<HourlyPoint> points = <HourlyPoint>[];
    for (int i = 0; i < n; i++) {
      final DateTime? dt = _parseIso('hourly.time[$i]', times[i]);
      if (dt == null) continue;
      points.add(HourlyPoint(
        time: dt,
        temperatureC: _rangedAt(temps, i, 'hourly.temperature_2m', -90, 60),
        precipitationProbabilityPct: _rangedAt(
            probs, i, 'hourly.precipitation_probability', 0, 100),
        weatherCode: asInt(codes[i]),
      ));
    }
    if (points.isEmpty) {
      throw const AppFailure.schemaViolation('hourly', 'empty-after-equalize');
    }
    return points;
  }

  static List<DailySummary> _parseDaily(
      Map<dynamic, dynamic> d, void Function(String field)? onDrift) {
    _drift(d, _dailyKeys, 'daily', onDrift);
    final Object? timeRaw = d['time'];
    final Object? codeRaw = d['weather_code'];
    final Object? maxRaw = d['temperature_2m_max'];
    final Object? minRaw = d['temperature_2m_min'];
    final Object? sunriseRaw = d['sunrise'];
    final Object? sunsetRaw = d['sunset'];
    final Object? uvRaw = d['uv_index_max'];
    final Object? probRaw = d['precipitation_probability_max'];
    if (timeRaw is! List ||
        codeRaw is! List ||
        maxRaw is! List ||
        minRaw is! List ||
        sunriseRaw is! List ||
        sunsetRaw is! List ||
        uvRaw is! List ||
        probRaw is! List) {
      throw const AppFailure.schemaViolation('daily', 'expected-array');
    }
    final List<dynamic> times = timeRaw;
    final List<dynamic> codes = codeRaw;
    final List<dynamic> maxs = maxRaw;
    final List<dynamic> mins = minRaw;
    final List<dynamic> sunrises = sunriseRaw;
    final List<dynamic> sunsets = sunsetRaw;
    final List<dynamic> uvs = uvRaw;
    final List<dynamic> probs = probRaw;

    final List<int> keep = <int>[];
    final List<DateTime> parsedDates = <DateTime>[];
    // B-6: equalize ALL arrays to the shortest length FIRST, then drop
    // unparseable-time rows consistently across every array (same fix as
    // _parseHourly: keep[] indexed original-array indices into the
    // untruncated siblings -> RangeError on adversarial input).
    int n = times.length;
    n = min(n, codes.length);
    n = min(n, maxs.length);
    n = min(n, mins.length);
    n = min(n, sunrises.length);
    n = min(n, sunsets.length);
    n = min(n, uvs.length);
    n = min(n, probs.length);
    n = min(n, AppConstants.dailyEntryCount);
    for (int i = 0; i < n; i++) {
      final DateTime? dt = _parseIso('daily.time[$i]', times[i]);
      if (dt != null) {
        keep.add(i);
        parsedDates.add(dt);
      }
    }
    if (keep.isEmpty) {
      throw const AppFailure.schemaViolation('daily', 'empty-after-equalize');
    }
    return List<DailySummary>.generate(keep.length, (int k) {
      final int src = keep[k];
      double? max = _rangedAt(maxs, src, 'daily.temperature_2m_max', -90, 60);
      double? minT = _rangedAt(mins, src, 'daily.temperature_2m_min', -90, 60);
      if (max != null && minT != null && max < minT) {
        // B-6: PRD's swap-and-flag is struck; both become null ("—").
        AppLogger.validationFailure(
            field: 'daily.temperature_2m_max/min[$src]',
            reason: 'max-less-than-min',
            valueType: 'double');
        max = null;
        minT = null;
      }
      return DailySummary(
        date: parsedDates[k],
        tempMaxC: max,
        tempMinC: minT,
        weatherCode: asInt(codes[src]),
        sunrise: _parseIso('daily.sunrise[$src]', sunrises[src]),
        sunset: _parseIso('daily.sunset[$src]', sunsets[src]),
        uvIndexMax: _rangedAt(uvs, src, 'daily.uv_index_max', 0, 20),
        precipitationProbabilityMaxPct: _rangedAt(
            probs, src, 'daily.precipitation_probability_max', 0, 100),
      );
    });
  }

  static int? _parseUtcOffset(Map<dynamic, dynamic> root) {
    final Object? raw = root['utc_offset_seconds'];
    if (raw == null) return null; // absent -> device tz fallback (FM-14)
    final int? v = asInt(raw);
    if (v == null || v < -50400 || v > 50400) {
      AppLogger.validationFailure(
          field: 'utc_offset_seconds',
          reason: 'invalid-fallback-device-tz',
          valueType: _typeName(raw));
      return null;
    }
    return v;
  }

  // --- cache codec (echo-free by construction: entities never hold echo) ---

  /// Encodes a forecast for the disk cache.
  ///
  /// B-1: device-sourced places are encoded NAME-ONLY (no lat/lon) — the
  /// mirror of SettingsStore.setSavedPlace's ADR-07 branch. The device fix
  /// (2-dp) is a user location, not public place data. Search-sourced places
  /// keep their public place coords (US-13 carve-out) and are unaffected.
  static String encode(Forecast f, {bool deviceSourcedPlace = false}) {
    final Map<String, Object?> placeJson = deviceSourcedPlace
        ? <String, Object?>{
            'name': f.place.name,
            if (f.place.admin1 != null) 'admin1': f.place.admin1,
            'country': f.place.country,
            if (f.place.countryCode != null) 'countryCode': f.place.countryCode,
          }
        : f.place.toJson();
    return jsonEncode(<String, Object?>{
      'v': AppConstants.forecastCacheSchemaVersion,
      'place': placeJson,
        'fetchedAtUtc': f.fetchedAtUtc.toIso8601String(),
        'utcOffsetSeconds': f.utcOffsetSeconds,
        'timezone': f.timezone,
        'current': <String, Object?>{
          'time': f.current.time?.toIso8601String(),
          'temperatureC': f.current.temperatureC,
          'apparentTemperatureC': f.current.apparentTemperatureC,
          'weatherCode': f.current.weatherCode,
          'humidityPct': f.current.humidityPct,
          'precipitationMm': f.current.precipitationMm,
          'cloudCoverPct': f.current.cloudCoverPct,
          'pressureHpa': f.current.pressureHpa,
          'windSpeedKmh': f.current.windSpeedKmh,
          'windDirectionDeg': f.current.windDirectionDeg,
          'windGustsKmh': f.current.windGustsKmh,
          'isDay': f.current.isDay,
        },
        'hourly': <Object?>[
          for (final HourlyPoint p in f.hourly)
            <String, Object?>{
              'time': p.time.toIso8601String(),
              'temperatureC': p.temperatureC,
              'precipitationProbabilityPct': p.precipitationProbabilityPct,
              'weatherCode': p.weatherCode,
            }
        ],
        'daily': <Object?>[
          for (final DailySummary d in f.daily)
            <String, Object?>{
              'date': d.date.toIso8601String(),
              'tempMaxC': d.tempMaxC,
              'tempMinC': d.tempMinC,
              'weatherCode': d.weatherCode,
              'sunrise': d.sunrise?.toIso8601String(),
              'sunset': d.sunset?.toIso8601String(),
              'uvIndexMax': d.uvIndexMax,
              'precipitationProbabilityMaxPct':
                  d.precipitationProbabilityMaxPct,
            }
        ],
      });
  }

  /// Decodes a cached payload. Throws FormatException on corruption ->
  /// the cache treats it as FM-18 (evict + miss). Never throws AppFailure.
  static Forecast decode(String payloadJson) {
    final Object? json = jsonDecode(payloadJson);
    if (json is! Map) throw const FormatException('cache payload not object');
    final Map<dynamic, dynamic> root = json;
    final Object? v = root['v'];
    if (v is! int || v != AppConstants.forecastCacheSchemaVersion) {
      throw const FormatException('cache schema version mismatch');
    }
    final Object? placeRaw = root['place'];
    if (placeRaw is! Map) throw const FormatException('cache place invalid');
    final Map<String, Object?> placeJson = <String, Object?>{
      for (final dynamic k in placeRaw.keys)
        if (k is String) k: placeRaw[k],
    };
    final GeoPlace place = _decodePlace(placeJson);
    final Object? fetchedRaw = root['fetchedAtUtc'];
    if (fetchedRaw is! String) {
      throw const FormatException('cache fetchedAt invalid');
    }
    final DateTime? fetchedParsed = DateTime.tryParse(fetchedRaw);
    if (fetchedParsed == null) {
      throw const FormatException('cache fetchedAt invalid');
    }
    final DateTime fetchedAtUtc = fetchedParsed;
    CurrentConditions current = _decodeCurrent(root['current']);
    List<HourlyPoint> hourly = _decodeHourly(root['hourly']);
    List<DailySummary> daily = _decodeDaily(root['daily']);
    final Object? offsetRaw = root['utcOffsetSeconds'];
    final int? offset = offsetRaw is int ? offsetRaw : null;
    final Object? tzRaw = root['timezone'];
    return Forecast(
      place: place,
      current: current,
      hourly: hourly,
      daily: daily,
      utcOffsetSeconds: offset,
      timezone: tzRaw is String ? tzRaw : null,
      fetchedAtUtc: fetchedAtUtc,
    );
  }

  /// Decodes a cached place record. Device-sourced records persist the place
  /// NAME ONLY (ADR-07, B-1); missing lat/lon decodes to the 0,0 sentinel
  /// (mirrors SettingsStore's device branch) — that sentinel must NEVER
  /// reach the network; callers re-resolve device places via the OS.
  /// Search-sourced records carry their public coords as before.
  static GeoPlace _decodePlace(Map<String, Object?> json) {
    final Object? nameRaw = json['name'];
    if (nameRaw is! String || nameRaw.isEmpty) {
      throw const FormatException('cache place missing name');
    }
    final double? lat = asDouble(json['lat']);
    final double? lon = asDouble(json['lon']);
    if ((lat == null) != (lon == null)) {
      throw const FormatException('cache place half-missing coordinates');
    }
    final Object? admin1Raw = json['admin1'];
    final Object? countryRaw = json['country'];
    final Object? codeRaw = json['countryCode'];
    return GeoPlace(
      name: nameRaw,
      admin1: admin1Raw is String && admin1Raw.isNotEmpty ? admin1Raw : null,
      country:
          countryRaw is String && countryRaw.isNotEmpty ? countryRaw : '—',
      countryCode: codeRaw is String && codeRaw.length == 2 ? codeRaw : null,
      lat: lat ?? 0, // sentinel for name-only (device-sourced) records
      lon: lon ?? 0,
      geocodingId: asInt(json['id']),
    );
  }

  static CurrentConditions _decodeCurrent(Object? raw) {
    if (raw is! Map) throw const FormatException('cache current invalid');
    final Map<dynamic, dynamic> c = raw;
    DateTime? time;
    final Object? t = c['time'];
    if (t is String) {
      try {
        time = DateTime.parse(t);
      } on FormatException {
        time = null;
      }
    }
    double? d(Object? x) => asDouble(x);
    final Object? isDayRaw = c['isDay'];
    return CurrentConditions(
      time: time,
      temperatureC: d(c['temperatureC']),
      apparentTemperatureC: d(c['apparentTemperatureC']),
      weatherCode: asInt(c['weatherCode']),
      humidityPct: d(c['humidityPct']),
      precipitationMm: d(c['precipitationMm']),
      cloudCoverPct: d(c['cloudCoverPct']),
      pressureHpa: d(c['pressureHpa']),
      windSpeedKmh: d(c['windSpeedKmh']),
      windDirectionDeg: d(c['windDirectionDeg']),
      windGustsKmh: d(c['windGustsKmh']),
      isDay: isDayRaw is int && (isDayRaw == 0 || isDayRaw == 1) ? isDayRaw : 1,
    );
  }

  static List<HourlyPoint> _decodeHourly(Object? raw) {
    if (raw is! List) throw const FormatException('cache hourly invalid');
    return <HourlyPoint>[
      for (final dynamic e in raw)
        if (e is Map)
          HourlyPoint(
            time: _tryParseTime(e['time']),
            temperatureC: asDouble(e['temperatureC']),
            precipitationProbabilityPct:
                asDouble(e['precipitationProbabilityPct']),
            weatherCode: asInt(e['weatherCode']),
          ),
    ];
  }

  static DateTime _tryParseTime(Object? raw) {
    if (raw is String) {
      final DateTime? dt = DateTime.tryParse(raw);
      if (dt != null) return dt;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _tryParseTimeOrNull(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static List<DailySummary> _decodeDaily(Object? raw) {
    if (raw is! List) throw const FormatException('cache daily invalid');
    return <DailySummary>[
      for (final dynamic e in raw)
        if (e is Map)
          DailySummary(
            date: _tryParseTime(e['date']),
            tempMaxC: asDouble(e['tempMaxC']),
            tempMinC: asDouble(e['tempMinC']),
            weatherCode: asInt(e['weatherCode']),
            sunrise: _tryParseTimeOrNull(e['sunrise']),
            sunset: _tryParseTimeOrNull(e['sunset']),
            uvIndexMax: asDouble(e['uvIndexMax']),
            precipitationProbabilityMaxPct:
                asDouble(e['precipitationProbabilityMaxPct']),
          ),
    ];
  }
}
