// DailyScreen (S-4): full 7-day list.
// Reads the home controller's state — never a second fetch.
//
// Tapping a day expands it inline (accordion, one open at a time — design
// spec §3.4): sunrise/sunset, UV max, precipitation probability max (US-6
// AC2: sunrise/sunset must be visible somewhere on Home).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/responsive_scaffold.dart';
import 'package:weather_app/features/common/widgets/weather_icon.dart';
import 'package:weather_app/features/home/home_controller.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key});

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen> {
  int? _expandedIndex; // design §3.4: one open at a time

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final HomeScreenState state = ref.watch(homeControllerProvider);

    if (state is! HomeReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
      return ResponsiveScaffold(
        appBar: AppBar(title: Text(strings.dailySection)),
        body: const SizedBox.shrink(),
      );
    }

    final List<DailyViewPoint> days = state.view.daily;
    return ResponsiveScaffold(
      appBar: AppBar(title: Text(strings.dailySection)),
      body: days.isEmpty
          ? Center(child: Text(strings.dailyUnavailable))
          : ListView.separated(
              itemCount: days.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int i) {
                final DailyViewPoint d = days[i];
                return _DayTile(
                  day: d,
                  strings: strings,
                  expanded: _expandedIndex == i,
                  onChanged: (bool open) {
                    setState(() {
                      _expandedIndex = open ? i : null;
                    });
                  },
                );
              },
            ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final DailyViewPoint day;
  final AppLocalizations strings;
  final bool expanded;
  final ValueChanged<bool> onChanged;

  const _DayTile({
    required this.day,
    required this.strings,
    required this.expanded,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // The header summary is announced as one label; the expanded detail
    // rows keep their own semantics (no ExcludeSemantics blanket).
    return Semantics(
      label: '${day.weekday} ${day.date}, '
          '${strings.wmoLabel(day.weatherCode)}, high '
          '${day.tempMax.semanticLabel}, low '
          '${day.tempMin.semanticLabel}, '
          '${day.precipProbability.semanticLabel}',
      child: ExpansionTile(
        key: PageStorageKey<String>('${day.weekday}|${day.date}'),
        initiallyExpanded: expanded,
        onExpansionChanged: onChanged,
        leading: WeatherIcon(
            code: day.weatherCode, isDay: true, size: 36),
        title: Text('${day.weekday} · ${day.date}'),
        subtitle: Text(
          '${strings.wmoLabel(day.weatherCode)} · '
          '${day.precipProbability.display}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              day.tempMin.display,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.textSecondary(context),
                  ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Text(
              day.tempMax.display,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s4,
              DesignTokens.s16,
              DesignTokens.s16,
            ),
            child: Column(
              children: <Widget>[
                _DetailRow(
                  icon: Icons.wb_twilight,
                  label: strings.sunrise,
                  value: day.sunriseLabel,
                ),
                _DetailRow(
                  icon: Icons.nights_stay,
                  label: strings.sunset,
                  value: day.sunsetLabel,
                ),
                _DetailRow(
                  icon: Icons.wb_sunny,
                  label: strings.uvIndexMax,
                  value: day.uvIndexMax.display,
                ),
                _DetailRow(
                  icon: Icons.umbrella,
                  label: strings.precipProbabilityMax,
                  value: day.precipProbability.display,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
