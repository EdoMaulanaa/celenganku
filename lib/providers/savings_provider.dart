import 'package:flutter/material.dart';
import '../models/savings_pot.dart';
import '../services/supabase_service.dart';

enum SavingsStatus {
  initial,
  loading,
  loaded,
  error,
}

class SavingsProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  // Status
  SavingsStatus _status = SavingsStatus.initial;
  SavingsStatus get status => _status;
  
  // List of savings pots
  List<SavingsPot> _savingsPots = [];
  List<SavingsPot> get savingsPots => _savingsPots;
  
  // Total balance across all savings pots
  double get totalBalance => _savingsPots.fold(
    0, (sum, pot) => sum + pot.currentBalance
  );
  
  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // Constructor
  SavingsProvider() {
    // Delay initial loading to avoid calling during build phase
    Future.microtask(() => loadSavingsPots());
  }
  
  // Load all savings pots for current user
  Future<void> loadSavingsPots() async {
    if (!_supabaseService.isAuthenticated) return;
    
    try {
      _status = SavingsStatus.loading;
      notifyListeners();
      
      _savingsPots = await _supabaseService.getSavingsPots();
      
      _status = SavingsStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = SavingsStatus.error;
      _errorMessage = 'Failed to load savings pots: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Get a specific savings pot by ID
  SavingsPot? getSavingsPotById(String id) {
    try {
      return _savingsPots.firstWhere((pot) => pot.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Create a new savings pot
  Future<bool> createSavingsPot({
    required String name,
    required String description,
    String? iconName,
    String? thumbnailUrl,
    double? targetAmount,
    DateTime? targetDate,
  }) async {
    if (!_supabaseService.isAuthenticated) {
      _errorMessage = 'Not authenticated';
      return false;
    }
    
    if (name.trim().isEmpty) {
      _errorMessage = 'Name is required';
      return false;
    }
    
    if (targetAmount != null && targetAmount <= 0) {
      _errorMessage = 'Target amount must be greater than zero';
      return false;
    }
    
    try {
      _status = SavingsStatus.loading;
      notifyListeners();
      
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        _status = SavingsStatus.error;
        _errorMessage = 'User ID is null';
        notifyListeners();
        return false;
      }
      
      final now = DateTime.now();
      
      // Create the new pot
      final newPot = SavingsPot(
        id: '', // Let Supabase generate the UUID
        userId: userId,
        name: name.trim(),
        description: description.trim(),
        thumbnailUrl: thumbnailUrl,
        currentBalance: 0, // Start with zero balance
        targetAmount: targetAmount,
        targetDate: targetDate,
        createdAt: now,
        updatedAt: now,
      );
      
      try {
        // Save to database
        final savedPot = await _supabaseService.createSavingsPot(newPot);
        
        // Add to local list
        _savingsPots.add(savedPot);
        
        _status = SavingsStatus.loaded;
        notifyListeners();
        
        return true;
      } catch (e) {
        _status = SavingsStatus.error;
        _errorMessage = 'Database error: ${e.toString()}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = SavingsStatus.error;
      _errorMessage = 'Failed to create savings pot: ${e.toString()}';
      notifyListeners();
      
      return false;
    }
  }
  
  // Update a savings pot
  Future<bool> updateSavingsPot({
    required String id,
    String? name,
    String? description,
    String? iconName,
    String? thumbnailUrl,
    double? targetAmount,
    DateTime? targetDate,
  }) async {
    try {
      _status = SavingsStatus.loading;
      notifyListeners();
      
      // Find the pot to update
      final index = _savingsPots.indexWhere((pot) => pot.id == id);
      
      if (index == -1) {
        _status = SavingsStatus.error;
        _errorMessage = 'Savings pot not found';
        notifyListeners();
        return false;
      }
      
      // Create updated pot
      final currentPot = _savingsPots[index];
      final updatedPot = currentPot.copyWith(
        name: name,
        description: description,
        thumbnailUrl: thumbnailUrl,
        targetAmount: targetAmount,
        targetDate: targetDate,
        updatedAt: DateTime.now(),
      );
      
      // Update in database
      await _supabaseService.updateSavingsPot(updatedPot);
      
      // Update local list
      _savingsPots[index] = updatedPot;
      
      _status = SavingsStatus.loaded;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = SavingsStatus.error;
      _errorMessage = 'Failed to update savings pot: ${e.toString()}';
      notifyListeners();
      
      return false;
    }
  }
  
  // Delete a savings pot
  Future<bool> deleteSavingsPot(String id) async {
    try {
      _status = SavingsStatus.loading;
      notifyListeners();
      
      // Delete from database
      await _supabaseService.deleteSavingsPot(id);
      
      // Remove from local list
      _savingsPots.removeWhere((pot) => pot.id == id);
      
      _status = SavingsStatus.loaded;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = SavingsStatus.error;
      _errorMessage = 'Failed to delete savings pot: ${e.toString()}';
      notifyListeners();
      
      return false;
    }
  }
  
  // Upload a thumbnail image for a savings pot
  Future<bool> uploadThumbnail(
    String potId, 
    List<int> fileBytes, 
    String fileName
  ) async {
    try {
      _status = SavingsStatus.loading;
      notifyListeners();
      
      // Find the pot to update
      final index = _savingsPots.indexWhere((pot) => pot.id == potId);
      
      if (index == -1) {
        _status = SavingsStatus.error;
        _errorMessage = 'Savings pot not found';
        notifyListeners();
        return false;
      }
      
      // Upload image - fix the path structure
      final filePath = '$potId/$fileName';
      final thumbnailUrl = await _supabaseService.uploadImage(
        'thumbnails',
        filePath,
        fileBytes,
      );
      
      // Update pot
      final currentPot = _savingsPots[index];
      final updatedPot = currentPot.copyWith(
        thumbnailUrl: thumbnailUrl,
        updatedAt: DateTime.now(),
      );
      
      // Update in database
      await _supabaseService.updateSavingsPot(updatedPot);
      
      // Update local list
      _savingsPots[index] = updatedPot;
      
      _status = SavingsStatus.loaded;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = SavingsStatus.error;
      _errorMessage = 'Failed to upload thumbnail: ${e.toString()}';
      notifyListeners();
      
      return false;
    }
  }
  
  // Update pot balance after transaction
  Future<bool> updatePotBalance(String potId, double newBalance) async {
    try {
      // Find the pot to update
      final index = _savingsPots.indexWhere((pot) => pot.id == potId);
      
      if (index == -1) {
        return false;
      }
      
      // Create updated pot
      final currentPot = _savingsPots[index];
      final updatedPot = currentPot.copyWith(
        currentBalance: newBalance,
        updatedAt: DateTime.now(),
      );
      
      // Update in database
      await _supabaseService.updateSavingsPot(updatedPot);
      
      // Update local list
      _savingsPots[index] = updatedPot;
      
      notifyListeners();
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update pot balance: ${e.toString()}';
      return false;
    }
  }
  
  // Calculate days remaining until target date
  Future<int?> calculateDaysRemaining(String potId) async {
    try {
      return await _supabaseService.calculateDaysRemaining(potId);
    } catch (e) {
      _errorMessage = 'Failed to calculate days remaining: ${e.toString()}';
      return null;
    }
  }
  
  // Calculate daily savings needed to reach target
  Future<double?> calculateDailySavingsNeeded(String potId) async {
    try {
      return await _supabaseService.calculateDailySavingsNeeded(potId);
    } catch (e) {
      _errorMessage = 'Failed to calculate daily savings needed: ${e.toString()}';
      return null;
    }
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_status == SavingsStatus.error) {
      _status = _savingsPots.isNotEmpty 
        ? SavingsStatus.loaded 
        : SavingsStatus.initial;
    }
    notifyListeners();
  }
  
  // Refresh data
  Future<void> refresh() async {
    await loadSavingsPots();
  }
} 