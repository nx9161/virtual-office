// Skeleton placeholders (R-15): the whole group is ExcludeSemantics +
// a single "Loading weather" announcement — never per-skeleton noise.
// Shimmer <-> static placeholder gated on MotionTokens (reduced motion).

import 'package:flutter/material.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/motion.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class SkeletonGroup extends StatelessWidget {
  final Widget child;

  const SkeletonGroup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return ExcludeSemantics(
      child: Semantics(
        label: strings.loadingWeather,
        liveRegion: true,
        child: child,
      ),
    );
  }
}

class SkeletonBlock extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const SkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    final Duration? cycle = MotionTokens.shimmerCycle(context);
    _controller = AnimationController(
      vsync: this,
      duration: cycle ?? const Duration(milliseconds: 1200),
    );
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
    if (cycle != null) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (BuildContext context, Widget? child) => Opacity(
        opacity: _opacity.value,
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: DesignTokens.surfaceTertiary(context),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}
