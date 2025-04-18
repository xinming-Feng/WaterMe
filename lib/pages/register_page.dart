import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'login_page.dart';
import '../main_navigation.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await FirebaseService.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
        );

        if (mounted) {
          // 注册成功，导航到主页
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainNavigation(initialIndex: 0),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = _getFirebaseErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  String _getFirebaseErrorMessage(dynamic error) {
    if (error.toString().contains('email-already-in-use')) {
      return 'Email already in use. Please use another email or login';
    } else if (error.toString().contains('weak-password')) {
      return 'Password is too weak. Please use a more complex password';
    } else if (error.toString().contains('invalid-email')) {
      return 'Invalid email format';
    } else {
      return 'Registration failed: ${error.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: const Color(0xFF4A8F3C),
                width: 2,
              ),
            ),
            child: const Icon(Icons.arrow_back, color: Color(0xFF4A8F3C)),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/pixel_background.png'),
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/waterme_title.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: const Color(0xFF4A8F3C),
                        width: 3,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'REGISTER',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C5530),
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 用户名输入框
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'USERNAME',
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(
                                color: const Color(0xFF4A8F3C),
                                width: 2,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(
                                color: const Color(0xFF4A8F3C),
                                width: 2,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                          style: const TextStyle(
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 邮箱输入框
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'EMAIL',
                            prefixIcon: const Icon(Icons.email),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(
                                color: const Color(0xFF4A8F3C),
                                width: 2,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(
                                color: const Color(0xFF4A8F3C),
                                width: 2,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          style: const TextStyle(
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 密码输入框
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'PASSWORD',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(
                                color: const Color(0xFF4A8F3C),
                                width: 2,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(
                                color: const Color(0xFF4A8F3C),
                                width: 2,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          style: const TextStyle(
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 确认密码输入框
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'CONFIRM PASSWORD',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(
                                color: const Color(0xFF4A8F3C),
                                width: 2,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(
                                color: const Color(0xFF4A8F3C),
                                width: 2,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          style: const TextStyle(
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // 注册按钮
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A8F3C),
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              disabledBackgroundColor:
                                  const Color(0xFF4A8F3C).withOpacity(0.5),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'REGISTER',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      letterSpacing: 2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 登录链接
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'ALREADY HAVE AN ACCOUNT? LOGIN',
                            style: TextStyle(
                              color: Color(0xFF4A8F3C),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
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