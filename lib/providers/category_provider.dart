import 'package:flutter/material.dart';
import '../models/transaction_category.dart';
import '../models/transaction.dart';
import '../services/supabase_service.dart';

enum CategoryStatus {
  initial,
  loading,
  loaded,
  error,
}

class CategoryProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  // Status
  CategoryStatus _status = CategoryStatus.initial;
  CategoryStatus get status => _status;
  
  // Lists of categories by type
  List<TransactionCategory> _incomeCategories = [];
  List<TransactionCategory> _expenseCategories = [];
  
  List<TransactionCategory> get incomeCategories => _incomeCategories;
  List<TransactionCategory> get expenseCategories => _expenseCategories;
  
  // All categories combined
  List<TransactionCategory> get allCategories => 
      [..._incomeCategories, ..._expenseCategories];
  
  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // Constructor
  CategoryProvider() {
    // Delay initial loading to avoid calling during build phase
    Future.microtask(() => loadCategories());
  }
  
  // Load all categories
  Future<void> loadCategories() async {
    if (!_supabaseService.isAuthenticated) return;
    
    try {
      _status = CategoryStatus.loading;
      notifyListeners();
      
      final categories = await _supabaseService.getTransactionCategories();
      
      // Split into income and expense categories
      _incomeCategories = categories
          .where((cat) => cat.type == TransactionType.income)
          .toList();
      
      _expenseCategories = categories
          .where((cat) => cat.type == TransactionType.expense)
          .toList();
      
      _status = CategoryStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = CategoryStatus.error;
      _errorMessage = 'Failed to load categories: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Get category by ID
  TransactionCategory? getCategoryById(String? id) {
    if (id == null) return null;
    
    try {
      return allCategories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Create a custom category
  Future<bool> createCategory({
    required String name,
    required TransactionType type,
    String? iconName,
    Color? color,
  }) async {
    if (!_supabaseService.isAuthenticated) return false;
    
    try {
      _status = CategoryStatus.loading;
      notifyListeners();
      
      final now = DateTime.now();
      
      // Create new category
      final newCategory = TransactionCategory(
        id: '', // Let Supabase generate the UUID
        name: name,
        type: type,
        iconName: iconName,
        color: color,
        isDefault: false,
        createdAt: now,
      );
      
      // Save to database
      final savedCategory = 
          await _supabaseService.createTransactionCategory(newCategory);
      
      // Add to local list
      if (type == TransactionType.income) {
        _incomeCategories.add(savedCategory);
      } else {
        _expenseCategories.add(savedCategory);
      }
      
      _status = CategoryStatus.loaded;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = CategoryStatus.error;
      _errorMessage = 'Failed to create category: ${e.toString()}';
      notifyListeners();
      
      return false;
    }
  }
} 