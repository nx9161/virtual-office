// FocusRing: visible 3 px focus outline from the design tokens (R-15).
// Wrap custom interactive elements so keyboard / switch-control users get
// the same visible focus as native controls.

import 'package:flutter/material.dart';
import 'package:weather_app/features/common/design_tokens.dart';

class FocusRing extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const FocusRing({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  final FocusNode _node = FocusNode();
  bool _focused = false;

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      onFocusChange: (bool f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: _focused
              ? Border.all(color: DesignTokens.focusRing(context), width: 3)
              : Border.all(color: Colors.transparent, width: 3),
        ),
        child: widget.child,
      ),
    );
  }
}
