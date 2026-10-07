// PrivacyNoticeScreen: the Tech Law 12-section notice (C2).
// Sections are data-driven from AppLocalizations so the notice copy lives
// with the l10n strings; headers are semantic headings.

import 'package:flutter/material.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/responsive_scaffold.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class PrivacyNoticeScreen extends StatelessWidget {
  const PrivacyNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<({String title, String body})> sections =
        <({String title, String body})>[
      (title: strings.privacySection1Title(), body: strings.privacySection1Body()),
      (title: strings.privacySection2Title(), body: strings.privacySection2Body()),
      (title: strings.privacySection3Title(), body: strings.privacySection3Body()),
      (title: strings.privacySection4Title(), body: strings.privacySection4Body()),
      (title: strings.privacySection5Title(), body: strings.privacySection5Body()),
      (title: strings.privacySection6Title(), body: strings.privacySection6Body()),
      (title: strings.privacySection7Title(), body: strings.privacySection7Body()),
      (title: strings.privacySection8Title(), body: strings.privacySection8Body()),
      (title: strings.privacySection9Title(), body: strings.privacySection9Body()),
      (title: strings.privacySection10Title(), body: strings.privacySection10Body()),
      (title: strings.privacySection11Title(), body: strings.privacySection11Body()),
      (title: strings.privacySection12Title(), body: strings.privacySection12Body()),
    ];

    return ResponsiveScaffold(
      appBar: AppBar(title: Text(strings.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: <Widget>[
          Text(
            strings.privacyUpdated,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.textTertiary(context),
                ),
          ),
          const SizedBox(height: DesignTokens.s16),
          for (final ({String title, String body}) s in sections) ...<Widget>[
            Semantics(
              header: true,
              child: Text(
                s.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(s.body),
            const SizedBox(height: DesignTokens.s16),
          ],
        ],
      ),
    );
  }
}
