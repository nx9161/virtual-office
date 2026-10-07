// LocationDataSource: geolocator wrapper (device OS boundary).
//
// Foreground-only, REDUCED accuracy (coarse — the OS never grants us more
// than we need, and ADR-07 rounds to 2 dp immediately anyway). Fix timeout
// 15 s (PRD FM-10 -> AppFailure.locationTimeout).
//
// Permission-state nuance (HIGH-1.6): geolocator distinguishes `denied` from
// `deniedForever`; the repository maps these to the FM-7 never-re-prompt
// path vs. the settings deep-link card (FM-8).

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/domain/entities/app_settings.dart' show DevicePosition;
import 'package:weather_app/domain/repositories/location_repository.dart'
    show OsPermissionStatus;

class LocationDataSource {
  Future<bool> isServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<OsPermissionStatus> checkPermission() async {
    try {
      return _map(await Geolocator.checkPermission());
    } catch (_) {
      return OsPermissionStatus.unableToDetermine;
    }
  }

  Future<OsPermissionStatus> requestPermission() async {
    try {
      return _map(await Geolocator.requestPermission());
    } catch (_) {
      return OsPermissionStatus.unableToDetermine;
    }
  }

  OsPermissionStatus _map(LocationPermission p) => switch (p) {
        LocationPermission.always ||
        LocationPermission.whileInUse =>
          OsPermissionStatus.granted,
        LocationPermission.denied => OsPermissionStatus.denied,
        LocationPermission.deniedForever =>
          OsPermissionStatus.deniedForever,
        LocationPermission.unableToDetermine =>
          OsPermissionStatus.unableToDetermine,
      };

  /// One-shot foreground fix. Throws AppFailure variants (never raw
  /// geolocator exceptions — the repository maps everything).
  Future<DevicePosition> getCurrentPosition() async {
    try {
      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.reduced,
          timeLimit: AppConstants.locationFixTimeout,
        ),
      ).timeout(
          AppConstants.locationFixTimeout + const Duration(seconds: 2));
      // Rounding happens ONCE here at the datasource boundary (ADR-07);
      // the precise fix never leaves this method.
      return DevicePosition.rounded(pos.latitude, pos.longitude);
    } on TimeoutException {
      throw const AppFailure.locationTimeout();
    } on LocationServiceDisabledException {
      throw const AppFailure.locationServicesDisabled();
    } on PermissionDeniedException {
      throw const AppFailure.locationDenied();
    } catch (_) {
      throw const AppFailure.locationTimeout();
    }
  }

  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {}
  }
}
