// Consent flow state (§4.3 + HIGH-1 fixes).
//
// The controller exposes one-shot UI signals (sheet / OS prompt / fallback);
// the screen presents them and reports back. consentFlowStep is persisted in
// SharedPreferences so a kill during the OS prompt resumes correctly.

import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

/// One-shot UI signals. Consumed by the screen via uiSignalConsumed().
enum ConsentUiSignal {
  none,
  showConsentSheet,
  showOsPrompt,
  showSettingsFallback,
  showSearchPrompt,
}

class ConsentControllerState {
  final ConsentUiSignal uiSignal;

  /// Previous saved city when device location replaced it — drives the
  /// "Using your approximate location" + Undo snackbar (design §5.2).
  final GeoPlace? justReplacedPlace;
  final AppFailure? failure;
  final bool busy;

  const ConsentControllerState({
    this.uiSignal = ConsentUiSignal.none,
    this.justReplacedPlace,
    this.failure,
    this.busy = false,
  });

  ConsentControllerState copyWith({
    ConsentUiSignal? uiSignal,
    GeoPlace? justReplacedPlace,
    bool clearReplacedPlace = false,
    AppFailure? failure,
    bool clearFailure = false,
    bool? busy,
  }) {
    return ConsentControllerState(
      uiSignal: uiSignal ?? this.uiSignal,
      justReplacedPlace: clearReplacedPlace
          ? null
          : (justReplacedPlace ?? this.justReplacedPlace),
      failure: clearFailure ? null : (failure ?? this.failure),
      busy: busy ?? this.busy,
    );
  }
}
