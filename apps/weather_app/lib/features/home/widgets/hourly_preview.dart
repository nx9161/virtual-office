// HourlyPreview: next-8-hours strip on Home (design §3.1).
// Each hour is a distinct screen-reader item (PRD US-5 AC3).

import 'package:flutter/material.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/weather_icon.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class HourlyPreview extends StatelessWidget {
  final ForecastView view;
  final VoidCallback onSeeAll;

  const HourlyPreview({super.key, required this.view, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<HourlyViewPoint> hours = view.hourly.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                strings.hourlySection,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(onPressed: onSeeAll, child: Text(strings.seeAll)),
          ],
        ),
        if (view.deviceTimezoneFallback)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s8),
            child: Text(
              strings.deviceTimezoneNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.textTertiary(context),
                  ),
            ),
          ),
        SizedBox(
          height: 120,
          child: hours.isEmpty
              ? _unavailableNote(context, strings)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: hours.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: DesignTokens.s8),
                  itemBuilder: (BuildContext context, int i) =>
                      _HourCell(point: hours[i]),
                ),
        ),
        // FM-17: fewer than 24 hours remain (slice started at the current
        // local hour) — say so explicitly; never pad with fabricated values.
        if (view.hourlyPartial && hours.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s8),
            child: Text(
              strings.someHoursUnavailable,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.textSecondary(context),
                  ),
            ),
          ),
      ],
    );
  }

  Widget _unavailableNote(BuildContext context, AppLocalizations strings) {
    return Center(
      child: Text(
        strings.someHoursUnavailable,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DesignTokens.textSecondary(context),
            ),
      ),
    );
  }
}

class _HourCell extends StatelessWidget {
  final HourlyViewPoint point;

  const _HourCell({required this.point});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Semantics(
      label: '${point.timeLabel}, ${strings.wmoLabel(point.weatherCode)}, '
          '${point.temp.semanticLabel}, '
          '${point.precipProbability.semanticLabel}',
      child: ExcludeSemantics(
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceSecondary(context),
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            border: Border.all(color: DesignTokens.surfaceTertiary(context)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(point.timeLabel,
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: DesignTokens.s4),
              WeatherIcon(code: point.weatherCode, isDay: true, size: 24),
              const SizedBox(height: DesignTokens.s4),
              Text(point.temp.display,
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                point.precipProbability.display,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DesignTokens.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
