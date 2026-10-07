// Announcer: the single helper for screen-reader announcements (R-15).
//
// Called from the ref.listen side-effect layer — never scattered `announce`
// calls in widgets. Error states use assertive; offline/stale banners use
// polite live regions (design §6).

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

abstract final class Announcer {
  static void announce(
    String message, {
    bool assertive = false,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    SemanticsService.announce(
      message,
      textDirection,
      assertiveness:
          assertive ? Assertiveness.assertive : Assertiveness.polite,
    );
  }

  static void announceError(String message) =>
      announce(message, assertive: true);

  static void announcePolite(String message) => announce(message);
}
