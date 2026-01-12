// lib/core/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user role
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      final role = userDoc.data()?['role'] ?? 'user';

      return {
        'success': true,
        'userId': credential.user!.uid,
        'email': credential.user!.email,
        'role': role,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getErrorMessage(e.code),
      };
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'deviceID': deviceId,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'userId': credential.user!.uid,
        'email': credential.user!.email,
        'role': 'user',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getErrorMessage(e.code),
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get error message
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'invalid-email':
        return 'Email tidak valid';
      default:
        return 'Terjadi kesalahan: $code';
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    if (currentUser == null) return false;
    
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      return userDoc.data()?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
}