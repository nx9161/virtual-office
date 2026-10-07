// HeroCard: current conditions hero (design §3.1).
//
// Weather icon (decorative) + display-xl temperature + condition text +
// feels-like + high/low. Every value pairs a visual with a semantic label
// (FormattedValue); headings use semantic heading levels (R-15).

import 'package:flutter/material.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/weather_icon.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class HeroCard extends StatelessWidget {
  final ForecastView view;

  const HeroCard({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final DailyViewPoint? today =
        view.daily.isNotEmpty ? view.daily.first : null;
    return Semantics(
      header: true,
      child: Card(
        color: DesignTokens.surfaceSecondary(context),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(DesignTokens.cardRadius),
          side: BorderSide(color: DesignTokens.surfaceTertiary(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  WeatherIcon(
                      code: view.weatherCode, isDay: view.isDay, size: 48),
                  const SizedBox(width: DesignTokens.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Semantics(
                          label: view.temperature.semanticLabel,
                          child: ExcludeSemantics(
                            child: Text(
                              view.temperature.display,
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                          ),
                        ),
                        Text(
                          strings.wmoLabel(view.weatherCode),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s8),
              Semantics(
                label: view.feelsLike.semanticLabel,
                child: ExcludeSemantics(
                  child: Text(
                    'Feels like ${view.feelsLike.display}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              if (today != null) ...<Widget>[
                const SizedBox(height: DesignTokens.s4),
                Row(
                  children: <Widget>[
                    const Icon(Icons.arrow_upward, size: 16),
                    Semantics(
                      label: today.tempMax.semanticLabel,
                      child: ExcludeSemantics(
                          child: Text(today.tempMax.display)),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    const Icon(Icons.arrow_downward, size: 16),
                    Semantics(
                      label: today.tempMin.semanticLabel,
                      child: ExcludeSemantics(
                          child: Text(today.tempMin.display)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
