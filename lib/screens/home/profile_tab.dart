import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

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
            
            const SizedBox(height: 32),
            
            // Profile options
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // Edit profile option
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to edit profile screen
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  // Change password option
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to change password screen
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
            
            const SizedBox(height: 24),
            
            // App info
            Card(
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
            
            const SizedBox(height: 32),
            
            // Sign out button
            ElevatedButton.icon(
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
            
            const SizedBox(height: 24),
            
            // App version
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}