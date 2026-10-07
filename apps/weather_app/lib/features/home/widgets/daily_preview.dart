// DailyPreview: 3-row preview on Home (design §3.1).
// Full 7-day list lives on /daily.

import 'package:flutter/material.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/weather_icon.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class DailyPreview extends StatelessWidget {
  final ForecastView view;
  final VoidCallback onSeeAll;

  const DailyPreview({super.key, required this.view, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<DailyViewPoint> days = view.daily.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                strings.dailySection,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(onPressed: onSeeAll, child: Text(strings.seeAll)),
          ],
        ),
        ...<Widget>[
          for (final DailyViewPoint d in days) _DayRow(day: d),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final DailyViewPoint day;

  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Semantics(
      label:
          '${day.weekday}, ${strings.wmoLabel(day.weatherCode)}, high ${day.tempMax.semanticLabel}, low ${day.tempMin.semanticLabel}',
      child: ExcludeSemantics(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: DesignTokens.s8),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 72,
                child: Text(day.weekday,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              WeatherIcon(code: day.weatherCode, isDay: true, size: 28),
              const SizedBox(width: DesignTokens.s12),
              const Spacer(),
              Text(day.tempMin.display,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.textSecondary(context),
                      )),
              const SizedBox(width: DesignTokens.s8),
              Text(day.tempMax.display,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
