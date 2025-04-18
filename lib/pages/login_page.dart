import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'register_page.dart';
import '../main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await FirebaseService.loginUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          // 登录成功，导航到主页
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
    if (error.toString().contains('user-not-found')) {
      return 'User not found. Please check your email or register';
    } else if (error.toString().contains('wrong-password')) {
      return 'Wrong password. Please try again';
    } else if (error.toString().contains('too-many-requests')) {
      return 'Too many login attempts. Please try again later';
    } else {
      return 'Login failed: ${error.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C5530),
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
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
                              borderSide: const BorderSide(
                                color: Color(0xFF4A8F3C),
                                width: 2,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: const BorderSide(
                                color: Color(0xFF4A8F3C),
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
                              borderSide: const BorderSide(
                                color: Color(0xFF4A8F3C),
                                width: 2,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: const BorderSide(
                                color: Color(0xFF4A8F3C),
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
                        // 登录按钮
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
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
                                    'LOGIN',
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
                        // 注册链接
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'DON\'T HAVE AN ACCOUNT? REGISTER',
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