import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  // The key for storing theme preference
  static const themePreferenceKey = 'theme_preference';
  
  // Default to light theme as specified in PRD
  ThemeMode _themeMode = ThemeMode.light;
  
  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;
  
  // Check if dark mode is active
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Constructor loads saved theme preference
  ThemeProvider() {
    _loadThemePreference();
  }

  // Toggle between light and dark theme
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
      ? ThemeMode.dark 
      : ThemeMode.light;
    
    _saveThemePreference();
    notifyListeners();
  }

  // Set specific theme mode
  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    _saveThemePreference();
    notifyListeners();
  }

  // Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedTheme = prefs.getString(themePreferenceKey);
      
      if (storedTheme != null) {
        _themeMode = storedTheme == 'dark' 
          ? ThemeMode.dark 
          : ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      // Fallback to default light theme
      _themeMode = ThemeMode.light;
    }
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        themePreferenceKey, 
        _themeMode == ThemeMode.dark ? 'dark' : 'light'
      );
    } catch (e) {
      // Handle error silently
    }
  }

  // Get current theme data based on mode
  ThemeData getTheme() {
    return _themeMode == ThemeMode.dark 
      ? AppTheme.darkTheme() 
      : AppTheme.lightTheme();
  }
} 