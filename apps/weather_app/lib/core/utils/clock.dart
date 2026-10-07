// Clock injection for testability (R-11 formatter spec: "Updated X min ago"
// and location-timezone provenance take a `now` parameter).

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Mutable fake for unit/widget tests.
class FakeClock implements Clock {
  DateTime _now;

  FakeClock(this._now);

  void setNow(DateTime now) => _now = now;

  void advance(Duration duration) => _now = _now.add(duration);

  @override
  DateTime now() => _now;
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());
