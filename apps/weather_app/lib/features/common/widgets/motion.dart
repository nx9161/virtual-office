// MotionTokens: reduced-motion gate (R-15 / HIGH-5.7).
//
// Every animation in the app consults this one helper: shimmer (1200 ms
// cycle) <-> static placeholder, sheet slide 250 ms <-> instant, all gated
// on MediaQuery.disableAnimations.

import 'package:flutter/widgets.dart';

abstract final class MotionTokens {
  static bool isReducedMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration sheetSlide(BuildContext context) =>
      isReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 250);

  static Duration dialogScale(BuildContext context) =>
      isReducedMotion(context) ? Duration.zero : const Duration(milliseconds: 180);

  /// Shimmer cycle; null when reduced motion (caller shows a static placeholder).
  static Duration? shimmerCycle(BuildContext context) =>
      isReducedMotion(context) ? null : const Duration(milliseconds: 1200);
}
