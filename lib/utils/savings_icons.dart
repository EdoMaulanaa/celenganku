import 'package:flutter/material.dart';

/// A map of string keys to Material IconData for savings pot icons
/// This is used for storing icons in the database and retrieving them for display
class SavingsIcons {
  /// Map of icon identifiers to IconData objects
  static const Map<String, IconData> savingsIconMap = {
    "savings": Icons.savings,
    "travel": Icons.airplanemode_active,
    "education": Icons.school,
    "health": Icons.favorite,
    "shopping": Icons.shopping_cart,
    "wallet": Icons.account_balance_wallet,
    "home": Icons.home,
    "emergency": Icons.warning,
    "gift": Icons.card_giftcard,
    "food": Icons.restaurant,
    "entertainment": Icons.movie,
    "tech": Icons.computer,
    "pet": Icons.pets,
    "car": Icons.directions_car,
    "sport": Icons.sports_basketball,
    "beauty": Icons.spa,
    "clothing": Icons.checkroom,
    "baby": Icons.child_care,
    "investment": Icons.trending_up,
    "vacation": Icons.beach_access,
    "wedding": Icons.celebration,
    "retirement": Icons.elderly,
    "fitness": Icons.fitness_center,
    "holiday": Icons.event,
  };

  /// Get IconData from a string key
  static IconData getIconData(String? iconKey) {
    if (iconKey == null || iconKey.isEmpty) {
      return Icons.savings; // Default icon
    }

    return savingsIconMap[iconKey] ?? Icons.savings;
  }

  /// Get a list of all available icon keys
  static List<String> getAllIconKeys() {
    return savingsIconMap.keys.toList();
  }
} 