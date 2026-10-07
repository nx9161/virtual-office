// RecentPlacesStore: Hive box `recent_places` (PRD US-13).
//
// Up to 10 entries (PRD wins per R-3), most-recent-first, deduplicated.
// Contents are PUBLIC place data (name/region/country + 2-dp place coords) —
// never device-derived coordinates (US-13 AC3; asserted by test).
// Corrupt entries are purged on load (PRD FM-18); whole-list corruption
// wipes the list (self-healing, FM-18).
// Excluded from cloud backup (B-5).

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

class RecentPlacesStore {
  static const String boxName = 'recent_places';
  static const String _key = 'places_v1';

  Box<String>? _box;
  final List<GeoPlace> _places = <GeoPlace>[];

  Future<void> init() async {
    try {
      _box = await Hive.openBox<String>(boxName);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (_) {}
      _box = await Hive.openBox<String>(boxName);
    }
    _load();
  }

  void _load() {
    _places.clear();
    final String? stored = _box?.get(_key);
    if (stored == null) return;
    try {
      final Object? json = jsonDecode(stored);
      if (json is! List) throw const FormatException('recents not list');
      for (final Object? e in json) {
        if (e is! Map) continue;
        try {
          final GeoPlace p = GeoPlace.fromJson(<String, Object?>{
            for (final dynamic k in e.keys)
              if (k is String) k: e[k],
          });
          if (p.lat < -90 || p.lat > 90 || p.lon < -180 || p.lon > 180) {
            continue; // PRD FM-18: purge corrupt entries
          }
          _places.add(p);
        } catch (_) {
          // Skip the corrupt entry, keep the rest.
        }
      }
    } catch (_) {
      try {
        _box?.delete(_key);
      } catch (_) {}
      _places.clear();
    }
    _dedupeAndCap();
  }

  List<GeoPlace> get places => List<GeoPlace>.unmodifiable(_places);

  Future<void> add(GeoPlace place) async {
    _places.removeWhere((GeoPlace p) =>
        p.name == place.name && p.lat == place.lat && p.lon == place.lon);
    _places.insert(0, place);
    _dedupeAndCap();
    await _persist();
  }

  Future<void> remove(GeoPlace place) async {
    _places.removeWhere((GeoPlace p) =>
        p.name == place.name && p.lat == place.lat && p.lon == place.lon);
    await _persist();
  }

  Future<void> clear() async {
    _places.clear();
    try {
      await _box?.delete(_key);
    } catch (_) {}
  }

  void _dedupeAndCap() {
    final Set<String> seen = <String>{};
    _places.retainWhere((GeoPlace p) {
      final String k = '${p.name}|${p.lat}|${p.lon}';
      if (seen.contains(k)) return false;
      seen.add(k);
      return true;
    });
    if (_places.length > AppConstants.recentPlacesMax) {
      _places.removeRange(
          AppConstants.recentPlacesMax, _places.length);
    }
  }

  Future<void> _persist() async {
    try {
      await _box?.put(
          _key, jsonEncode(<Object?>[for (final GeoPlace p in _places) p.toJson()]));
    } catch (_) {
      // Recents are best-effort; never crash the app.
    }
  }
}

/// Bound in main.dart after async init.
final recentPlacesProvider = Provider<RecentPlacesStore>(
  (ref) => throw UnimplementedError(
    'recentPlacesProvider is not overridden. Bind after init in main.dart.',
  ),
);
