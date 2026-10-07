// ConsentController: the §4.3 consent flow + HIGH-1 fixes, plain Notifier,
// keepAlive.
//
// Sequence (US-1):
//   1. beginFlow(): 30-day suppression check (C4) -> declined+suppressed =
//      no UI; OS-denied = settings fallback (FM-7 never re-prompt); else the
//      in-app consent sheet.
//   2. allowFromSheet(): in-app consent recorded FIRST (US-1 AC2), THEN the
//      OS prompt. consentFlowStep=osPromptPending is persisted BEFORE the
//      prompt so a process kill resumes (HIGH-1).
//   3. onOsPromptResult(): grant -> resolve -> save (device-sourced) ->
//      step=done; denial -> recordOsDenied (never re-prompt).
//   4. notNow(): in-app decline -> 30-day suppression, route to search.
//   5. osPromptPending resume at startup: re-checks the live OS status and
//      continues or completes accordingly.
//
// AC-7: the OS grant is re-verified live before any location use.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/error/error_mapper.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/data/di/data_providers.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';
import 'package:weather_app/features/consent/consent_state.dart';
import 'package:weather_app/features/home/home_controller.dart';

class ConsentController extends Notifier<ConsentControllerState> {
  bool _disposed = false;

  LocationRepository get _location => ref.read(locationRepositoryProvider);
  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  @override
  ConsentControllerState build() {
    ref.onDispose(() => _disposed = true);
    // HIGH-1: resume a flow that died during the OS prompt.
    Future.microtask(_resumePendingOsPrompt);
    return const ConsentControllerState();
  }

  Future<void> _resumePendingOsPrompt() async {
    if (_disposed) return;
    if (_settings.settings.consentFlowStep != ConsentFlowStep.osPromptPending) {
      return;
    }
    final OsPermissionStatus status = await _location.checkPermission();
    if (_disposed) return;
    await onOsPromptResult(status);
  }

  /// Entry point: Settings toggle ON or the welcome screen's "Use my location".
  Future<void> beginFlow() async {
    final ConsentState consent = _location.consentState;
    if (consent == ConsentState.granted) {
      // Already granted: re-resolve the device location directly.
      await _completeDeviceFlow();
      return;
    }
    if (consent == ConsentState.osDenied) {
      // FM-7: never re-prompt after OS denial — deep-link instead.
      if (!_disposed) {
        state = state.copyWith(uiSignal: ConsentUiSignal.showSettingsFallback);
      }
      return;
    }
    if (consent == ConsentState.declined && !_location.canPromptForConsent) {
      // C4: 30-day suppression still active — silently route to search.
      if (!_disposed) {
        state = state.copyWith(uiSignal: ConsentUiSignal.showSearchPrompt);
      }
      return;
    }
    if (!_disposed) {
      state = state.copyWith(uiSignal: ConsentUiSignal.showConsentSheet);
    }
  }

  /// Sheet's "Allow": record in-app consent FIRST (US-1 AC2), persist the
  /// resume step, then signal the UI to invoke the OS prompt.
  Future<void> allowFromSheet() async {
    state = state.copyWith(busy: true, clearFailure: true);
    await _location.grantConsent();
    await _location.setConsentFlowStep(ConsentFlowStep.osPromptPending);
    if (!_disposed) {
      state = state.copyWith(
          uiSignal: ConsentUiSignal.showOsPrompt, busy: false);
    }
  }

  /// Sheet's "Not now": in-app decline -> 30-day suppression (C4).
  Future<void> notNow() async {
    await _location.declineConsent();
    if (!_disposed) {
      state = state.copyWith(uiSignal: ConsentUiSignal.showSearchPrompt);
    }
  }

  /// Called by the UI after the OS permission prompt resolves.
  Future<void> onOsPromptResult(OsPermissionStatus status) async {
    if (_disposed) return;
    state = state.copyWith(busy: true);
    switch (status) {
      case OsPermissionStatus.granted:
        await _completeDeviceFlow();
      case OsPermissionStatus.denied:
      case OsPermissionStatus.deniedForever:
        // FM-7: OS denial = never re-prompt in-app.
        await _location.recordOsDenied();
        if (!_disposed) {
          state = state.copyWith(
            uiSignal: ConsentUiSignal.showSearchPrompt,
            busy: false,
          );
        }
      case OsPermissionStatus.unableToDetermine:
        // Can't determine the OS state: don't block — route to search
        // (the app works fully without location).
        if (!_disposed) {
          state = state.copyWith(
            uiSignal: ConsentUiSignal.showSearchPrompt,
            busy: false,
          );
        }
    }
  }

  Future<void> _completeDeviceFlow() async {
    try {
      final GeoPlace? previous = _settings.savedPlace;
      final bool wasDevice =
          previous != null && _settings.savedPlaceIsDeviceSourced;
      final GeoPlace place =
          await ref.read(resolveDeviceLocationProvider).call();
      if (_disposed) return;
      await _location.savePlace(place, deviceSourced: true);
      await _location.setConsentFlowStep(ConsentFlowStep.done);
      if (!_disposed) {
        state = state.copyWith(
          // Undo only when we replaced a real saved city (design §5.2).
          justReplacedPlace:
              (previous != null && !wasDevice) ? previous : null,
          uiSignal: ConsentUiSignal.none,
          busy: false,
        );
      }
      await ref
          .read(homeControllerProvider.notifier)
          .selectPlace(place, deviceSourced: true);
    } on AppFailure catch (f) {
      if (!_disposed) {
        state = state.copyWith(failure: f, busy: false);
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(failure: mapToFailure(e), busy: false);
      }
    }
  }

  /// Undo (5 s snackbar): restores the city the device location replaced.
  Future<void> undoDevicePlace() async {
    final GeoPlace? previous = state.justReplacedPlace;
    if (previous == null) return;
    await _location.savePlace(previous, deviceSourced: false);
    await ref.read(homeControllerProvider.notifier).reloadAfterRevoke();
    if (!_disposed) {
      state = state.copyWith(clearReplacedPlace: true);
    }
  }

  void clearJustReplaced() {
    if (!_disposed) state = state.copyWith(clearReplacedPlace: true);
  }

  void uiSignalConsumed() {
    if (!_disposed) {
      state = state.copyWith(uiSignal: ConsentUiSignal.none);
    }
  }

  void clearFailure() {
    if (!_disposed) state = state.copyWith(clearFailure: true);
  }

  /// Test hook.
  ConsentFlowStep get flowStep => _settings.settings.consentFlowStep;
}

/// keepAlive: the flow must survive sheet dismissal / navigation.
final consentControllerProvider =
    NotifierProvider<ConsentController, ConsentControllerState>(
        ConsentController.new);
