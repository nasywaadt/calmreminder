import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String userId;
  final String deviceId;    // Disesuaikan dengan gambar Firestore
  final String email;
  final String role;        // user atau admin
  final int heartRate;
  final double temp;
  final double accX;
  final double accY;
  final double accZ;
  final String stressLevel;
  final DateTime timestamp;
  final String timeCategory;

  UserData({
    required this.userId,
    required this.deviceId,
    required this.email,
    required this.role,
    required this.heartRate,
    required this.temp,
    required this.accX,
    required this.accY,
    required this.accZ,
    required this.stressLevel,
    required this.timestamp,
    required this.timeCategory,
  });

  // Factory untuk menangani data dari Firestore (menggunakan DocumentSnapshot)
  factory UserData.fromFirestore(Map<String, dynamic> json, String id) {
    // Menangani timestamp dari Firestore (biasanya tipe Timestamp, bukan String)
    DateTime parsedTime;
    if (json['timestamp'] is Timestamp) {
      parsedTime = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      parsedTime = DateTime.parse(json['timestamp']);
    } else {
      parsedTime = DateTime.now();
    }

    return UserData(
      userId: id,
      deviceId: json['deviceId'] ?? json['deviceId'] ?? 'Unknown Device',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      heartRate: (json['heartRate'] ?? 0).toInt(),
      temp: (json['temp'] ?? 0).toDouble(),
      accX: (json['accX'] ?? 0).toDouble(),
      accY: (json['accY'] ?? 0).toDouble(),
      accZ: (json['accZ'] ?? 0).toDouble(),
      stressLevel: json['stressLevel'] ?? 'Unknown',
      timestamp: parsedTime,
      timeCategory: json['timeCategory'] ?? _calculateTimeCategory(parsedTime),
    );
  }

  // Map untuk menyimpan ke Firestore
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'deviceId': deviceId,
    'email': email,
    'role': role,
    'heartRate': heartRate,
    'temp': temp,
    'accX': accX,
    'accY': accY,
    'accZ': accZ,
    'stressLevel': stressLevel,
    'timestamp': Timestamp.fromDate(timestamp), // Simpan sebagai Timestamp Firestore
    'timeCategory': timeCategory,
  };

  static String _calculateTimeCategory(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'Pagi';
    if (hour >= 12 && hour < 17) return 'Siang';
    return 'Malam';
  }
}