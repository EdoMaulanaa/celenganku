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
  final GlobalKey<SavingsPotTabState> _savingsPotTabKey = GlobalKey<SavingsPotTabState>(debugLabel: 'savingsPotTabKey');
  final GlobalKey<DashboardTabState> _dashboardTabKey = GlobalKey<DashboardTabState>(debugLabel: 'dashboardTabKey');
  final GlobalKey<TransactionsTabState> _transactionsTabKey = GlobalKey<TransactionsTabState>(debugLabel: 'transactionsTabKey');
  final GlobalKey<ProfileTabState> _profileTabKey = GlobalKey<ProfileTabState>(debugLabel: 'profileTabKey');
  
  // Create tab widgets directly as fields
  Widget? _dashboardTab;
  Widget? _savingsPotTab;
  Widget? _transactionsTab;
  Widget? _profileTab;
  
  // Ensure each tab is created only once
  Widget _getDashboardTab() {
    _dashboardTab ??= DashboardTab(key: _dashboardTabKey);
    return _dashboardTab!;
  }
  
  Widget _getSavingsPotTab() {
    _savingsPotTab ??= SavingsPotTab(key: _savingsPotTabKey);
    return _savingsPotTab!;
  }
  
  Widget _getTransactionsTab() {
    _transactionsTab ??= TransactionsTab(key: _transactionsTabKey);
    return _transactionsTab!;
  }
  
  Widget _getProfileTab() {
    _profileTab ??= ProfileTab(key: _profileTabKey);
    return _profileTab!;
  }
  
  @override
  void initState() {
    super.initState();
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
    // Get the current tab based on index
    Widget currentTab;
    switch (_currentIndex) {
      case 0:
        currentTab = _getDashboardTab();
        break;
      case 1:
        currentTab = _getSavingsPotTab();
        break;
      case 2:
        currentTab = _getTransactionsTab();
        break;
      case 3:
        currentTab = _getProfileTab();
        break;
      default:
        currentTab = _getDashboardTab();
    }
    
    return Scaffold(
      body: currentTab,
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
                // Safely access the SavingsPotTabState
                final state = _savingsPotTabKey.currentState;
                if (state != null && state.mounted) {
                  state.showCreatePotDialog();
                }
              },
              heroTag: 'createPotFAB',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
} 