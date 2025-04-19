import 'package:flutter/material.dart';
import '../widgets/pixel_title.dart';
import '../utils/plant_images.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import 'login_page.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyPlantPage extends StatefulWidget {
  const MyPlantPage({super.key});

  @override
  State<MyPlantPage> createState() => _MyPlantPageState();
}

class _MyPlantPageState extends State<MyPlantPage> {
  String? _avatarPath;
  String _username = '';
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _plants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatarPath();
    _loadUsername();
    _loadPlants();
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
  
  // 加载用户植物数据
  Future<void> _loadPlants() async {
    if (!FirebaseService.isUserLoggedIn) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      final userId = FirebaseService.currentUser!.uid;
      final snapshot = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .orderBy('created_at', descending: true)
          .get();
          
      final List<Map<String, dynamic>> plants = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        plants.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Plant',
          'species': data['species'] ?? '',
          'image': data['image'] ?? PlantImages.getRandomPlantImage(),
          'lastWatered': data['last_watered'] != null 
              ? DateFormat('yyyy-MM-dd').format((data['last_watered'] as Timestamp).toDate())
              : DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'nextWatering': data['next_watering'] != null
              ? DateFormat('yyyy-MM-dd').format((data['next_watering'] as Timestamp).toDate())
              : DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))),
          'device_id': data['device_id'] ?? '',
          'moisture': data['moisture'] ?? 0,
          'temperature': data['temperature'] ?? 0,
          'watering_interval': data['watering_interval'] ?? 7,
        });
      }
      
      setState(() {
        _plants = plants;
        _isLoading = false;
      });
    } catch (e) {
      print('加载植物数据失败: $e');
      setState(() {
        _isLoading = false;
      });
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

  // 更新最后浇水日期
  Future<void> updateLastWateredDate(int index) async {
    final plantId = _plants[index]['id'];
    final userId = FirebaseService.currentUser!.uid;
    final now = DateTime.now();
    
    // 计算下次浇水日期（基于设置的间隔）
    final nextWatering = now.add(Duration(days: _plants[index]['watering_interval']));
    
    try {
      // 更新Firebase
      await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .doc(plantId)
          .update({
        'last_watered': now,
        'next_watering': nextWatering,
      });
      
      // 更新本地状态
      setState(() {
        _plants[index]['lastWatered'] = DateFormat('yyyy-MM-dd').format(now);
        _plants[index]['nextWatering'] = DateFormat('yyyy-MM-dd').format(nextWatering);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新浇水记录失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete a plant
  Future<void> _deletePlant(int index) async {
    final plantId = _plants[index]['id'];
    final plantName = _plants[index]['name'];
    
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plant?', style: TextStyle(fontFamily: 'monospace')),
        content: Text(
          'Are you sure you want to delete "$plantName"? This action cannot be undone.',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: Color(0xFF4A8F3C), width: 2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Color(0xFF4A8F3C),
                fontFamily: 'monospace',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text(
              'DELETE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = FirebaseService.currentUser!.uid;
      await FirebaseService.deletePlant(userId, plantId);
      
      // Reload plants after deletion
      await _loadPlants();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deleted plant: $plantName',
            style: const TextStyle(
              fontFamily: 'monospace',
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      print('Failed to delete plant: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete plant: $e',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
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
                        'Hello, ${_username.isNotEmpty ? _username : "Plant Lover"}',
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
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF4A8F3C),
                              ),
                            )
                          : _plants.isEmpty
                              ? Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.zero,
                                      border: Border.all(
                                        color: const Color(0xFF4A8F3C),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.spa,
                                          size: 80,
                                          color: const Color(0xFF4A8F3C).withOpacity(0.7),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Your plant collection is empty',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C5530),
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Go to Connect page to add your first plant',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF2C5530),
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _plants.length,
                                  itemBuilder: (context, index) {
                                    final plant = _plants[index];
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Plant image
                                                Container(
                                                  width: 70,
                                                  height: 70,
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
                                                const SizedBox(width: 12),
                                                // Plant info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        plant['name'],
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF2C5530),
                                                          fontFamily: 'monospace',
                                                        ),
                                                      ),
                                                      if (plant['species'].isNotEmpty)
                                                        Text(
                                                          plant['species'],
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            fontStyle: FontStyle.italic,
                                                            color: Color(0xFF4A3B28),
                                                            fontFamily: 'monospace',
                                                          ),
                                                        ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.water_drop,
                                                            size: 14,
                                                            color: Color(0xFF4A8F3C),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Last: ${plant['lastWatered']}',
                                                            style: const TextStyle(
                                                              fontSize: 12,
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
                                                            size: 14,
                                                            color: Color(0xFFB87D44),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Next: ${plant['nextWatering']}',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              color: Color(0xFF4A3B28),
                                                              fontFamily: 'monospace',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (plant['device_id'].isNotEmpty)
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.sensors,
                                                              size: 14,
                                                              color: Color(0xFF4A8F3C),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'Moisture: ${plant['moisture']}%',
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                color: Color(0xFF4A3B28),
                                                                fontFamily: 'monospace',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                // Action buttons
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // Water button
                                                    IconButton(
                                                      icon: Container(
                                                        padding: const EdgeInsets.all(8),
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
                                                          size: 20,
                                                        ),
                                                      ),
                                                      iconSize: 40,
                                                      padding: EdgeInsets.zero,
                                                      onPressed: () {
                                                        updateLastWateredDate(index);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'WATERED ${plant['name'].toUpperCase()}',
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
                                                    const SizedBox(width: 8),
                                                    // Delete button
                                                    IconButton(
                                                      icon: Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.shade700,
                                                          borderRadius: BorderRadius.zero,
                                                          border: Border.all(
                                                            color: Colors.white,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.delete,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      iconSize: 40,
                                                      padding: EdgeInsets.zero,
                                                      onPressed: () => _deletePlant(index),
                                                    ),
                                                  ],
                                                ),
                                              ],
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
