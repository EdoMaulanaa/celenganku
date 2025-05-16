import 'package:flutter/foundation.dart';

// Supabase URL and anon key
class SupabaseConfig {
  static const String supabaseUrl = "https://xmumcfhffvrqketlhdqp.supabase.co";
  static const String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhtdW1jZmhmZnZycWtldGxoZHFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDczODgyNjAsImV4cCI6MjA2Mjk2NDI2MH0.w1bEi5CJtyEcxfhsZiMxWDpuXQuakG7RTKOo-Oi5BtY";

  // For development purposes, print a warning if credentials are not set
  static void validateConfig() {
    assert(
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
      'Please update the Supabase credentials in lib/config/supabase_config.dart',
    );

    if (kDebugMode && (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty)) {
      print('WARNING: Supabase credentials are not set in lib/config/supabase_config.dart');
    }
  }
} 