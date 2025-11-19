import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mqtt_service.dart';
import 'sensor_data.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MqttService()..connect(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Mental Health Monitor',
      debugShowCheckedModeBanner: false,
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);
    final SensorData? data = mqtt.latest;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Mental Health Monitor"),
        backgroundColor: Colors.teal,
      ),

      body: data == null
          ? const Center(
              child: Text(
                "Waiting for data...\nPastikan ESP32 mengirim MQTT.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STATUS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Stress Level",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          data.stressLevel,
                          style: TextStyle(
                            fontSize: 28,
                            color: data.stressLevel == "Relax"
                                ? Colors.green
                                : data.stressLevel == "Mild Stress"
                                    ? Colors.orange
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // HEART RATE
                  buildCard(
                    title: "Heart Rate",
                    value: "${data.heartRate} bpm",
                    icon: Icons.favorite,
                    color: Colors.red,
                  ),

                  // TEMPERATURE
                  buildCard(
                    title: "Temperature",
                    value: "${data.temp.toStringAsFixed(1)} °C",
                    icon: Icons.thermostat,
                    color: Colors.orange,
                  ),

                  // HUMIDITY
                  buildCard(
                    title: "Humidity",
                    value: "${data.hum.toStringAsFixed(1)} %",
                    icon: Icons.water_drop,
                    color: Colors.blue,
                  ),

                  // MPU6050 MOVEMENT
                  buildCard(
                    title: "Movement (accZ)",
                    value: data.accZ.toStringAsFixed(2),
                    icon: Icons.sensors,
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ],
          )
        ],
      ),
    );
  }
}
