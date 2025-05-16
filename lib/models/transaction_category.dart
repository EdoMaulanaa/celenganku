import 'package:flutter/material.dart';
import 'transaction.dart';

class TransactionCategory {
  final String id;
  final String name;
  final TransactionType type;
  final String? iconName;
  final Color? color;
  final bool isDefault;
  final DateTime createdAt;

  // Constructor
  TransactionCategory({
    required this.id,
    required this.name,
    required this.type,
    this.iconName,
    this.color,
    this.isDefault = false,
    required this.createdAt,
  });

  // Create from Supabase JSON
  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    // Parse color from hex string
    Color? colorFromHex;
    if (json['color'] != null) {
      final hexColor = json['color'];
      if (hexColor.startsWith('#') && hexColor.length == 7) {
        try {
          colorFromHex = Color(
            int.parse('FF${hexColor.substring(1)}', radix: 16),
          );
        } catch (e) {
          // Default to null if parsing fails
        }
      }
    }

    return TransactionCategory(
      id: json['id'],
      name: json['name'],
      type: json['type'] == 'income' 
          ? TransactionType.income 
          : TransactionType.expense,
      iconName: json['icon_name'],
      color: colorFromHex,
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    // Convert color to hex string
    String? colorToHex;
    if (color != null) {
      final hexValue = color!.value.toRadixString(16).padLeft(8, '0');
      colorToHex = '#${hexValue.substring(2)}';
    }
    
    final Map<String, dynamic> data = {
      'name': name,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'icon_name': iconName,
      'color': colorToHex,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
    
    // Add ID only if it's not empty
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    
    return data;
  }

  // Get Icon from iconName
  IconData get icon {
    // Attempt to map common icon names to Material icons
    switch (iconName) {
      case 'work': return Icons.work;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'trending_up': return Icons.trending_up;
      case 'stars': return Icons.stars;
      case 'attach_money': return Icons.attach_money;
      case 'restaurant': return Icons.restaurant;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'directions_car': return Icons.directions_car;
      case 'home': return Icons.home;
      case 'theaters': return Icons.theaters;
      case 'favorite': return Icons.favorite;
      case 'school': return Icons.school;
      case 'face': return Icons.face;
      case 'receipt': return Icons.receipt;
      case 'flight': return Icons.flight;
      case 'more_horiz': return Icons.more_horiz;
      default: return type == TransactionType.income 
          ? Icons.arrow_upward 
          : Icons.arrow_downward;
    }
  }
} 