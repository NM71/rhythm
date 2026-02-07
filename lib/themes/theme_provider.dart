import 'package:flutter/material.dart';
import 'package:rhythm/themes/dark_mode.dart';
import 'package:rhythm/themes/light_mode.dart';

class ThemeProvider extends ChangeNotifier{
  // initially, light mode
  ThemeData _themeData = lightMode;

  // get theme
  ThemeData get themeData => _themeData;

  // is Dark Mode
  bool get isDarkMode => _themeData == darkMode; // returns a bool value on the basis of the condition output


  // set theme
  set themeData(ThemeData themeData){
    _themeData = themeData;

    // update UI
    notifyListeners(); // to notify all the listeners about the change in theme
  }

  // toggle theme
  void toggleTheme(){
    if(_themeData == lightMode){
      themeData = darkMode;
    }
    else{
      themeData = lightMode;
    }
  }
}