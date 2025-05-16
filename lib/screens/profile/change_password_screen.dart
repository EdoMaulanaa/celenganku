import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/loading_overlay.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // First verify the current password by attempting to sign in
      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;
      final email = authProvider.user?.email;
      
      if (email == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Could not determine current user email";
        });
        return;
      }
      
      // Verify the current password
      final isCurrentPasswordValid = await authProvider.verifyPassword(email, currentPassword);
      
      if (!isCurrentPasswordValid) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Current password is incorrect";
        });
        return;
      }
      
      // Update to the new password
      final success = await authProvider.updatePassword(newPassword);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (authProvider.errorMessage != null) {
        setState(() {
          _errorMessage = authProvider.errorMessage;
        });
        authProvider.clearError();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An error occurred: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Password'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                
                // Current password field
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isCurrentPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isCurrentPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // New password field
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isNewPasswordVisible,
                  validator: Validator.validatePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                
                const SizedBox(height: 24),
                
                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isConfirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                
                const SizedBox(height: 32),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    child: const Text('Update Password'),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Security note
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'For security, please use a strong password that you don\'t use elsewhere.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 