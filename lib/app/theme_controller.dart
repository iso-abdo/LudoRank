
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  final Box _settingsBox;

  late ThemeMode _themeMode;

  ThemeController({
    required Box settingsBox,
  }) : _settingsBox = settingsBox {
    final savedMode = _settingsBox.get(
      _themeKey,
      defaultValue: 'system',
    );

    _themeMode = _parseThemeMode(savedMode);
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeMode _parseThemeMode(dynamic value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    final savedValue = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    // Save the new setting before updating the UI.
    await _settingsBox.put(_themeKey, savedValue);

    _themeMode = mode;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    await setThemeMode(newMode);
  }
}
