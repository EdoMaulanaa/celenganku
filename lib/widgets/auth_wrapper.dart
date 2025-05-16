import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Try to restore session if needed
    _checkSession();
  }
  
  Future<void> _checkSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.status == AuthStatus.unauthenticated) {
      await authProvider.checkAndRestoreSession();
    }
  }

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