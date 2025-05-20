import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import 'dashboard_tab.dart';
import 'savings_pots_tab.dart';
import 'transactions_tab.dart';
import 'profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
  
  // Static method to navigate to a specific tab
  static void navigateToTab(BuildContext context, int tabIndex) {
    final homeState = context.findRootAncestorStateOfType<_HomeScreenState>();
    if (homeState != null) {
      homeState.setTab(tabIndex);
    }
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // Public method to set tab
  void setTab(int index) {
    if (index != _currentIndex) {
      setState(() {
        // Restart animations when navigating to a tab
        switch (index) {
          case 0:
            _dashboardTabKey.currentState?.resetAnimation();
            break;
          case 1:
            _savingsPotTabKey.currentState?.resetAnimation();
            break;
          case 2:
            _transactionsTabKey.currentState?.resetAnimation();
            break;
          case 3:
            _profileTabKey.currentState?.resetAnimation();
            break;
        }
        _currentIndex = index;
      });
    }
  }
  
  // Reference to tab keys to call their methods
  final GlobalKey<SavingsPotTabState> _savingsPotTabKey = GlobalKey<SavingsPotTabState>();
  final GlobalKey<DashboardTabState> _dashboardTabKey = GlobalKey<DashboardTabState>();
  final GlobalKey<TransactionsTabState> _transactionsTabKey = GlobalKey<TransactionsTabState>();
  final GlobalKey<ProfileTabState> _profileTabKey = GlobalKey<ProfileTabState>();
  
  // List of tab screens
  late final List<Widget> _tabs;
  
  @override
  void initState() {
    super.initState();
    // Initialize tabs with the keys
    _tabs = [
      DashboardTab(key: _dashboardTabKey),
      SavingsPotTab(key: _savingsPotTabKey),
      TransactionsTab(key: _transactionsTabKey),
      ProfileTab(key: _profileTabKey),
    ];
  }
  
  // Handle sign out
  Future<void> _signOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final result = await authProvider.signOut();
    
    if (result && mounted) {
      // Navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else if (mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to sign out'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  // Toggle theme
  void _toggleTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Only process if we're actually changing tabs
          if (index != _currentIndex) {
          setState(() {
              // Restart animations when navigating to a tab
              switch (index) {
                case 0:
                  _dashboardTabKey.currentState?.resetAnimation();
                  break;
                case 1:
                  _savingsPotTabKey.currentState?.resetAnimation();
                  break;
                case 2:
                  _transactionsTabKey.currentState?.resetAnimation();
                  break;
                case 3:
                  _profileTabKey.currentState?.resetAnimation();
                  break;
              }
            _currentIndex = index;
          });
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings_outlined),
            label: 'Pots',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1 
          ? FloatingActionButton(
              onPressed: () {
                // Directly show the create pot dialog using the public method
                _savingsPotTabKey.currentState?.showCreatePotDialog();
              },
              heroTag: 'createPotFAB',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
} 