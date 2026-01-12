import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
// WAJIB: Gunakan MqttBrowserClient untuk Flutter Web
import 'package:mqtt_client/mqtt_browser_client.dart';

import '../models/sensor_data.dart';
import '../logic/stress_logic.dart';

class MqttService with ChangeNotifier {
  // Gunakan Browser Client agar tidak crash di Web
  MqttService() {
    print("DEBUG: MqttService diinisialisasi");
  }

  late MqttBrowserClient client;
  SensorData? latest;

  Future<void> connect() async {
    // 1. Inisialisasi Client dengan URL WSS lengkap (Wajib untuk HiveMQ Cloud di Web)
    // Format: wss://[HOST]/mqtt
    const String host = '6edfad2acaf04ec9aae0a1e285878cb8.s1.eu.hivemq.cloud';
    
    client = MqttBrowserClient.withPort(
      'wss://$host/mqtt', 
      'flutter_web_client_${DateTime.now().millisecondsSinceEpoch}',
      8884,
    );

    // 2. Konfigurasi Protokol dan Keamanan
    client.setProtocolV311();
    client.keepAlivePeriod = 60;
    client.logging(on: true); // Aktifkan untuk melihat log di Console F12

    // 3. Konfigurasi Pesan Koneksi & Autentikasi
    // PASTIKAN: Username dan Password sudah dibuat di tab "Access Management" HiveMQ Cloud
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .authenticateAs(
          'calmreminder', // Ganti dengan Username dari Access Management
          'Calmreminder123', // Ganti dengan Password dari Access Management
        )
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMessage;

    try {
      debugPrint("⏳ Mencoba menyambungkan ke HiveMQ Cloud (Web)...");
      await client.connect();
      debugPrint("✅ MQTT Terhubung!");
    } catch (e) {
      debugPrint("❌ Gagal Terhubung: $e");
      client.disconnect();
      return;
    }

    // 4. Subscribe ke Topik
    client.subscribe('sensor/data/calmreminder', MqttQos.atMostOnce);

    // 5. Listen Data Masuk
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final MqttPublishMessage recMess = events[0].payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );

      debugPrint("📥 Pesan Diterima: $payload");

      try {
        final Map<String, dynamic> jsonData = jsonDecode(payload);
        SensorData data = SensorData.fromJson(jsonData);

        // Analisis Stress menggunakan logika yang ada
        final stress = StressLogic.analyze(
          heartRate: data.heartRate,
          temp: data.temp,
          accX: data.accX,
          accY: data.accY,
          accZ: data.accZ,
        );

        // Update data terbaru dan beri tahu Dashboard
        latest = data.copyWithStress(stress);
        notifyListeners();
        
      } catch (e) {
        debugPrint("❌ Error Parsing JSON: $e");
      }
    });
  }

  void disconnect() {
    client.disconnect();
    debugPrint("🔌 MQTT Terputus");
  }
}