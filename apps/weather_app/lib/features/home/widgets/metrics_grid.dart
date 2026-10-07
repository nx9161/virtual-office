// MetricsGrid: current-conditions metrics (design §3.1, PRD US-4 AC2).
//
// US-4 AC2 content (PRD wins on content): wind speed + compass direction,
// humidity, precipitation probability, UV index, wind gusts, precipitation
// amount, cloud cover %, pressure. Precipitation *probability* is sourced
// from hourly[0]; precipitation *amount* is the current-condition value.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:weather_app/core/units/weather_formatter.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class MetricsGrid extends StatelessWidget {
  final ForecastView view;

  const MetricsGrid({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: DesignTokens.s12,
      crossAxisSpacing: DesignTokens.s12,
      childAspectRatio: 1.6,
      children: <Widget>[
        _MetricCard(
          icon: _WindArrow(compass: view.windCompass),
          value: view.windSpeed,
          label: '${strings.wind} ${view.windCompass}',
          semanticHint: '${strings.wind} ${view.windSpeed.semanticLabel} '
              'from the ${view.windCompassWord}',
        ),
        _MetricCard(
          icon: const Icon(Icons.water_drop, size: 24),
          value: view.humidity,
          label: strings.humidity,
          semanticHint: view.humidity.semanticLabel,
        ),
        _MetricCard(
          icon: const Icon(Icons.cloud, size: 24),
          value: view.precipProbability,
          label: strings.precipProbability,
          semanticHint: view.precipProbability.semanticLabel,
        ),
        _MetricCard(
          icon: const Icon(Icons.wb_sunny, size: 24),
          value: view.uvIndex,
          label: strings.uvIndexLabel,
          semanticHint: view.uvIndex.semanticLabel,
        ),
        _MetricCard(
          icon: const Icon(Icons.air, size: 24),
          value: view.windGusts,
          label: strings.windGusts,
          semanticHint:
              '${strings.windGusts}: ${view.windGusts.semanticLabel}',
        ),
        _MetricCard(
          icon: const Icon(Icons.umbrella, size: 24),
          value: view.precipitation,
          label: strings.precipAmount,
          semanticHint:
              '${strings.precipAmount}: ${view.precipitation.semanticLabel}',
        ),
        _MetricCard(
          icon: const Icon(Icons.cloud_queue, size: 24),
          value: view.cloudCover,
          label: strings.cloudCover,
          semanticHint:
              '${strings.cloudCover}: ${view.cloudCover.semanticLabel}',
        ),
        _MetricCard(
          icon: const Icon(Icons.speed, size: 24),
          value: view.pressure,
          label: strings.pressure,
          semanticHint: '${strings.pressure}: ${view.pressure.semanticLabel}',
        ),
      ],
    );
  }
}

class _WindArrow extends StatelessWidget {
  final String compass;

  const _WindArrow({required this.compass});

  @override
  Widget build(BuildContext context) {
    const List<String> points = <String>[
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    final int index = points.indexOf(compass);
    // Arrow points in the direction the wind comes FROM; rotate so that
    // N (0°) points up.
    final double radians =
        index < 0 ? 0 : (index * 22.5) * math.pi / 180;
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: radians,
        child: const Icon(Icons.arrow_upward, size: 24),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final Widget icon;
  final FormattedValue value;
  final String label;
  final String semanticHint;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: DesignTokens.surfaceSecondary(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        side: BorderSide(color: DesignTokens.surfaceTertiary(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s12),
        child: Semantics(
          label: '$label: $semanticHint',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                icon,
                const SizedBox(height: DesignTokens.s4),
                Text(
                  value.display,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DesignTokens.textSecondary(context),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
