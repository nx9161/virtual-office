// ErrorCard: full-screen error state (R-8: only when there is NO data).
//
// Built from FailurePresentation (PRD §11 exact headlines). Human sentence +
// one primary action + optional secondary; technical detail goes to the
// sanitized log, never the screen. Announced via the assertive live region
// by the caller (ref.listen side-effect layer).

import 'package:flutter/material.dart';
import 'package:weather_app/core/error/failure_presentation.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class ErrorCard extends StatelessWidget {
  final FailurePresentation presentation;
  final void Function(FailureAction action) onAction;

  const ErrorCard({
    super.key,
    required this.presentation,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Semantics(
          header: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.cloud_off,
                size: 64,
                color: DesignTokens.textTertiary(context),
              ),
              const SizedBox(height: DesignTokens.s16),
              Text(
                presentation.headline,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                presentation.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DesignTokens.textSecondary(context),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.s24),
              _actionButton(context, strings, presentation.primaryAction,
                  primary: true),
              if (presentation.secondaryAction != null) ...<Widget>[
                const SizedBox(height: DesignTokens.s8),
                _actionButton(context, strings, presentation.secondaryAction!,
                    primary: false),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    AppLocalizations strings,
    FailureAction action, {
    required bool primary,
  }) {
    final String label = strings.failureActionLabel(action);
    if (action == FailureAction.none) return const SizedBox.shrink();
    final VoidCallback onPressed = () => onAction(action);
    if (primary) {
      return ElevatedButton(onPressed: onPressed, child: Text(label));
    }
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}
