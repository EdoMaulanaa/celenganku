class Validator {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Regular expression for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }
  
  // Minimum length validation
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }
  
  // Number validation
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a number';
    }
    
    return null;
  }
  
  // Positive number validation
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    
    if (number == null) {
      return '$fieldName must be a number';
    }
    
    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }
    
    return null;
  }
  
  // Target date validation (must be in the future)
  static String? validateTargetDate(DateTime? value) {
    if (value == null) {
      return null; // Optional field
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final valueDate = DateTime(value.year, value.month, value.day);
    
    if (valueDate.isBefore(today)) {
      return 'Target date must be in the future';
    }
    
    return null;
  }
  
  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    // Only allow alphanumeric and underscore
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscore';
    }
    
    return null;
  }
}