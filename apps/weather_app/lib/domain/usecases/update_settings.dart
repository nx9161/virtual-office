// UpdateSettings: settings mutations (FM-20 debounce owned by controller).

import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';

class UpdateSettings {
  final SettingsRepository _settings;

  UpdateSettings(this._settings);

  Future<void> setUnitSystem(UnitSystem units) =>
      _settings.setUnitSystem(units);

  Future<void> setThemeMode(AppThemeMode mode) => _settings.setThemeMode(mode);
}
