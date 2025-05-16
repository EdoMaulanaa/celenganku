import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Services
import 'services/supabase_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/savings_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';

// Themes
import 'themes/app_theme.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/auth_wrapper.dart';

// Utils
import 'utils/chart_utils.dart';
import 'utils/auth_route_observer.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Auth provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // Category provider
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        
        // Savings provider
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        
        // Transaction provider - depends on SavingsProvider and CategoryProvider
        ChangeNotifierProxyProvider2<SavingsProvider, CategoryProvider, TransactionProvider>(
          create: (context) => TransactionProvider(
            Provider.of<SavingsProvider>(context, listen: false),
            Provider.of<CategoryProvider>(context, listen: false),
          ),
          update: (context, savingsProvider, categoryProvider, previous) => 
            previous ?? TransactionProvider(savingsProvider, categoryProvider),
        ),
      ],
      child: const AppWithTheme(),
    );
  }
}

class AppWithTheme extends StatelessWidget {
  const AppWithTheme({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Celenganku',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: const SplashScreen(),
      navigatorObservers: [
        AuthRouteObserver(),
      ],
      onGenerateRoute: (RouteSettings settings) {
        // Named routes
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (_) => const SplashScreen(),
            settings: settings,
          );
        } else if (settings.name == '/login') {
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: settings,
          );
        } else if (settings.name == '/auth') {
          return MaterialPageRoute(
            builder: (_) => const AuthWrapper(),
            settings: settings,
          );
        }
        
        // Default route handling will use AuthRouteObserver
        return null;
      },
    );
  }
}
