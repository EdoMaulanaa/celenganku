import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validator.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Handle reset password
  Future<void> _resetPassword() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final result = await authProvider.resetPassword(
      _emailController.text.trim(),
    );
    
    setState(() {
      _isLoading = false;
      if (result) {
        _resetSent = true;
      }
    });
    
    if (!result && mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Gagal mengirim email reset'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Navigate back to login
  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Password'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _resetSent ? _buildSuccessContent() : _buildResetForm(),
          ),
        ),
      ),
    );
  }
  
  // Form for requesting password reset
  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reset password icon
          Icon(
            Icons.lock_reset,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Lupa Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Instructions
          const Text(
            'Masukkan alamat email Anda dan kami akan mengirimkan instruksi untuk mengatur ulang password Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 32),
          
          // Email field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Masukkan email anda',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: Validator.validateEmail,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
          ),
          
          const SizedBox(height: 32),
          
          // Reset password button
          ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Reset Password'),
          ),
          
          const SizedBox(height: 24),
          
          // Back to login link
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali ke Login'),
          ),
        ],
      ),
    );
  }
  
  // Success message after reset email sent
  Widget _buildSuccessContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),
        
        const SizedBox(height: 24),
        
        // Success title
        const Text(
          'Email Terkirim',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Success message
        Text(
          'Kami telah mengirimkan instruksi reset password ke ${_emailController.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        
        const SizedBox(height: 32),
        
        // Return to login button
        ElevatedButton(
          onPressed: _navigateToLogin,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Kembali ke Login'),
        ),
      ],
    );
  }
}
