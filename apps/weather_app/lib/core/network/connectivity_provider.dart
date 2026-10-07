// Connectivity signal (PRD US-10 AC2 / FM-1).
//
// Debounced 2 s: a single auto-retry fires per real reconnect, not per VPN
// toggle / captive-portal flap. The home controller retries ONLY when the
// last failure was networkUnreachable/timeout (never apiClientError /
// schemaViolation), and latches until the next failure (HIGH-1.3).

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/config/constants.dart';

/// Emits true when the device has a network path, debounced per
/// [AppConstants.reconnectDebounce]. Seeded with the current status.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final Connectivity connectivity = Connectivity();
  final StreamController<bool> controller = StreamController<bool>();
  Timer? debounce;
  bool? lastEmitted;

  void scheduleEmit(bool online) {
    debounce?.cancel();
    debounce = Timer(AppConstants.reconnectDebounce, () {
      if (lastEmitted != online) {
        lastEmitted = online;
        if (!controller.isClosed) controller.add(online);
      }
    });
  }

  // Seed: emit the current status immediately (no debounce on the seed).
  connectivity.checkConnectivity().then((List<ConnectivityResult> results) {
    final bool online = !results.contains(ConnectivityResult.none);
    lastEmitted = online;
    if (!controller.isClosed) controller.add(online);
  });

  final StreamSubscription<List<ConnectivityResult>> sub =
      connectivity.onConnectivityChanged.listen(
    (List<ConnectivityResult> results) {
      scheduleEmit(!results.contains(ConnectivityResult.none));
    },
  );

  ref.onDispose(() {
    debounce?.cancel();
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});
