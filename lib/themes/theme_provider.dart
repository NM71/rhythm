import 'package:flutter/material.dart';
import 'package:rhythm/themes/dark_mode.dart';
import 'package:rhythm/themes/light_mode.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeBoxName = 'theme_box';
  static const String _isDarkModeKey = 'isDarkMode';

  ThemeData _themeData = lightMode;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    _saveTheme(themeData == darkMode);
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_themeBoxName);
    final isDark = box.get(_isDarkModeKey, defaultValue: false);
    _themeData = isDark ? darkMode : lightMode;
    notifyListeners();
  }

  Future<void> _saveTheme(bool isDark) async {
    final box = await Hive.openBox(_themeBoxName);
    await box.put(_isDarkModeKey, isDark);
  }

  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}
