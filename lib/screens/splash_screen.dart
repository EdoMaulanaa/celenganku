import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Start auth check without delay
    _checkAuthAndNavigate();
  }
  
  // Check authentication status and navigate accordingly
  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Wait at least 2 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check auth status again after the delay
    if (authProvider.status == AuthStatus.authenticated) {
      // Navigate to home screen if authenticated
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: const RouteSettings(name: '/home'),
        ),
      );
    } else if (authProvider.status == AuthStatus.unauthenticated) {
      // Navigate to login screen if not authenticated
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: const RouteSettings(name: '/login'),
        ),
      );
    } else if (authProvider.status == AuthStatus.loading) {
      // Wait a bit longer if still loading
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) _checkAuthAndNavigate();
    } else {
      // Default to login on error
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: const RouteSettings(name: '/login'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.savings_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App name
            const Text(
              'Celenganku',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Tag line
            const Text(
              'Manage your savings wisely',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
} 