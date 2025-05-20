import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../models/savings_pot.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal() {
    // Setup logging
    _setupErrorLogging();
  }

  // Supabase client getter
  SupabaseClient get client => Supabase.instance.client;
  
  // Auth getter
  GoTrueClient get auth => client.auth;
  
  // Get current user
  User? get currentUser => auth.currentUser;
  
  // Check if user is logged in
  bool get isAuthenticated => auth.currentUser != null;

  // Initialize Supabase
  static Future<void> initialize() async {
    // Validate config
    SupabaseConfig.validateConfig();
    
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
  }

  // Setup error logging for Supabase
  void _setupErrorLogging() {
    // Print when there's an error with Supabase
    client.auth.onAuthStateChange.listen(
      (data) {
        print('Auth state changed: ${data.event}');
      },
      onError: (error) {
        print('Supabase auth error: $error');
      }
    );
  }

  // REALTIME SUBSCRIPTION METHODS
  
  // Subscribe to transactions table changes and return a StreamSubscription
  Stream<List<Transaction>> streamTransactions({String? potId}) {
    if (potId != null) {
      // Stream transactions for a specific pot
      return client
          .from('transactions')
          .stream(primaryKey: ['id'])
          .eq('savings_pot_id', potId)
          .order('date', ascending: false)
          .map((data) => data.map((item) => Transaction.fromJson(item)).toList());
    } else {
      // Stream all transactions for the current user
      return client
          .from('transactions')
          .stream(primaryKey: ['id'])
          .eq('user_id', currentUser!.id)
          .order('date', ascending: false)
          .map((data) => data.map((item) => Transaction.fromJson(item)).toList());
    }
  }
  
  // Stream savings pots changes
  Stream<List<SavingsPot>> streamSavingsPots() {
    return client
        .from('savings_pots')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser!.id)
        .order('created_at')
        .map((data) => data.map((item) => SavingsPot.fromJson(item)).toList());
  }

  // AUTHENTICATION METHODS
  
  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email, 
    required String password,
  }) async {
    return await auth.signUp(
      email: email,
      password: password,
    );
  }
  
  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email, 
    required String password,
  }) async {
    return await auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign out
  Future<void> signOut() async {
    await auth.signOut();
  }
  
  // Send password reset email
  Future<void> resetPassword(String email) async {
    await auth.resetPasswordForEmail(email);
  }
  
  // Update user email or other attributes
  Future<UserResponse> updateUser({String? email, String? username}) async {
    Map<String, dynamic> userMetadata = {};
    
    if (username != null) {
      userMetadata['username'] = username;
    }
    
    return await auth.updateUser(
      UserAttributes(
        email: email,
        data: userMetadata.isNotEmpty ? userMetadata : null,
      ),
    );
  }
  
  // Update user password
  Future<UserResponse> updatePassword(String password) async {
    return await auth.updateUser(
      UserAttributes(password: password),
    );
  }

  // USER PROFILE METHODS
  
  // Get user profile by id
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return UserProfile.fromJson(response);
    } catch (e) {
      // Return null if no profile found or other error
      return null;
    }
  }
  
  // Create or update user profile
  Future<void> upsertProfile(UserProfile profile) async {
    await client
        .from('profiles')
        .upsert(profile.toJson());
  }
  
  // SAVINGS POT METHODS
  
  // Get all savings pots for current user
  Future<List<SavingsPot>> getSavingsPots() async {
    if (currentUser == null) return [];
    
    final response = await client
        .from('savings_pots')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at');
    
    return (response as List)
        .map((pot) => SavingsPot.fromJson(pot))
        .toList();
  }
  
  // Get a specific savings pot by id
  Future<SavingsPot?> getSavingsPot(String id) async {
    try {
      final response = await client
          .from('savings_pots')
          .select()
          .eq('id', id)
          .single();
      
      return SavingsPot.fromJson(response);
    } catch (e) {
      // Return null if no record found or other error occurs
      return null;
    }
  }
  
  // Create a new savings pot
  Future<SavingsPot> createSavingsPot(SavingsPot pot) async {
    try {
      final response = await client
          .from('savings_pots')
          .insert(pot.toJson())
          .select()
          .single();
      
      return SavingsPot.fromJson(response);
    } catch (e) {
      print('Error creating savings pot: $e');
      throw e;
    }
  }
  
  // Update a savings pot
  Future<void> updateSavingsPot(SavingsPot pot) async {
    try {
      await client
          .from('savings_pots')
          .update(pot.toJson())
          .eq('id', pot.id);
    } catch (e) {
      print('Error updating savings pot: $e');
      throw e;
    }
  }
  
  // Delete a savings pot
  Future<void> deleteSavingsPot(String id) async {
    await client
        .from('savings_pots')
        .delete()
        .eq('id', id);
  }
  
  // TRANSACTION METHODS
  
  // Get all transactions for a specific savings pot
  Future<List<Transaction>> getTransactionsForPot(String potId) async {
    final response = await client
        .from('transactions')
        .select()
        .eq('savings_pot_id', potId)
        .order('date', ascending: false);
    
    return (response as List)
        .map((txn) => Transaction.fromJson(txn))
        .toList();
  }
  
  // Get all transactions for current user
  Future<List<Transaction>> getAllTransactions() async {
    if (currentUser == null) return [];
    
    final response = await client
        .from('transactions')
        .select()
        .eq('user_id', currentUser!.id)
        .order('date', ascending: false);
    
    return (response as List)
        .map((txn) => Transaction.fromJson(txn))
        .toList();
  }
  
  // Create a new transaction
  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      print('Creating transaction: ${transaction.toJson()}');
      final response = await client
          .from('transactions')
          .insert(transaction.toJson())
          .select()
          .single();
      
      print('Transaction created successfully: $response');
      return Transaction.fromJson(response);
    } catch (e) {
      print('Error creating transaction: $e');
      throw e;
    }
  }
  
  // Update a transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await client
        .from('transactions')
        .update(transaction.toJson())
        .eq('id', transaction.id);
  }
  
  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await client
        .from('transactions')
        .delete()
        .eq('id', id);
  }
  
  // TRANSACTION CATEGORY METHODS
  
  // Get all transaction categories
  Future<List<TransactionCategory>> getTransactionCategories() async {
    final response = await client
        .from('transaction_categories')
        .select()
        .order('name');
    
    return (response as List)
        .map((cat) => TransactionCategory.fromJson(cat))
        .toList();
  }
  
  // Get transaction categories by type
  Future<List<TransactionCategory>> getTransactionCategoriesByType(
    TransactionType type
  ) async {
    final typeStr = type == TransactionType.income ? 'income' : 'expense';
    
    final response = await client
        .from('transaction_categories')
        .select()
        .eq('type', typeStr)
        .order('name');
    
    return (response as List)
        .map((cat) => TransactionCategory.fromJson(cat))
        .toList();
  }
  
  // Get a specific transaction category by id
  Future<TransactionCategory?> getTransactionCategory(String id) async {
    try {
      final response = await client
          .from('transaction_categories')
          .select()
          .eq('id', id)
          .single();
      
      return TransactionCategory.fromJson(response);
    } catch (e) {
      // Return null if no category found or other error
      return null;
    }
  }
  
  // Create a custom transaction category
  Future<TransactionCategory> createTransactionCategory(
    TransactionCategory category
  ) async {
    final response = await client
        .from('transaction_categories')
        .insert(category.toJson())
        .select()
        .single();
    
    return TransactionCategory.fromJson(response);
  }
  
  // Calculate days remaining for a savings goal
  Future<int?> calculateDaysRemaining(String potId) async {
    try {
      final pot = await getSavingsPot(potId);
      if (pot == null || pot.targetDate == null) {
        return null;
      }
      
      final response = await client
          .rpc('calculate_days_remaining', params: {
            'target_date': pot.targetDate!.toIso8601String()
          });
      
      if (response == null) {
        return null;
      }
      
      return response as int;
    } catch (e) {
      // Return null on error
      return null;
    }
  }
  
  // Calculate daily savings needed to reach goal
  Future<double?> calculateDailySavingsNeeded(String potId) async {
    try {
      final pot = await getSavingsPot(potId);
      if (pot == null || pot.targetAmount == null || pot.targetDate == null) {
        return null;
      }
      
      final response = await client
          .rpc('calculate_daily_savings_needed', params: {
            'target_amount': pot.targetAmount,
            'current_balance': pot.currentBalance,
            'target_date': pot.targetDate!.toIso8601String()
          });
      
      if (response == null) {
        return null;
      }
      
      return (response as num).toDouble();
    } catch (e) {
      // Return null on error
      return null;
    }
  }
  
  // STORAGE METHODS
  
  // Upload an image (for user avatar or pot thumbnail)
  Future<String> uploadImage(String bucket, String path, List<int> fileBytes) async {
    try {
      print('Uploading image to bucket: $bucket, path: $path');
      
      try {
        // Try to create the bucket if it doesn't exist (might fail due to permissions)
        await client.storage.createBucket(bucket, const BucketOptions(
          public: true,
        ));
        print('Bucket $bucket created or already exists');
      } catch (e) {
        print('Note: Could not create bucket: $e');
        // Continue anyway as bucket might already exist
      }
      
      try {
        // Try to list buckets
        final buckets = await client.storage.listBuckets();
        print('Available buckets: ${buckets.map((b) => b.name).join(', ')}');
      } catch (e) {
        print('Could not list buckets: $e');
      }
      
      // Upload the file
      try {
        await client
            .storage
            .from(bucket)
            .uploadBinary(path, Uint8List.fromList(fileBytes));
        print('File uploaded successfully');
      } catch (e) {
        print('Error in uploadBinary: $e');
        throw e;
      }
      
      // Get public URL
      try {
        final url = client
            .storage
            .from(bucket)
            .getPublicUrl(path);
        
        print('Image uploaded successfully. Public URL: $url');
        return url;
      } catch (e) {
        print('Error getting public URL: $e');
        throw e;
      }
    } catch (e) {
      print('Error uploading image: $e');
      throw e;
    }
  }
  
  // Delete an image
  Future<void> deleteImage(String bucket, String path) async {
    await client
        .storage
        .from(bucket)
        .remove([path]);
  }

  // Check for existing session and restore if possible
  Future<bool> checkAndRestoreSession() async {
    try {
      final AuthResponse response = await auth.refreshSession();
      return response.session != null;
    } catch (e) {
      print('Error refreshing session: $e');
      return false;
    }
  }

  // Verify password by attempting to sign in
  Future<bool> verifyPassword(String email, String password) async {
    try {
      // We'll attempt to sign in with the provided credentials
      // If it works, the password is correct
      final response = await auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // If we get here, the password was correct
      return response.session != null;
    } catch (e) {
      // If we get an exception, the password was likely incorrect
      print('Error verifying password: $e');
      return false;
    }
  }
}