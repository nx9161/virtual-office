// SearchSheet (S-2): city search bottom sheet.
//
// Search bar at top (autofocus, maxLength 100 — the validation layer
// re-enforces it, AC-3); "Use device location" row; recents (≤5, tappable,
// clearable); results; offline disables the field but keeps recents tappable
// (design §3.2). Selecting a place records it, loads its weather, announces
// "Showing X", and pops the sheet.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/failure_presentation.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/network/connectivity_provider.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/features/common/announcer.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/error_banner.dart';
import 'package:weather_app/features/consent/consent_controller.dart';
import 'package:weather_app/features/search/search_controller.dart';
import 'package:weather_app/features/search/search_state.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class SearchSheet extends ConsumerStatefulWidget {
  const SearchSheet({super.key});

  @override
  ConsumerState<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<SearchSheet> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final SearchScreenState state = ref.watch(searchControllerProvider);
    final bool online =
        ref.watch(isOnlineProvider).valueOrNull ?? true;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: DesignTokens.s16,
          right: DesignTokens.s16,
          top: DesignTokens.s12,
          bottom: MediaQuery.of(context).viewInsets.bottom + DesignTokens.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                strings.chooseACity,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            TextField(
              controller: _text,
              autofocus: true,
              enabled: online,
              maxLength: AppConstants.searchQueryMaxChars,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: online
                    ? strings.searchCitiesHint
                    : strings.searchNeedsConnection,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _text.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _text.clear();
                          ref
                              .read(searchControllerProvider.notifier)
                              .onQueryChanged('');
                          setState(() {});
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (String v) {
                ref
                    .read(searchControllerProvider.notifier)
                    .onQueryChanged(v);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: Text(strings.useDeviceLocation),
              subtitle: Text(strings.coarsePrecisionOn),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(consentControllerProvider.notifier).beginFlow();
              },
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: _body(context, strings, state, online),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations strings,
      SearchScreenState state, bool online) {
    return switch (state) {
      SearchIdle(recentPlaces: final List<GeoPlace> recents) ||
      SearchOffline(recentPlaces: final List<GeoPlace> recents) =>
        _recentsList(context, strings, recents, offline: !online),
      SearchLoading() => const _ResultsShimmer(),
      SearchResults(
        results: final List<GeoPlace> results,
        recentPlaces: final List<GeoPlace> recents
      ) =>
        ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (final GeoPlace p in results) _placeTile(context, p),
            if (recents.isNotEmpty) ...<Widget>[
              const Divider(),
              _recentsList(context, strings, recents),
            ],
          ],
        ),
      // FM-12: single source of truth for the empty-state headline is
      // FailurePresentationMapper (PRD §11 exact copy); the sheet never
      // renders its own variant.
      SearchEmpty(queryEcho: final String echo) => Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s24),
            child: Text(
              FailurePresentationMapper.map(AppFailure.noResults(echo))
                  .headline,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      SearchError(
        failure: final AppFailure failure,
        recentPlaces: final List<GeoPlace> recents
      ) =>
        ListView(
          shrinkWrap: true,
          children: <Widget>[
            ErrorBanner(
              failure: failure,
              presentation: FailurePresentationMapper.forSearch(
                  FailurePresentationMapper.map(failure)),
              onAction: (FailureAction a) {
                if (a == FailureAction.dismiss) {
                  ref.read(searchControllerProvider.notifier).dismissError();
                }
              },
              onDismiss: () =>
                  ref.read(searchControllerProvider.notifier).dismissError(),
            ),
            _recentsList(context, strings, recents),
          ],
        ),
    };
  }

  Widget _placeTile(BuildContext context, GeoPlace place) {
    return ListTile(
      leading: const Icon(Icons.place_outlined),
      title: Text(place.name),
      subtitle: Text(place.admin1 != null
          ? '${place.admin1}, ${place.country}'
          : place.country),
      onTap: () => _select(context, place),
    );
  }

  Widget _recentsList(BuildContext context, AppLocalizations strings,
      List<GeoPlace> recents,
      {bool offline = false}) {
    if (recents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s24),
          child: Text(
            offline ? strings.searchNeedsConnection : strings.noRecentSearches,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: DesignTokens.s16),
              child: Text(
                strings.recentSearches,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(searchControllerProvider.notifier).clearRecents(),
              child: Text(strings.clearRecents),
            ),
          ],
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: recents.length,
            itemBuilder: (BuildContext context, int i) {
              final GeoPlace p = recents[i];
              return Dismissible(
                key: ValueKey<String>('${p.name}|${p.lat}|${p.lon}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => ref
                    .read(searchControllerProvider.notifier)
                    .removeRecent(p),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding:
                      const EdgeInsets.only(right: DesignTokens.s16),
                  color: DesignTokens.error(context).withValues(alpha: 0.15),
                  child: Icon(Icons.delete,
                      color: DesignTokens.error(context)),
                ),
                child: _placeTile(context, p),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _select(BuildContext context, GeoPlace place) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    await ref.read(searchControllerProvider.notifier).selectPlace(place);
    if (context.mounted) {
      Announcer.announce(strings.showingPlace(place.name));
      Navigator.of(context).pop();
    }
  }
}

class _ResultsShimmer extends StatelessWidget {
  const _ResultsShimmer();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: 5,
        separatorBuilder: (_, __) =>
            const SizedBox(height: DesignTokens.s8),
        itemBuilder: (_, __) => Container(
          height: 56,
          decoration: BoxDecoration(
            color: DesignTokens.surfaceTertiary(context),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
