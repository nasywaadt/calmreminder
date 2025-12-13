import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';
import 'sensor_data.dart';
import 'stress_logic.dart';

class MqttService with ChangeNotifier {
  late MqttServerClient client;
  SensorData? latest;

  Future<void> connect() async {
    client = MqttServerClient('broker.mqtt-dashboard.com', 'flutter_client_calmreminder_02');
    client.port = 1883;
    client.keepAlivePeriod = 60;

    final msg = MqttConnectMessage()
        .withClientIdentifier("calmreminder_monitor_2")
        .startClean()
        .keepAliveFor(60);

    client.connectionMessage = msg;

    try {
      await client.connect();
      print("MQTT Connected");
    } catch (e) {
      print("MQTT ERROR: $e");
      client.disconnect();
    }

    client.subscribe("sensor/data/calmreminder", MqttQos.atMostOnce);

    client.updates!.listen((events) {
      final MqttPublishMessage msg = events.first.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        msg.payload.message,
      );

      print("RAW: $payload");

      

      try {
        final jsonData = jsonDecode(payload);
        SensorData data = SensorData.fromJson(jsonData);

        // 🔥 Apply Stress Logic
        String stress = StressLogic.analyze(
          heartRate: data.heartRate,
          temp: data.temp,
          accX: data.accX,
          accY: data.accY,
          accZ: data.accZ,
        );

        latest = data.copyWithStress(stress);
        notifyListeners();

        print("Stress Level: $stress");
      } catch (e) {
        print("JSON ERROR: $e");
      }
    });
  }
}
