// HomeScreen (S-1): current conditions + hourly/daily previews.
//
// State contract (R-8): firstLoad (skeleton) | ready (data + staleness
// property + optional banner) | failure (fullscreen card, no data).
// Side effects (navigation, sheets, snackbars) are triggered here from
// ref.listen — the failure->UI copy comes from FailurePresentationMapper.

import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:weather_app/core/config/app_providers.dart';
import 'package:weather_app/core/error/failure_presentation.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/network/connectivity_provider.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/core/units/weather_formatter.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/error_banner.dart';
import 'package:weather_app/features/common/widgets/error_card.dart';
import 'package:weather_app/features/common/widgets/offline_banner.dart';
import 'package:weather_app/features/common/widgets/provenance_strip.dart';
import 'package:weather_app/features/common/widgets/responsive_scaffold.dart';
import 'package:weather_app/features/common/widgets/skeleton.dart';
import 'package:weather_app/features/home/home_controller.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/features/home/widgets/metrics_grid.dart';
import 'package:weather_app/features/home/widgets/daily_preview.dart';
import 'package:weather_app/features/home/widgets/hero_card.dart';
import 'package:weather_app/features/home/widgets/hourly_preview.dart';
import 'package:weather_app/features/search/search_sheet.dart';
import 'package:weather_app/features/settings/settings_controller.dart';
import 'package:weather_app/features/settings/settings_state.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeScreenState state = ref.watch(homeControllerProvider);
    final AppLocalizations strings = AppLocalizations.of(context);

    return switch (state) {
      HomeFirstLoad() => ResponsiveScaffold(
          appBar: AppBar(title: Text(strings.appTitle)),
          body: const SkeletonGroup(child: _HomeSkeleton()),
        ),
      HomeNeedsLocationChoice() ||
      HomeEmpty() =>
        ResponsiveScaffold(
          appBar: AppBar(title: Text(strings.appTitle)),
          body: const SizedBox.shrink(),
        ),
      HomeReady(
        view: final ForecastView view,
        staleness: final Staleness staleness,
        isRefreshing: final bool isRefreshing,
        bannerFailure: final AppFailure? bannerFailure
      ) =>
        _ReadyHome(
          view: view,
          staleness: staleness,
          isRefreshing: isRefreshing,
          bannerFailure: bannerFailure,
        ),
      HomeFailure(failure: final AppFailure failure) => ResponsiveScaffold(
          appBar: AppBar(
            title: Text(strings.appTitle),
            actions: <Widget>[_SearchButton(), _SettingsButton()],
          ),
          body: ErrorCard(
            presentation: FailurePresentationMapper.map(failure),
            onAction: (FailureAction a) =>
                _onFailureAction(context, ref, a),
          ),
        ),
    };
  }

  void _onFailureAction(
      BuildContext context, WidgetRef ref, FailureAction action) {
    final HomeController controller = ref.read(homeControllerProvider.notifier);
    switch (action) {
      case FailureAction.retry:
        controller.retry();
      case FailureAction.searchInstead:
        _openSearch(context);
      case FailureAction.useDeviceLocation:
        _openSearch(context); // search sheet hosts "Use device location"
      case FailureAction.openSystemSettings:
        ref.read(locationRepositoryProvider).openAppSettings();
      case FailureAction.openLocationSettings:
        ref.read(locationRepositoryProvider).openLocationSettings();
      case FailureAction.dismiss:
        controller.clearBanner();
      case FailureAction.none:
        break;
    }
  }

  void _openSearch(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SearchSheet(),
    );
  }
}

class _SearchButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.search),
      tooltip: strings.searchTooltip,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const SearchSheet(),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: strings.settingsTooltip,
      onPressed: () => Navigator.of(context).pushNamed('/settings'),
    );
  }
}

class _ReadyHome extends ConsumerWidget {
  final ForecastView view;
  final Staleness staleness;
  final bool isRefreshing;
  final AppFailure? bannerFailure;

