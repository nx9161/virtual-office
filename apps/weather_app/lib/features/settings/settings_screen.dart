// SettingsScreen (S-5): grouped list per design §3.5.
//
// Location group (toggle + saved city + precision explainer), Units group
// (temperature + wind + pressure segmented), Appearance (theme), Privacy
// (notice, what-we-store, delete local data, crash reporting), About.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/responsive_scaffold.dart';
import 'package:weather_app/features/consent/consent_controller.dart';
import 'package:weather_app/features/consent/consent_sheet.dart';
import 'package:weather_app/features/consent/consent_state.dart';
import 'package:weather_app/features/search/search_sheet.dart';
import 'package:weather_app/features/settings/settings_controller.dart';
import 'package:weather_app/features/settings/settings_state.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState state = ref.watch(settingsControllerProvider);
    final AppLocalizations strings = AppLocalizations.of(context);
    final SettingsController controller =
        ref.read(settingsControllerProvider.notifier);

    // Consent-flow UI signals (ref.listen side-effect policy): the consent
    // controller signals; the screen presents the sheet / deep-links.
    ref.listen<ConsentUiSignal>(
      consentControllerProvider.select((ConsentControllerState s) => s.uiSignal),
      (ConsentUiSignal? prev, ConsentUiSignal next) {
        if (prev == next) return;
        final ConsentController consent =
            ref.read(consentControllerProvider.notifier);
        switch (next) {
          case ConsentUiSignal.showConsentSheet:
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const ConsentSheet(),
            ).then((_) {
              consent.uiSignalConsumed();
              controller.refreshPlaceRows();
            });
          case ConsentUiSignal.showSettingsFallback:
            // FM-7: OS-denied — never re-prompt; deep-link to system settings.
            ref.read(locationRepositoryProvider).openAppSettings();
            consent.uiSignalConsumed();
          case ConsentUiSignal.showSearchPrompt:
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const SearchSheet(),
            ).then((_) {
              consent.uiSignalConsumed();
              controller.refreshPlaceRows();
            });
          case ConsentUiSignal.showOsPrompt:
          case ConsentUiSignal.none:
            break;
        }
      },
    );

    return ResponsiveScaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        children: <Widget>[
          _group(context, strings.locationGroup, <Widget>[
            _locationToggle(context, ref, strings, state, controller),
            ListTile(
              title: Text(strings.savedCity),
              subtitle: Text(state.savedPlaceLabel ?? strings.notSet),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const SearchSheet(),
              ).then((_) => controller.refreshPlaceRows()),
            ),
            ListTile(
              title: Text(strings.locationPrecision),
              subtitle: Text(strings.locationPrecisionValue),
              trailing: const Icon(Icons.info_outline),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(strings.locationPrecision),
                  content: Text(strings.locationPrecisionExplainer),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(strings.dismiss),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          _group(context, strings.unitsGroup, <Widget>[
            _segmentedRow(
              context,
              label: strings.temperature,
              options: <String>[strings.celsius, strings.fahrenheit],
              selected: state.unitSystem.temp == TempUnit.celsius ? 0 : 1,
              onSelected: (int i) => controller.setTempUnit(
                  i == 0 ? TempUnit.celsius : TempUnit.fahrenheit),
            ),
            _segmentedRow(
              context,
              label: strings.wind,
              options: const <String>['km/h', 'mph', 'm/s'],
              selected: switch (state.unitSystem.wind) {
                WindUnit.kmh => 0,
                WindUnit.mph => 1,
                WindUnit.ms => 2,
              },
              onSelected: (int i) => controller.setWindUnit(
                  <WindUnit>[WindUnit.kmh, WindUnit.mph, WindUnit.ms][i]),
            ),
          ]),
          _group(context, strings.themeGroup, <Widget>[
            _segmentedRow(
              context,
              label: strings.theme,
              options: <String>[
                strings.themeSystem,
                strings.themeLight,
                strings.themeDark
              ],
              selected: switch (state.themeMode) {
                AppThemeMode.system => 0,
                AppThemeMode.light => 1,
                AppThemeMode.dark => 2,
              },
              onSelected: (int i) => controller.setThemeMode(
                  <AppThemeMode>[
                    AppThemeMode.system,
                    AppThemeMode.light,
                    AppThemeMode.dark
                  ][i]),
            ),
          ]),
          _group(context, strings.privacyGroup, <Widget>[
            ListTile(
              title: Text(strings.privacyNotice),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed('/privacy'),
            ),
            ListTile(
              title: Text(strings.whatWeStore),
              subtitle: Text(strings.whatWeStoreBody,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.info_outline),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(strings.whatWeStore),
                  content: Text(strings.whatWeStoreBody),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(strings.dismiss),
                    ),
                  ],
                ),
              ),
            ),
            SwitchListTile(
              title: Text(strings.crashReporting),
              subtitle: Text(strings.crashReportingBody),
              value: state.crashReportingEnabled,
              onChanged: controller.setCrashReporting,
            ),
            ListTile(
              title: Text(strings.deleteLocalData,
                  style: TextStyle(color: DesignTokens.error(context))),
              onTap: state.busy
                  ? null
                  : () => _confirmDelete(context, ref, strings, controller),
            ),
          ]),
          _group(context, strings.aboutGroup, <Widget>[
            ListTile(
              title: Text(strings.dataSource),
              subtitle: Text(strings.appVersion(state.appVersionLabel)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(DesignTokens.s16, DesignTokens.s16,
              DesignTokens.s16, DesignTokens.s4),
          child: Semantics(
            header: true,
            child: Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: DesignTokens.textSecondary(context),
                    )),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
          color: DesignTokens.surfaceSecondary(context),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _locationToggle(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations strings,
    SettingsState state,
    SettingsController controller,
  ) {
    final bool pending = state.osPermission == null;
    return SwitchListTile(
      title: Text(strings.useDeviceLocation),
      subtitle: pending
          ? const _PermissionShimmer()
          : state.osPermission == OsPermissionStatus.unableToDetermine
              ? Text(strings.openSettingsFailed)
              : null,
      value: state.locationEnabled,
      // While the OS query is pending (max 1 s) the toggle is inert —
      // never a stuck shimmer, never a wrong value (MEDIUM-8).
      onChanged: pending || state.busy
          ? null
          : (bool on) {
              if (on) {
                // Toggling ON re-triggers the consent sheet (design §3.5).
                ref.read(consentControllerProvider.notifier).beginFlow();
              } else {
                controller.revokeLocation();
              }
            },
    );
  }

  Widget _segmentedRow(
    BuildContext context, {
    required String label,
    required List<String> options,
    required int selected,
    required void Function(int) onSelected,
  }) {
    return ListTile(
      title: Text(label),
      trailing: SegmentedButton<int>(
        segments: <ButtonSegment<int>>[
          for (int i = 0; i < options.length; i++)
            ButtonSegment<int>(value: i, label: Text(options[i])),
        ],
        selected: <int>{selected},
        onSelectionChanged: (Set<int> s) => onSelected(s.first),
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations strings,
    SettingsController controller,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.deleteLocalDataTitle),
        content: Text(strings.deleteLocalDataBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await controller.deleteLocalData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.dataDeleted)),
      );
    }
  }
}

/// Indeterminate shimmer for the permission toggle (max 1 s — the controller
/// falls back to a disabled toggle after the cap).
class _PermissionShimmer extends StatelessWidget {
  const _PermissionShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: 120,
      decoration: BoxDecoration(
        color: DesignTokens.surfaceTertiary(context),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
