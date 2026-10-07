// HourlyScreen (S-3): full 24-hour list.
// Reads the home controller's state — never a second fetch. If the home
// state is not ready (deep link), the screen pops back.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/responsive_scaffold.dart';
import 'package:weather_app/features/common/widgets/weather_icon.dart';
import 'package:weather_app/features/home/home_controller.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class HourlyScreen extends ConsumerWidget {
  const HourlyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final HomeScreenState state = ref.watch(homeControllerProvider);

    if (state is! HomeReady) {
      // No data to show (e.g. deep link): go back to the root.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
      return ResponsiveScaffold(
        appBar: AppBar(title: Text(strings.hourlySection)),
        body: const SizedBox.shrink(),
      );
    }

    final ForecastView view = state.view;
    final List<HourlyViewPoint> hours = view.hourly;
    return ResponsiveScaffold(
      appBar: AppBar(title: Text(strings.hourlySection)),
      body: hours.isEmpty
          ? Center(child: Text(strings.hourlyUnavailable))
          : Column(
              children: <Widget>[
                // FM-17: slice started at the current local hour — flag the
                // short list instead of padding it.
                if (view.hourlyPartial)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.s8,
                    ),
                    child: Text(
                      strings.someHoursUnavailable,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DesignTokens.textSecondary(context),
                              ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: hours.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int i) {
                      final HourlyViewPoint p = hours[i];
                      return Semantics(
                        label: '${p.timeLabel}, '
                            '${strings.wmoLabel(p.weatherCode)}, '
                            '${p.temp.semanticLabel}, '
                            '${p.precipProbability.semanticLabel}',
                        child: ExcludeSemantics(
                          child: ListTile(
                            leading: WeatherIcon(
                                code: p.weatherCode, isDay: true, size: 32),
                            title: Text(p.timeLabel),
                            subtitle: Text(strings.wmoLabel(p.weatherCode)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  p.precipProbability.display,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: DesignTokens.textSecondary(
                                            context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: DesignTokens.s16),
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    p.temp.display,
                                    textAlign: TextAlign.right,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
