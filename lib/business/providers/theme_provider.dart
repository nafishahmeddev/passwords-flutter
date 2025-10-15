import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum ThemeMode { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColor = true;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _themeModeKey = 'theme_mode';
  static const String _useDynamicColorKey = 'use_dynamic_color';

  ThemeProvider() {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColor => _useDynamicColor;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> _loadSettings() async {
    final themeModeStr = await _secureStorage.read(key: _themeModeKey);
    final dynamicColorStr = await _secureStorage.read(key: _useDynamicColorKey);

    if (themeModeStr != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeStr,
        orElse: () => ThemeMode.system,
      );
    }

    if (dynamicColorStr != null) {
      _useDynamicColor = dynamicColorStr == 'true';
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _secureStorage.write(key: _themeModeKey, value: mode.name);
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool value) async {
    if (_useDynamicColor == value) return;

    _useDynamicColor = value;
    await _secureStorage.write(
      key: _useDynamicColorKey,
      value: value.toString(),
    );
    notifyListeners();
  }
}

// Extension method to convert ThemeMode enum to a user-friendly string
extension ThemeModeExtension on ThemeMode {
  String get toDisplayString {
    switch (this) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}
