import 'package:flutter/material.dart';
import 'package:rhythm/themes/dark_mode.dart';
import 'package:rhythm/themes/light_mode.dart';

class ThemeProvider extends ChangeNotifier {
  // Initially, light mode
  ThemeData _themeData = lightMode;

  // Get current theme
  ThemeData get themeData => _themeData;

  // Check if dark mode is active
  bool get isDarkMode => _themeData == darkMode;

  // Set theme
  set themeData(ThemeData themeData) {
    _themeData = themeData;

    // Notify UI to rebuild
    notifyListeners();
  }

  // Toggle between light and dark mode
  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode; // Assign dark mode
    } else {
      themeData = lightMode; // Assign light mode
    }
  }
}
