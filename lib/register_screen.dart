import 'package:flutter/material.dart';

import 'db/database_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. التحقق من التعبئة العامة
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    // 2. التحقق من صيغة البريد الإلكتروني ينتهي بـ @gmail.com
    if (!email.toLowerCase().endsWith('@gmail.com') || email.length <= 10) {
      _showMessage('Email must be a valid @gmail.com address');
      return;
    }

    // 3. التحقق من أن كلمة المرور أرقام فقط
    final isDigitsOnly = RegExp(r'^[0-9]+$').hasMatch(password);
    if (!isDigitsOnly) {
      _showMessage('Password must contain digits only');
      return;
    }

    // 4. التحقق من تطابق كلمتي المرور
    if (password != confirmPassword) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 5. إرسال البيانات لدالة MySQL
    bool success = await DatabaseService.registerUser(
      name: name,
      email: email,
      password: password,
    );

    setState(() {
      _isLoading = false;
    });

    // 6. معالجة النتيجة
    if (success) {
      _showMessage('Account created successfully!');
      if (mounted) Navigator.pop(context);
    } else {
      _showMessage('Failed to create account. Email might be already in use.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 72,
                  color: colors.primary,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  'Sign up to start tracking your budget',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                // حقل الاسم الكامل
                TextField(
                  controller: _nameController,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your name',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // حقل البريد الإلكتروني
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'user@gmail.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // حقل كلمة المرور (أرقام فقط)
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Digits only (e.g. 123456)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // حقل تأكيد كلمة المرور
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // زر إنشاء الحساب
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
