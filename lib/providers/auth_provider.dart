import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  // Authentication status
  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;
  
  // User data
  User? _user;
  User? get user => _user;
  
  // User profile
  UserProfile? _profile;
  UserProfile? get profile => _profile;
  
  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // Constructor
  AuthProvider() {
    // Initialize with current session if exists
    _initializeAuth();
    
    // Listen for auth state changes
    _setupAuthListener();
  }

  // Initialize auth state
  Future<void> _initializeAuth() async {
    try {
      final currentUser = _supabaseService.currentUser;
      
      if (currentUser != null) {
        _user = currentUser;
        await _loadUserProfile(currentUser.id);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to initialize authentication: ${e.toString()}';
    }
    
    notifyListeners();
  }

  // Set up auth state change listener
  void _setupAuthListener() {
    _supabaseService.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session?.user != null) {
            _handleSignedIn(session!.user);
          }
          break;
        case AuthChangeEvent.signedOut:
          _handleSignedOut();
          break;
        case AuthChangeEvent.userUpdated:
          if (session?.user != null) {
            _handleUserUpdated(session!.user);
          }
          break;
        default:
          break;
      }
    });
  }
  
  // Handle signed in event
  Future<void> _handleSignedIn(User user) async {
    _user = user;
    await _loadUserProfile(user.id);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }
  
  // Handle signed out event
  void _handleSignedOut() {
    _user = null;
    _profile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
  
  // Handle user updated event
  Future<void> _handleUserUpdated(User user) async {
    _user = user;
    await _loadUserProfile(user.id);
    notifyListeners();
  }
  
  // Load user profile from database
  Future<void> _loadUserProfile(String userId) async {
    try {
      _profile = await _supabaseService.getUserProfile(userId);
      
      // If profile doesn't exist, create it
      if (_profile == null && _user != null) {
        final newProfile = UserProfile(
          id: _user!.id,
          email: _user!.email ?? '',
          createdAt: DateTime.now(),
        );
        
        await _supabaseService.upsertProfile(newProfile);
        _profile = newProfile;
      }
    } catch (e) {
      _errorMessage = 'Failed to load user profile: ${e.toString()}';
    }
  }
  
  // Sign up
  Future<bool> signUp(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      await _supabaseService.signUp(
        email: email,
        password: password,
      );
      
      // Note: At this point, user is not fully signed in until they confirm email
      // We'll keep status as loading until they sign in
      
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to sign up: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      await _supabaseService.signIn(
        email: email,
        password: password,
      );
      
      // Auth state listener will handle the state update
      
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to sign in: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Sign out
  Future<bool> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();
      
      await _supabaseService.signOut();
      
      // Auth state listener will handle the state update
      
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to sign out: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      await _supabaseService.resetPassword(email);
      
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to reset password: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Update user profile
  Future<bool> updateProfile({String? username}) async {
    try {
      if (_user == null || _profile == null) return false;
      
      _status = AuthStatus.loading;
      notifyListeners();
      
      // Update auth user metadata
      if (username != null) {
        await _supabaseService.updateUser(username: username);
      }
      
      // Update profile in database
      final updatedProfile = _profile!.copyWith(
        username: username ?? _profile!.username,
        updatedAt: DateTime.now(),
      );
      
      await _supabaseService.upsertProfile(updatedProfile);
      
      _profile = updatedProfile;
      _status = AuthStatus.authenticated;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Update user password
  Future<bool> updatePassword(String password) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();
      
      await _supabaseService.updatePassword(password);
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to update password: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Update user avatar
  Future<bool> updateAvatar(List<int> fileBytes, String fileName) async {
    try {
      if (_user == null || _profile == null) return false;
      
      _status = AuthStatus.loading;
      notifyListeners();
      
      print('Updating avatar for user: ${_user!.id}');
      print('File name: $fileName');
      print('File size: ${fileBytes.length} bytes');
      
      try {
        // Create file path in storage bucket - fix the path to match our policy
        final filePath = '${_user!.id}/$fileName';
        
        // Upload avatar
        final avatarUrl = await _supabaseService.uploadImage(
          'avatars',
          filePath,
          fileBytes,
        );
        
        // Update profile with new avatar URL
        final updatedProfile = _profile!.copyWith(
          avatarUrl: avatarUrl,
          updatedAt: DateTime.now(),
        );
        
        await _supabaseService.upsertProfile(updatedProfile);
        
        _profile = updatedProfile;
        _status = AuthStatus.authenticated;
        notifyListeners();
        
        print('Avatar updated successfully: $avatarUrl');
        return true;
      } catch (uploadError) {
        print('Error during avatar upload: $uploadError');
        
        // Even if upload fails, try to update username
        if (_profile != null) {
          final updatedProfile = _profile!.copyWith(
            updatedAt: DateTime.now(),
          );
          
          await _supabaseService.upsertProfile(updatedProfile);
          _profile = updatedProfile;
        }
        
        _status = AuthStatus.error;
        _errorMessage = 'Failed to update avatar: ${uploadError.toString()}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Critical error in updateAvatar: $e');
      _status = AuthStatus.error;
      _errorMessage = 'Failed to update avatar: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
} 