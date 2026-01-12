import 'package:calmreminder/core/models/sensor_data.dart';
import 'package:calmreminder/core/models/user_data.dart';
import 'package:calmreminder/core/mqtt/mqtt_service.dart';
import 'firebase_service.dart';

class MqttFirebaseBridge {
  final FirebaseService _firebaseService = FirebaseService();
  final String userId;
  final String email;
  final String role;
  final String deviceId; // Diubah dari username ke deviceId agar sinkron dengan Firestore

  MqttFirebaseBridge({
    required this.userId,
    required this.email,
    required this.role,
    required this.deviceId,
  });

  // Menjalankan bridge untuk mendengarkan perubahan data di MQTT
  void startBridge(MqttService mqttService) {
    mqttService.addListener(() {
      final sensorData = mqttService.latest;
      if (sensorData != null) {
        _saveSensorDataToFirebase(sensorData);
      }
    });
  }

Future<void> _saveSensorDataToFirebase(SensorData sensorData) async {
    try {
      print('Attempting to save to Firebase for user: $userId'); // Debug log
      final now = DateTime.now();
      
      final userData = UserData(
        userId: userId,
        deviceId: deviceId,
        email: email,
        role: role,
        heartRate: sensorData.heartRate,
        temp: sensorData.temp,
        accX: sensorData.accX,
        accY: sensorData.accY,
        accZ: sensorData.accZ,
        stressLevel: sensorData.stressLevel,
        timestamp: now,
        timeCategory: _getTimeCategory(now),
      );

      // Pastikan method di bawah ini menggunakan await
      await _firebaseService.saveUserData(userData);
      print('✅ Data berhasil masuk ke Firestore');
      
      await _firebaseService.updateLastActive(userId);
    } catch (e, stacktrace) {
      print('❌ Error Bridge MQTT ke Firebase: $e');
      print('📌 Stacktrace: $stacktrace'); // Ini akan memberitahu baris mana yang error
    }
  }

  String _getTimeCategory(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return 'Pagi';
    if (hour >= 12 && hour < 17) return 'Siang';
    return 'Malam';
  }
}