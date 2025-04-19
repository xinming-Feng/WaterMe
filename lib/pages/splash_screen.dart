import 'package:flutter/material.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../main_navigation.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 创建动画控制器
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // 创建不透明度动画
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    
    // 创建缩放动画
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    // 启动动画
    _controller.forward();
    
    // 3秒后导航到下一个页面
    Timer(const Duration(milliseconds: 3000), () {
      // 创建淡出效果
      _controller.reverse().then((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FirebaseService.isUserLoggedIn
                ? const MainNavigation(initialIndex: 0)
                : const LoginPage(),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 使用新的静态图片
                    Image.asset(
                      'assets/images/splash.png',
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 30),
                    // 加载指示器
                    const CircularProgressIndicator(
                      color: Color(0xFF4A8F3C),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "watering...",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'monospace',
                        color: Color(0xFF4A8F3C),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 