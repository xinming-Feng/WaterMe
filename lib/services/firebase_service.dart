import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 暴露Firestore实例，方便直接访问
  static FirebaseFirestore get firestore => _firestore;
  
  // 初始化 Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    
    // 打印当前用户信息，用于调试
    if (_auth.currentUser != null) {
      print('当前已登录用户: ${_auth.currentUser!.email} (${_auth.currentUser!.uid})');
    } else {
      print('当前没有登录用户');
    }
  }
  
  // 获取当前用户
  static User? get currentUser => _auth.currentUser;
  
  // 用户是否已登录
  static bool get isUserLoggedIn => _auth.currentUser != null;
  
  // 注册新用户
  static Future<UserCredential> registerUser({
    required String email, 
    required String password,
    required String username,
  }) async {
    try {
      // 创建新用户
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 创建用户资料
      await _createUserProfile(
        userId: userCredential.user!.uid,
        email: email,
        username: username,
      );
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }
  
  // 创建用户资料
  static Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String username,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'email': email,
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }
  
  // 用户登录
  static Future<UserCredential> loginUser({
    required String email, 
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 更新最后登录时间
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }
  
  // 用户登出
  static Future<void> logoutUser() async {
    await _auth.signOut();
  }
  
  // 重置密码
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  // 获取用户资料
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? doc.data() as Map<String, dynamic>? : null;
  }
  
  // 更新用户资料
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }
  
  // 获取用户的所有植物
  static Future<List<Map<String, dynamic>>> getUserPlants(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('获取用户植物失败: $e');
      return [];
    }
  }
  
  // 获取用户的所有设备
  static Future<List<Map<String, dynamic>>> getUserDevices(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('获取用户设备失败: $e');
      return [];
    }
  }
  
  // 添加新植物
  static Future<String> addPlant(String userId, Map<String, dynamic> plantData) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .add(plantData);
      
      return docRef.id;
    } catch (e) {
      print('添加植物失败: $e');
      rethrow;
    }
  }
  
  // 添加新设备
  static Future<void> addDevice(String userId, String deviceId, Map<String, dynamic> deviceData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .set(deviceData);
    } catch (e) {
      print('添加设备失败: $e');
      rethrow;
    }
  }
  
  // 更新植物信息
  static Future<void> updatePlant(String userId, String plantId, Map<String, dynamic> updateData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .doc(plantId)
          .update(updateData);
    } catch (e) {
      print('更新植物信息失败: $e');
      rethrow;
    }
  }
  
  // 删除植物
  static Future<void> deletePlant(String userId, String plantId) async {
    try {
      // Get plant info to check if it has a device
      final plantDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .doc(plantId)
          .get();
      
      if (!plantDoc.exists) {
        throw Exception('Plant not found');
      }
      
      final plantData = plantDoc.data();
      
      // First delete all history records
      final historySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .doc(plantId)
          .collection('history')
          .get();
      
      final batch = _firestore.batch();
      
      // Add history deletion to batch
      for (var doc in historySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Add plant deletion to batch
      batch.delete(plantDoc.reference);
      
      // If the plant has a device that's not used by other plants, we could delete it
      // This is optional and depends on your business logic
      final deviceId = plantData?['device_id'];
      if (deviceId != null && deviceId.isNotEmpty) {
        // Check if any other plants use this device
        final otherPlantsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('plants')
            .where('device_id', isEqualTo: deviceId)
            .where(FieldPath.documentId, isNotEqualTo: plantId)
            .get();
        
        // If no other plants use this device, delete it
        if (otherPlantsSnapshot.docs.isEmpty) {
          final deviceDoc = _firestore
              .collection('users')
              .doc(userId)
              .collection('devices')
              .doc(deviceId);
          
          batch.delete(deviceDoc);
        }
      }
      
      // Commit the batch
      await batch.commit();
      
    } catch (e) {
      print('删除植物失败: $e');
      rethrow;
    }
  }
  
  // 添加植物数据历史记录
  static Future<void> addPlantHistory(String userId, String plantId, Map<String, dynamic> historyData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .doc(plantId)
          .collection('history')
          .add({
            ...historyData,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('添加植物历史记录失败: $e');
      rethrow;
    }
  }
  
  // 获取植物历史数据
  static Future<List<Map<String, dynamic>>> getPlantHistory(
    String userId, 
    String plantId, 
    {int limit = 10}
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('plants')
          .doc(plantId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('获取植物历史数据失败: $e');
      return [];
    }
  }

  // MQTT客户端
  MqttServerClient? _client;
  final String _mqttServer = "4.tcp.eu.ngrok.io"; // 需要更新
  final int _mqttPort = 13087; // 需要更新
  final String _mqttUsername = "CEgroup1"; // 需要更新
  final String _mqttPassword = "group111111"; // 需要更新
} 