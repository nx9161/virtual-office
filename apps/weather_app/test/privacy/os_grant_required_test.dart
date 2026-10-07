// AC-7: the OS grant is the enforcement point.
//
// ResolveDeviceLocation must re-verify the LIVE OS permission before any
// location use. ConsentState.granted with a denied OS permission throws
// locationDenied and NEVER issues a forecast call or touches the fix.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/usecases/resolve_device_location.dart';

class _MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late _MockLocationRepository location;

  setUp(() {
    location = _MockLocationRepository();
  });

  test('OS denied -> locationDenied, resolveDevicePlace NEVER called', () async {
    when(() => location.checkPermission())
        .thenAnswer((_) async => OsPermissionStatus.denied);
    final ResolveDeviceLocation usecase = ResolveDeviceLocation(location);

    await expectLater(
      usecase.call(),
      throwsA(isA<LocationDeniedFailure>()),
    );
    verifyNever(() => location.resolveDevicePlace());
  });

  test('OS deniedForever -> locationDenied, resolveDevicePlace NEVER called',
      () async {
    when(() => location.checkPermission())
        .thenAnswer((_) async => OsPermissionStatus.deniedForever);

    await expectLater(
      ResolveDeviceLocation(location).call(),
      throwsA(isA<LocationDeniedFailure>()),
    );
    verifyNever(() => location.resolveDevicePlace());
  });

  test('OS granted -> resolves the device place', () async {
    final GeoPlace place = GeoPlace(
        name: 'Current location',
        admin1: null,
        country: 'Testland',
        countryCode: 'TT',
        lat: 52.52,
        lon: 13.41);
    when(() => location.checkPermission())
        .thenAnswer((_) async => OsPermissionStatus.granted);
    when(() => location.resolveDevicePlace())
        .thenAnswer((_) async => place);

    expect(await ResolveDeviceLocation(location).call(), place);
    verify(() => location.resolveDevicePlace()).called(1);
  });

  test('permission checked on EVERY call (no cached grant)', () async {
    when(() => location.checkPermission())
        .thenAnswer((_) async => OsPermissionStatus.granted);
    when(() => location.resolveDevicePlace()).thenAnswer((_) async => GeoPlace(
        name: 'X', admin1: null, country: 'Y', countryCode: null,
        lat: 0.0, lon: 0.0));

    final ResolveDeviceLocation usecase = ResolveDeviceLocation(location);
    await usecase.call();
    await usecase.call();
    verify(() => location.checkPermission()).called(2);
  });
}
