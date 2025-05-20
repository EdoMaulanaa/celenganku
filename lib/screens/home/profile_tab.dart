import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/change_password_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => ProfileTabState();
}

class ProfileTabState extends State<ProfileTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<GlobalKey> _sectionKeys = List.generate(5, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void resetAnimation() {
    _animationController.reset();
    _animationController.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Get username or email
    final username = authProvider.profile?.username 
      ?? authProvider.user?.email?.split('@').first
      ?? 'User';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // User avatar and info section with fade + slide animation
            _buildAnimatedSection(
              index: 0,
              child: Column(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    backgroundImage: authProvider.profile?.avatarUrl != null
                      ? NetworkImage(authProvider.profile!.avatarUrl!)
                      : null,
                    child: authProvider.profile?.avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // User name
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  // User email
                  Text(
                    authProvider.user?.email ?? 'No email',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Profile options card with animation
            _buildAnimatedSection(
              index: 1,
              child: Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Edit profile option
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Edit Profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    // Change password option
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    // Theme toggle option
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark Mode'),
                      value: themeProvider.isDarkMode,
                      onChanged: (_) {
                        themeProvider.toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App info card with animation
            _buildAnimatedSection(
              index: 2,
              child: Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    // About option
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Show about dialog
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    // Help option
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to help screen
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Sign out button with animation
            _buildAnimatedSection(
              index: 3,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Show confirmation dialog
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  
                  if (result == true) {
                    // Sign out
                    final signedOut = await authProvider.signOut();
                    
                    if (signedOut && context.mounted) {
                      // Navigate to login screen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App version with animation
            _buildAnimatedSection(
              index: 4,
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to create animated sections
  Widget _buildAnimatedSection({required int index, required Widget child}) {
    // Create staggered animation for each section
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1, // Staggered start times
          0.5 + (index * 0.1), // Overlap end times slightly
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          0.5 + (index * 0.1),
          curve: Curves.easeOut,
        ),
      ),
    );
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        key: _sectionKeys[index],
        child: child,
      ),
    );
  }
}