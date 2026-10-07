// ConsentSheet: the in-app consent step (§4.3).
//
// Bullet transparency copy + "~1 km (rounded coordinates)" (R-4, legally
// material) + first-run crash-reporting disclosure (R-17) + privacy-notice
// link. "Allow" records in-app consent and signals the OS prompt; "Not now"
// records an in-app decline (30-day suppression, C4).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/error/failure_presentation.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/error_banner.dart';
import 'package:weather_app/features/consent/consent_controller.dart';
import 'package:weather_app/features/consent/consent_state.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class ConsentSheet extends ConsumerWidget {
  const ConsentSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ConsentControllerState state = ref.watch(consentControllerProvider);
    final ConsentController controller =
        ref.read(consentControllerProvider.notifier);

    // The OS prompt is invoked by the UI (platform call) once the controller
    // has recorded in-app consent and persisted the resume step (US-1 AC2).
    ref.listen<ConsentUiSignal>(
      consentControllerProvider.select((ConsentControllerState s) => s.uiSignal),
      (ConsentUiSignal? prev, ConsentUiSignal next) async {
        if (next == ConsentUiSignal.showOsPrompt && prev != next) {
          final OsPermissionStatus status = await ref
              .read(locationRepositoryProvider)
              .requestPermission();
          await controller.onOsPromptResult(status);
          controller.uiSignalConsumed();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                strings.consentTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(strings.consentBody),
            const SizedBox(height: DesignTokens.s12),
            ...<Widget>[
              for (final String bullet in strings.consentBullets)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: DesignTokens.s4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(Icons.check, size: 20),
                      const SizedBox(width: DesignTokens.s8),
                      Expanded(child: Text(bullet)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: DesignTokens.s12),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/privacy'),
              child: Text(strings.privacyNoticeLink),
            ),
            Text(
              strings.crashDisclosure,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.textSecondary(context),
                  ),
            ),
            if (state.failure != null) ...<Widget>[
              const SizedBox(height: DesignTokens.s12),
              ErrorBanner(
                failure: state.failure!,
                presentation:
                    FailurePresentationMapper.map(state.failure!),
                onAction: (FailureAction a) {
                  if (a == FailureAction.retry) {
                    controller.clearFailure();
                    controller.beginFlow();
                  } else {
                    controller.clearFailure();
                  }
                },
                onDismiss: controller.clearFailure,
              ),
            ],
            const SizedBox(height: DesignTokens.s16),
            FilledButton(
              onPressed: state.busy ? null : controller.allowFromSheet,
              child: state.busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.allow),
            ),
            const SizedBox(height: DesignTokens.s8),
            TextButton(
              onPressed: state.busy ? null : controller.notNow,
              child: Text(strings.notNow),
            ),
          ],
        ),
      ),
    );
  }
}
