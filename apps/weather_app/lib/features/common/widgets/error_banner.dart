// ErrorBanner: non-blocking error over cached data (R-8).
//
// Shown when a refresh/SWR fails but data exists: "Couldn't refresh —
// showing data from 1h ago. Retry." For rateLimited, the Retry button shows
// a live countdown and enables only after Retry-After elapses (PRD FM-6);
// the controller owns the single scheduled auto-retry (R-12).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:weather_app/core/error/failure_presentation.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class ErrorBanner extends StatefulWidget {
  final AppFailure failure;
  final FailurePresentation presentation;
  final void Function(FailureAction action) onAction;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.failure,
    required this.presentation,
    required this.onAction,
    this.onDismiss,
  });

  @override
  State<ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<ErrorBanner> {
  Timer? _ticker;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    final AppFailure f = widget.failure;
    if (f is RateLimitedFailure && f.retryAfter != null) {
      _remaining = f.retryAfter;
      _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if (!mounted) return;
        final Duration next = _remaining! - const Duration(seconds: 1);
        setState(() => _remaining = next.isNegative ? Duration.zero : next);
        if (_remaining == Duration.zero) {
          _ticker?.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool countingDown = _remaining != null && _remaining! > Duration.zero;
    String actionLabel =
        strings.failureActionLabel(widget.presentation.primaryAction);
    if (countingDown) {
      actionLabel = strings.retryIn(_remaining!.inSeconds);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.errorSurface(context),
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.error(context).withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline,
              color: DesignTokens.error(context), size: 20),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.presentation.headline,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  widget.presentation.body,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: countingDown
                ? null
                : () => widget.onAction(widget.presentation.primaryAction),
            child: Text(actionLabel),
          ),
          if (widget.onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: strings.dismiss,
              onPressed: widget.onDismiss,
            ),
        ],
      ),
    );
  }
}
