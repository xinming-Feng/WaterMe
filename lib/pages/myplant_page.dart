import 'package:flutter/material.dart';
import '../widgets/pixel_title.dart';
import '../utils/plant_images.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import 'login_page.dart';
import 'dart:io';

class MyPlantPage extends StatefulWidget {
  const MyPlantPage({super.key});

  @override
  State<MyPlantPage> createState() => _MyPlantPageState();
}

class _MyPlantPageState extends State<MyPlantPage> {
  String? _avatarPath;
  String _username = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAvatarPath();
    _loadUsername();
  }

  Future<void> _loadAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _avatarPath = prefs.getString('user_avatar');
    });
  }

  Future<void> _loadUsername() async {
    if (FirebaseService.isUserLoggedIn) {
      try {
        final userId = FirebaseService.currentUser!.uid;
        final userProfile = await FirebaseService.getUserProfile(userId);
        if (userProfile != null && userProfile['username'] != null) {
          setState(() {
            _username = userProfile['username'];
          });
        }
      } catch (e) {
        print('Failed to load username: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar', image.path);
        setState(() {
          _avatarPath = image.path;
        });
      }
    } catch (e) {
      // 处理错误
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to select image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseService.logoutUser();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF4A8F3C).withOpacity(0.1),
          border: Border.all(
            color: const Color(0xFF4A8F3C),
            width: 2,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: _avatarPath != null
              ? Image.file(
                  File(_avatarPath!),
                  fit: BoxFit.cover,
                )
              : const Icon(
                  Icons.person_add,
                  color: Color(0xFF4A8F3C),
                  size: 30,
                ),
        ),
      ),
    );
  }

  // 模拟植物数据
  final List<Map<String, dynamic>> plants = [
    {
      'name': 'Pothos',
      'species': 'Epipremnum aureum',
      'image': PlantImages.getPlantImageByIndex(0),
      'lastWatered': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'nextWatering': '2023-04-20',
      'health': 'Good',
    },
    {
      'name': 'Succulent',
      'species': 'Echeveria',
      'image': PlantImages.getPlantImageByIndex(1),
      'lastWatered': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'nextWatering': '2023-04-25',
      'health': 'Good',
    },
    {
      'name': 'Cactus',
      'species': 'Cactaceae',
      'image': PlantImages.getPlantImageByIndex(2),
      'lastWatered': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'nextWatering': '2023-05-01',
      'health': 'Needs Attention',
    },
  ];

  void updateLastWateredDate(int index) {
    setState(() {
      plants[index]['lastWatered'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      // 计算下次浇水时间（1天后）
      plants[index]['nextWatering'] = DateFormat('yyyy-MM-dd').format(
        DateTime.now().add(const Duration(days: 1)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const PixelTitle(height: 80, centerTitle: false),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A8F3C),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 20),
              ),
              onPressed: _logout,
              tooltip: 'LOGOUT',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/pixel_background.png'),
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Row(
                  children: [
                    _buildAvatar(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: const Color(0xFF4A8F3C),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'Hello, ${_username.isNotEmpty ? _username : "植物爱好者"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C5530),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: const Color(0xFF4A8F3C),
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        'MY PLANT COLLECTION',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C5530),
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: plants.length,
                        itemBuilder: (context, index) {
                          final plant = plants[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.zero,
                              border: Border.all(
                                color: const Color(0xFF4A8F3C),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.zero,
                                      border: Border.all(
                                        color: const Color(0xFF4A8F3C),
                                        width: 2,
                                      ),
                                    ),
                                    child: Image.asset(
                                      plant['image'],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plant['name'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C5530),
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        Text(
                                          plant['species'],
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Color(0xFF4A3B28),
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.water_drop,
                                              size: 16,
                                              color: Color(0xFF4A8F3C),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Last: ${plant['lastWatered']}',
                                              style: const TextStyle(
                                                color: Color(0xFF4A3B28),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Color(0xFFB87D44),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Next: ${plant['nextWatering']}',
                                              style: const TextStyle(
                                                color: Color(0xFF4A3B28),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4A8F3C),
                                          borderRadius: BorderRadius.zero,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.water_drop,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      iconSize: 52,
                                      onPressed: () {
                                        updateLastWateredDate(index);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'WATERED ${plants[index]['name'].toUpperCase()}',
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                letterSpacing: 1,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: const Color(0xFF4A8F3C),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
