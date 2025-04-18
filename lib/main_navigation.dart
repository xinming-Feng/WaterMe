import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/connect_page.dart';
import 'pages/data_page.dart';
import 'pages/myplant_page.dart';

// 创建一个全局变量来存储当前页面索引
int currentIndex = 0;

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    ConnectPage(),
    DataPage(),
    MyPlantPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // 更新全局变量
    currentIndex = _selectedIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // 更新全局变量
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/pixel_background.png'),
          alignment: const Alignment(0.0, -0.5),
          fit: BoxFit.cover,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: _pages.elementAt(_selectedIndex)),
        bottomNavigationBar: Container(
          height: 100,  // 设置固定高度以适应背景图
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/nav_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 8, bottom: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNavItem(0, 'assets/images/nav_home.png', 'Home'),
                _buildNavItem(1, 'assets/images/nav_connect.png', 'Connect'),
                _buildNavItem(2, 'assets/images/nav_data.png', 'Data'),
                _buildNavItem(3, 'assets/images/nav_plants.png', 'My Plants'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A8F3C).withOpacity(0.8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.8), width: 2)
              : null,
        ),
        child: Image.asset(
          iconPath,
          width: 80,
          height: 80,
          color: isSelected ? Colors.white : const Color(0xFFF4E6C8).withOpacity(0.9),
        ),
      ),
    );
  }
}
