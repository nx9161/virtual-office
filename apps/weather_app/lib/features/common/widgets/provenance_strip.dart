// ProvenanceStrip: honest-data strip (design §3.1).
// "Open-Meteo · updated 12:04 · precise location off" — the time is in the
// LOCATION's timezone (formatter-provided), never assumed device-local.

import 'package:flutter/material.dart';
import 'package:weather_app/features/common/design_tokens.dart';

class ProvenanceStrip extends StatelessWidget {
  final String updatedTimeLabel;

  const ProvenanceStrip({super.key, required this.updatedTimeLabel});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Open-Meteo · updated $updatedTimeLabel · precise location off',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: DesignTokens.textTertiary(context),
          ),
    );
  }
}