  const _ReadyHome({
    required this.view,
    required this.staleness,
    required this.isRefreshing,
    required this.bannerFailure,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool showOffline = staleness is OfflineStaleStaleness;
    final bool staleWarning = switch (staleness) {
      StaleStaleness(age: final Duration a) => a.inMinutes > 30,
      OfflineStaleStaleness(age: final Duration a) => a.inMinutes > 30,
      FreshStaleness() => false,
    };

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(view.placeLabel,
                style: Theme.of(context).textTheme.titleMedium),
            _UpdatedAgo(
              fetchedAtUtc: view.fetchedAtUtc,
              warning: staleWarning,
            ),
          ],
        ),
        actions: <Widget>[_SearchButton(), _SettingsButton()],
      ),
      body: Column(
        children: <Widget>[
          if (showOffline)
            OfflineBanner(detail: view.updatedTime)
          else if (bannerFailure != null)
            ErrorBanner(
              failure: bannerFailure!,
              presentation: FailurePresentationMapper.map(bannerFailure!),
              onAction: (FailureAction a) =>
                  _onBannerAction(context, ref, a),
              onDismiss: () =>
                  ref.read(homeControllerProvider.notifier).clearBanner(),
            ),
          if (isRefreshing)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _onRefresh(context, ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  const SizedBox(height: DesignTokens.s8),
                  HeroCard(view: view),
                  const SizedBox(height: DesignTokens.s8),
                  ProvenanceStrip(updatedTimeLabel: view.updatedTime),
                  if (view.deviceTimezoneFallback)
                    Text(
                      strings.deviceTimezoneNote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DesignTokens.textTertiary(context),
                          ),
                    ),
                  const SizedBox(height: DesignTokens.s16),
                  MetricsGrid(view: view),
                  const SizedBox(height: DesignTokens.s16),
                  HourlyPreview(
                    view: view,
                    onSeeAll: () =>
                        Navigator.of(context).pushNamed('/hourly'),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  DailyPreview(
                    view: view,
                    onSeeAll: () =>
                        Navigator.of(context).pushNamed('/daily'),
                  ),
                  if (view.isDeviceLocation) ...<Widget>[
                    const SizedBox(height: DesignTokens.s16),
                    OutlinedButton(
                      onPressed: () => _openSearchStatic(context),
                      child: Text(strings.changeLocation),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.s24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh(BuildContext context, WidgetRef ref) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool online = ref.read(isOnlineProvider).value ?? true;
    if (!online) {
      // Design §3.1: refresh disabled offline, with explanation on tap.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.pullToRefreshOffline)),
        );
      }
      return;
    }
    await ref.read(homeControllerProvider.notifier).refresh();
  }

  void _onBannerAction(
      BuildContext context, WidgetRef ref, FailureAction action) {
    final HomeController controller = ref.read(homeControllerProvider.notifier);
    switch (action) {
      case FailureAction.retry:
        controller.retry();
      case FailureAction.searchInstead:
        _openSearchStatic(context);
      case FailureAction.useDeviceLocation:
        _openSearchStatic(context);
      case FailureAction.openSystemSettings:
        ref.read(locationRepositoryProvider).openAppSettings();
      case FailureAction.openLocationSettings:
        ref.read(locationRepositoryProvider).openLocationSettings();
      case FailureAction.dismiss:
        controller.clearBanner();
      case FailureAction.none:
        break;
    }
  }

  void _openSearchStatic(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SearchSheet(),
    );
  }
}

/// "Updated X min ago" ticker: rebuilds every 30 s without touching the rest
/// of the screen (select discipline — frontend MEDIUM-6).
class _UpdatedAgo extends ConsumerStatefulWidget {
  final DateTime fetchedAtUtc;
  final bool warning;

  const _UpdatedAgo({required this.fetchedAtUtc, required this.warning});

  @override
  ConsumerState<_UpdatedAgo> createState() => _UpdatedAgoState();
}

class _UpdatedAgoState extends ConsumerState<_UpdatedAgo> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UnitSystem units = ref.watch(
        settingsControllerProvider.select((SettingsState s) => s.unitSystem));
    final Locale locale = ref.watch(localeProvider);
    final Clock clock = ref.watch(clockProvider);
    final String label = WeatherFormatter(
      units: units,
      locale: locale,
      clock: clock,
    ).updatedAgoLabel(widget.fetchedAtUtc);
    return Text(
      'Updated $label',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: widget.warning
                ? DesignTokens.warning(context)
                : DesignTokens.textTertiary(context),
          ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: DesignTokens.s8),
        SkeletonBlock(height: 220),
        SizedBox(height: DesignTokens.s16),
        Row(
          children: <Widget>[
            Expanded(child: SkeletonBlock(height: 96)),
            SizedBox(width: DesignTokens.s12),
            Expanded(child: SkeletonBlock(height: 96)),
          ],
        ),
        SizedBox(height: DesignTokens.s12),
        Row(
          children: <Widget>[
            Expanded(child: SkeletonBlock(height: 96)),
            SizedBox(width: DesignTokens.s12),
            Expanded(child: SkeletonBlock(height: 96)),
          ],
        ),
        SizedBox(height: DesignTokens.s16),
        SkeletonBlock(height: 120),
      ],
    );
  }
}
