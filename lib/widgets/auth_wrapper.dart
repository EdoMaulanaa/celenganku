import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Show loading indicator while checking auth status
    if (authProvider.status == AuthStatus.initial || 
        authProvider.status == AuthStatus.loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }
    
    // Check if authenticated and redirect accordingly
    if (authProvider.status == AuthStatus.authenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
} 