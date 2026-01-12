import 'package:calmreminder/core/models/admin_message.dart';
import 'package:calmreminder/core/models/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- SENSOR DATA ---
  Future<void> saveUserData(UserData data) async {
  try {
        final docRef = await _firestore
            .collection('users')
            .doc(data.userId)
            .collection('sensor_data')
            .add(data.toJson());
        
        // Tambahkan print ini untuk melihat ID unik dokumen di terminal
        print('✅ Data masuk ke Firestore. Doc ID: ${docRef.id}'); 
      } catch (e) {
        print('Error saving sensor data: $e');
      }
    }

  Stream<List<UserData>> getUserSensorData(String userId, {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sensor_data')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserData.fromFirestore(doc.data(), doc.id))
            .toList());
  }

   // Get data by time category
  Stream<List<UserData>> getUserDataByTimeCategory(String userId, String category) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sensor_data')
        .where('timeCategory', isEqualTo: category)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserData.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // --- USER MANAGEMENT ---
  Stream<List<Map<String, dynamic>>> getUsersList() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'email': data['email'] ?? 'No email',
          'deviceId': data['deviceId'] ?? 'No device',
          'role': data['role'] ?? 'user',
        };
      }).toList();
    });
  }

  Future<void> updateLastActive(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating activity: $e');
    }
  }

  // --- MESSAGE SYSTEM (Admin to User) ---

  // Admin: Kirim pesan terstruktur
  Future<void> sendMessageToUser({
    required String userId,
    required String title,
    required String subtitle,
    required String message,
    required String emoji,
    required List<String> tips,
    required String stressLevel,
  }) async {
    try {
      await _firestore
          .collection('messages')
          .doc(userId)
          .collection('admin_messages')
          .add({
        'userId': userId,
        'title': title,
        'subtitle': subtitle,
        'message': message,
        'emoji': emoji,
        'tips': tips,
        'stressLevel': stressLevel,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      print('✅ Pesan terstruktur terkirim ke $userId');
    } catch (e) {
      print('❌ Gagal kirim pesan: $e');
      rethrow;
    }
  }

  // User: Ambil pesan terbaru dari Admin
  Stream<List<AdminMessage>> getUserMessages(String userId) {
    return _firestore
        .collection('messages')
        .doc(userId)
        .collection('admin_messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminMessage.fromJson(doc.data(), doc.id))
            .toList());
  }

  // User: Tandai pesan dibaca
  Future<void> markMessageAsRead(String userId, String messageId) async {
    try {
      await _firestore
          .collection('messages')
          .doc(userId)
          .collection('admin_messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      print('Error read status: $e');
    }
  }
}