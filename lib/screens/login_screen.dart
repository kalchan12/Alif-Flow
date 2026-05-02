import 'package:flutter/material.dart';
import 'package:alif_flow/theme/app_theme.dart';
import 'package:alif_flow/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Determine role from metadata
      final role = _authService.currentUserRole;
      
      if (!mounted) return;

      if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/seller_dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging in: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo placeholder
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.insights, // Placeholder for Alif-Flow logo
                      color: AppTheme.primaryCyan,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Alif-Flow',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue to your dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'name@company.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: Icon(Icons.visibility_off_outlined),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Forgot password logic
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Sign In'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text('Create Account'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/admin_dashboard');
                  },
                  child: const Text('Login as Admin (Demo)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
