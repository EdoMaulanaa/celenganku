class Validator {
  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    
    // Basic email validation regex
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  // Validate username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    return null;
  }
} 