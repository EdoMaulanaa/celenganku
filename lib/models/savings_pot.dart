import 'package:flutter/material.dart';

class SavingsPot {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String? thumbnailUrl;
  final double currentBalance;
  final double? targetAmount;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor
  SavingsPot({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    this.thumbnailUrl,
    required this.currentBalance,
    this.targetAmount,
    this.targetDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Supabase JSON
  factory SavingsPot.fromJson(Map<String, dynamic> json) {
    return SavingsPot(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      currentBalance: (json['current_balance'] ?? 0).toDouble(),
      targetAmount: json['target_amount'] != null 
        ? (json['target_amount']).toDouble()
        : null,
      targetDate: json['target_date'] != null 
        ? DateTime.parse(json['target_date'])
        : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'name': name,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'current_balance': currentBalance,
      'target_amount': targetAmount,
      'target_date': targetDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Add ID only if it's not empty
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    
    return data;
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (targetAmount == null || targetAmount == 0) {
      return 0;
    }
    
    final progress = (currentBalance / targetAmount!) * 100;
    return progress > 100 ? 100 : progress;
  }

  // Copy with method for updating
  SavingsPot copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? thumbnailUrl,
    double? currentBalance,
    double? targetAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsPot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      currentBalance: currentBalance ?? this.currentBalance,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 