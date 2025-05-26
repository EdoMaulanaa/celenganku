class Validator {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email harus diisi';
    }
    
    // Regular expression for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (!emailRegex.hasMatch(value)) {
      return 'Masukkan alamat email yang valid';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password harus diisi';
    }
    
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    
    return null;
  }
  
  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName harus diisi';
    }
    
    return null;
  }
  
  // Minimum length validation
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    
    if (value.length < minLength) {
      return '$fieldName minimal $minLength karakter';
    }
    
    return null;
  }
  
  // Number validation
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName harus berupa angka';
    }
    
    return null;
  }
  
  // Positive number validation
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    
    final number = double.tryParse(value);
    
    if (number == null) {
      return '$fieldName harus berupa angka';
    }
    
    if (number <= 0) {
      return '$fieldName harus lebih besar dari nol';
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
      return 'Tanggal target harus di masa depan';
    }
    
    return null;
  }
  
  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username harus diisi';
    }
    
    if (value.length < 3) {
      return 'Username minimal 3 karakter';
    }
    
    // Only allow alphanumeric and underscore
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    
    if (!usernameRegex.hasMatch(value)) {
      return 'Username hanya boleh berisi huruf, angka, dan garis bawah';
    }
    
    return null;
  }
}