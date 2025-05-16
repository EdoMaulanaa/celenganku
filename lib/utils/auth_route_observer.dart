import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

class AuthRouteObserver extends NavigatorObserver {
  // Track if we're currently handling a navigation event
  bool _isHandlingNavigation = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // Only check routes after initial splash screen and auth wrapper
    if (!_isHandlingNavigation && 
        route.settings.name != null && 
        route.settings.name != '/' &&
        route.settings.name != '/auth' &&
        route.settings.name != '/login' &&
        route.settings.name != '/splash') {
      _checkAuthStatus(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    // Check auth on replace as well - this can happen on refresh
    if (newRoute != null) {
      _checkAuthStatus(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // No need to check auth on pop
  }

  Future<void> _checkAuthStatus(Route<dynamic> route) async {
    // Avoid concurrent navigation operations
    if (_isHandlingNavigation) return;
    _isHandlingNavigation = true;

    try {
      // Skip checking for certain routes
      if (route.settings.name == '/login' || 
          route.settings.name == '/' || 
          route.settings.name == '/auth' ||
          route.settings.name == '/splash') {
        _isHandlingNavigation = false;
        return;
      }

      // Get the BuildContext from the route
      final BuildContext? context = route.navigator?.context;
      if (context == null) {
        _isHandlingNavigation = false;
        return;
      }

      // Check authentication status
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // If we're in loading state, wait a bit
      if (authProvider.status == AuthStatus.loading) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Try to restore session if needed
      if (authProvider.status == AuthStatus.unauthenticated ||
          authProvider.status == AuthStatus.error) {
        
        // Don't redirect if we're already going to login
        if (route.settings.name == '/login') {
          _isHandlingNavigation = false;
          return;
        }
        
        // If not authenticated, redirect to login screen
        route.navigator?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: const RouteSettings(name: '/login'),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    } finally {
      // Reset flag when done
      _isHandlingNavigation = false;
    }
  }
} 