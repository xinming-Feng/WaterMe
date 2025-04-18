import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 初始化 Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
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
} 