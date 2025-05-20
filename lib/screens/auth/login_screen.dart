import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validator.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle login
  Future<void> _login() async {
    // Reset previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final result = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (result && mounted) {
      // Navigate to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted) {
      // Analisis pesan error untuk menentukan field yang bermasalah
      final errorMessage = authProvider.errorMessage?.toLowerCase() ?? 'failed to sign in';
      
      setState(() {
        // Periksa apakah ada kata kunci yang menunjukkan masalah email
        final isEmailError = errorMessage.contains('email') || 
                             errorMessage.contains('not found') || 
                             errorMessage.contains('tidak terdaftar');
        
        // Periksa apakah ada kata kunci yang menunjukkan masalah password
        final isPasswordError = errorMessage.contains('password') || 
                                errorMessage.contains('credentials') || 
                                errorMessage.contains('invalid login') ||
                                errorMessage.contains('invalid_credentials');
        
        // Tentukan field yang akan menampilkan error
        if (isEmailError && isPasswordError) {
          // Jika error menunjukkan kedua field bermasalah, tampilkan di keduanya
          _emailError = 'Email atau password salah';
          _passwordError = 'Email atau password salah';
        } else if (isEmailError) {
          // Jika hanya email yang bermasalah
          _emailError = 'Email tidak ditemukan';
        } else if (isPasswordError) {
          // Jika hanya password yang bermasalah
          _passwordError = 'Password salah';
        } else {
          // Default fallback jika tidak bisa menentukan field spesifik
          _passwordError = 'Login gagal, silakan coba lagi';
        }
      });
    }
  }

  // Navigate to register screen
  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  // Navigate to forgot password screen
  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo
                  Icon(
                    Icons.savings_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // App name
                  Text(
                    'Celenganku',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Welcome text
                  const Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      errorText: _emailError,
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorStyle: const TextStyle(color: Colors.red),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validator.validateEmail,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) {
                      if (_emailError != null) {
                        setState(() {
                          _emailError = null;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      errorText: _passwordError,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      errorStyle: const TextStyle(color: Colors.red),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: Validator.validatePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    onChanged: (value) {
                      if (_passwordError != null) {
                        setState(() {
                          _passwordError = null;
                        });
                      }
                    },
                  ),
                  
                  // Forgot password button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _navigateToForgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
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
                        : const Text('Sign In'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: _navigateToRegister,
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 