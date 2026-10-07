// App-level providers (composition helpers owned by core).

import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Device locale, overridable in tests. Drives the °F default (R-11) and the
/// formatter's locale separators.
final localeProvider = Provider<Locale>(
  (ref) => PlatformDispatcher.instance.locale,
);
