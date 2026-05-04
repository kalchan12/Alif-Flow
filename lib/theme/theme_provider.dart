import 'package:flutter/material.dart';

/// Manages the app's theme mode (light/dark) and notifies listeners on change.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

/// Global theme provider instance accessible throughout the app.
final themeProvider = ThemeProvider();
