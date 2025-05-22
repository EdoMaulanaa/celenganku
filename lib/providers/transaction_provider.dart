import 'dart:async';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../services/supabase_service.dart';
import 'savings_provider.dart';
import 'category_provider.dart';

enum TransactionStatus {
  initial,
  loading,
  loaded,
  error,
}

class TransactionProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final SavingsProvider _savingsProvider;
  final CategoryProvider _categoryProvider;
  
  // Status
  TransactionStatus _status = TransactionStatus.initial;
  TransactionStatus get status => _status;
  
  // Current pot ID (if viewing a specific pot)
  String? _currentPotId;
  String? get currentPotId => _currentPotId;
  
  // Flag to toggle between grouping expenses by category or savings pot
  bool _groupExpensesBySavingsPot = true;
  bool get groupExpensesBySavingsPot => _groupExpensesBySavingsPot;
  
  // List of transactions
  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;
  
  // Stream subscription
  StreamSubscription<List<Transaction>>? _transactionSubscription;
  
  // Filtered transactions for current pot
  List<Transaction> get currentPotTransactions {
    if (_currentPotId == null) return [];
    return _transactions.where((txn) => txn.savingsPotId == _currentPotId).toList();
  }
  
  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // Constructor
  TransactionProvider(this._savingsProvider, this._categoryProvider) {
    // Delay initial loading to avoid calling during build phase
    Future.microtask(() => loadTransactions());
  }
  
  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }
  
  // Set grouping method for expense breakdown
  void setGroupExpensesBySavingsPot(bool value) {
    if (_groupExpensesBySavingsPot != value) {
      _groupExpensesBySavingsPot = value;
      notifyListeners();
    }
  }
  
  // Cancel existing subscription
  void _cancelSubscription() {
    _transactionSubscription?.cancel();
    _transactionSubscription = null;
  }
  
  // Get category for a transaction
  TransactionCategory? getCategoryForTransaction(Transaction transaction) {
    if (transaction.categoryId != null) {
      return _categoryProvider.getCategoryById(transaction.categoryId);
    }
    return null;
  }
  
  // Set current pot ID
  void setCurrentPotId(String? potId, {bool notify = true}) {
    if (_currentPotId != potId) {
      _currentPotId = potId;
      
      // Reload transactions with new potId filter
      loadTransactions();
      
      if (notify) {
        notifyListeners();
      }
    }
  }
  
  // Load all transactions for current user
  Future<void> loadTransactions() async {
    if (!_supabaseService.isAuthenticated) return;
    
    try {
      _status = TransactionStatus.loading;
      notifyListeners();
      
      // Cancel any existing subscription
      _cancelSubscription();
      
      // Create a new subscription based on current context
      _transactionSubscription = _supabaseService
          .streamTransactions(potId: _currentPotId) // When null, it will stream ALL user transactions
          .listen(
            (updatedTransactions) {
              _transactions = updatedTransactions;
              _status = TransactionStatus.loaded;
              notifyListeners();
              print('Transactions updated: ${_transactions.length} transactions loaded.');
            },
            onError: (error) {
              print('Error in transaction stream: $error');
              _status = TransactionStatus.error;
              _errorMessage = 'Error streaming transactions: $error';
              notifyListeners();
            },
          );
      
    } catch (e) {
      print('Error loading transactions: $e');
      _status = TransactionStatus.error;
      _errorMessage = 'Failed to load transactions: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Create a new transaction
  Future<bool> createTransaction({
    required String savingsPotId,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String? notes,
    String? category, // For backward compatibility
    String? categoryId,
  }) async {
    if (!_supabaseService.isAuthenticated) {
      _errorMessage = 'Not authenticated';
      return false;
    }
    
    if (savingsPotId.isEmpty) {
      _errorMessage = 'Invalid savings pot ID';
      return false;
    }
    
    if (amount <= 0) {
      _errorMessage = 'Amount must be greater than zero';
      return false;
    }
    
    try {
      _status = TransactionStatus.loading;
      notifyListeners();
      
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        _status = TransactionStatus.error;
        _errorMessage = 'User ID is null';
        notifyListeners();
        return false;
      }
      
      final now = DateTime.now();
      
      // Validate savings pot exists
      final pot = _savingsProvider.getSavingsPotById(savingsPotId);
      if (pot == null) {
        _status = TransactionStatus.error;
        _errorMessage = 'Savings pot not found';
        notifyListeners();
        return false;
      }
      
      // Check if balance is enough for expense
      if (type == TransactionType.expense && amount > pot.currentBalance) {
        _status = TransactionStatus.error;
        _errorMessage = 'Insufficient balance for withdrawal';
        notifyListeners();
        return false;
      }
      
      print('Creating transaction: Amount=$amount, Type=${type.toString()}, PotID=$savingsPotId');
      
      // Create the new transaction
      final newTransaction = Transaction(
        id: '', // Let Supabase generate the UUID
        userId: userId,
        savingsPotId: savingsPotId,
        amount: amount,
        type: type,
        date: date,
        notes: notes,
        category: category,
        categoryId: categoryId,
        createdAt: now,
      );
      
      // Save to database - the UI will update automatically via the stream
      try {
        await _supabaseService.createTransaction(newTransaction);
        
        // Refresh savings pots to see updated balance
        await _savingsProvider.loadSavingsPots();
        
        _status = TransactionStatus.loaded;
        notifyListeners();
        
        return true;
      } catch (e) {
        _status = TransactionStatus.error;
        _errorMessage = 'Database error: ${e.toString()}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = TransactionStatus.error;
      _errorMessage = 'Failed to create transaction: ${e.toString()}';
      notifyListeners();
      
      return false;
    }
  }
  
  // Update a transaction
  Future<bool> updateTransaction({
    required String id,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? notes,
    String? category,
    String? categoryId,
  }) async {
    try {
      _status = TransactionStatus.loading;
      notifyListeners();
      
      // Find the transaction to update
      final index = _transactions.indexWhere((txn) => txn.id == id);
      
      if (index == -1) {
        _status = TransactionStatus.error;
        _errorMessage = 'Transaction not found';
        notifyListeners();
        return false;
      }
      
      final currentTransaction = _transactions[index];
      
      // Create updated transaction
      final updatedTransaction = currentTransaction.copyWith(
        amount: amount,
        type: type,
        date: date,
        notes: notes,
        category: category,
        categoryId: categoryId,
      );
      
      // Update in database
      await _supabaseService.updateTransaction(updatedTransaction);
      
      // Update local list
      _transactions[index] = updatedTransaction;
      
      // Balance is now updated by database trigger
      
      _status = TransactionStatus.loaded;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = TransactionStatus.error;
      _errorMessage = 'Failed to update transaction: ${e.toString()}';
      notifyListeners();
      
      return false;
    }
  }
  
  // Delete a transaction
  Future<bool> deleteTransaction(String id) async {
    try {
      _status = TransactionStatus.loading;
      notifyListeners();
      
      // Delete from database
      await _supabaseService.deleteTransaction(id);
      
      // Remove from local list
      _transactions.removeWhere((txn) => txn.id == id);
      
      // Balance is now updated by database trigger
      
      _status = TransactionStatus.loaded;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = TransactionStatus.error;
      _errorMessage = 'Failed to delete transaction: ${e.toString()}';
      notifyListeners();
      
      return false;
    }
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_status == TransactionStatus.error) {
      _status = _transactions.isNotEmpty 
        ? TransactionStatus.loaded 
        : TransactionStatus.initial;
    }
    notifyListeners();
  }
  
  // Manual refresh function to reload transactions
  Future<void> refresh() async {
    // Ensure we're loading ALL transactions
    if (_currentPotId != null) {
      _currentPotId = null;
    }
    
    await loadTransactions();
  }
} 