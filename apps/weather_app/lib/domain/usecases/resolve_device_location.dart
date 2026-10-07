// ResolveDeviceLocation: consent -> OS permission -> fix -> place name.
//
// AC-7: the OS grant is the enforcement point. ConsentState.granted with a
// denied OS permission throws AppFailure.locationDenied and NEVER issues a
// forecast call.

import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';

class ResolveDeviceLocation {
  final LocationRepository _location;

  ResolveDeviceLocation(this._location);

  Future<GeoPlace> call() async {
    final OsPermissionStatus permission = await _location.checkPermission();
    if (permission != OsPermissionStatus.granted) {
      throw const AppFailure.locationDenied();
    }
    return _location.resolveDevicePlace();
  }
}
