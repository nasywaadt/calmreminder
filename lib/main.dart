import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mqtt_service.dart';
import 'sensor_data.dart';
import 'dart:math' as math;
import 'dart:collection';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MqttService()..connect(),
      child: const MyApp(),
    ),
  );
}

// Data history manager untuk EKG
class DataHistory extends ChangeNotifier {
  final Queue<double> _heartRateHistory = Queue();
  final Queue<double> _tempHistory = Queue();
  final int maxDataPoints = 30;

  void addHeartRate(int value) {
    _heartRateHistory.add(value.toDouble());
    if (_heartRateHistory.length > maxDataPoints) {
      _heartRateHistory.removeFirst();
    }
    notifyListeners();
  }

  void addTemp(double value) {
    _tempHistory.add(value);
    if (_tempHistory.length > maxDataPoints) {
      _tempHistory.removeFirst();
    }
    notifyListeners();
  }

  List<double> get heartRateHistory => _heartRateHistory.toList();
  List<double> get tempHistory => _tempHistory.toList();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calm Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final DataHistory _dataHistory = DataHistory();
  int _lastHeartRate = 0;
  double _lastTemp = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // Fungsi untuk menghitung stress level
  String _calculateStressLevel(SensorData data) {
    double movement = (data.accX.abs() + data.accY.abs() + data.accZ.abs()) / 3;

    if (data.heartRate < 85 && movement < 1.5 && data.temp < 37) {
      return "Relax";
    }

    if ((data.heartRate >= 85 && data.heartRate < 110) ||
        (movement >= 1.5 && movement < 3)) {
      return "Mild Stress";
    }

    if (data.heartRate >= 110 || movement >= 3 || data.temp >= 38) {
      return "High Stress";
    }

    return "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);
    final SensorData? data = mqtt.latest;

    // Update history when new data arrives
    if (data != null) {
      if (data.heartRate != _lastHeartRate) {
        _dataHistory.addHeartRate(data.heartRate);
        _lastHeartRate = data.heartRate;
      }
      if (data.temp != _lastTemp) {
        _dataHistory.addTemp(data.temp);
        _lastTemp = data.temp;
      }
    }

    // Hitung stress level
    String stressLevel = "Unknown";
    if (data != null) {
      stressLevel = data.stressLevel;
      if (stressLevel == "Unknown" || stressLevel.isEmpty) {
        stressLevel = _calculateStressLevel(data);
      }
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6DD5ED),
              Color(0xFF2193B0),
              Color(0xFF8E54E9),
              Color(0xFFCC2B5E),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: data == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        "Waiting for data...\nPastikan ESP32 mengirim MQTT.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Header with Brain Icon
                        _buildHeader(),
                        
                        const SizedBox(height: 30),

                        // Heart Rate & Temperature Cards with EKG
                        ListenableBuilder(
                          listenable: _dataHistory,
                          builder: (context, child) {
                            return Column(
                              children: [
                                _buildMetricCard(
                                  title: "Heart Rate",
                                  value: "${data.heartRate}",
                                  unit: "BPM",
                                  color: const Color(0xFF6DD5ED),
                                  icon: Icons.favorite,
                                  animation: _waveController,
                                  ekgData: _dataHistory.heartRateHistory,
                                ),
                                const SizedBox(height: 16),
                                _buildMetricCard(
                                  title: "Body Temp.",
                                  value: data.temp.toStringAsFixed(1),
                                  unit: "°C",
                                  color: const Color(0xFFFF6B9D),
                                  icon: Icons.thermostat,
                                  animation: _waveController,
                                  ekgData: _dataHistory.tempHistory,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // Mood Indicator
                        _buildMoodIndicator(stressLevel),

                        const SizedBox(height: 20),

                        // Stress Status Button
                        _buildStressButton(stressLevel),

                        const SizedBox(height: 30),

                        // Action Buttons
                        _buildActionButtons(),

                        const SizedBox(height: 20),

                        // Additional Info Cards
                        _buildInfoCard(
                          "Humidity",
                          "${data.hum.toStringAsFixed(1)}%",
                          Icons.water_drop,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildInfoCard(
                          "Movement (accZ)",
                          data.accZ.toStringAsFixed(2),
                          Icons.sensors,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🧠',
              style: TextStyle(fontSize: 40),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'MindSync Pro',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
    required AnimationController animation,
    required List<double> ekgData,
  }) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const Icon(Icons.info_outline, size: 16, color: Colors.white70),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // EKG Chart
                  SizedBox(
                    height: 40,
                    child: ekgData.isNotEmpty
                        ? CustomPaint(
                            size: const Size(double.infinity, 40),
                            painter: EKGPainter(
                              dataPoints: ekgData,
                              color: Colors.white,
                            ),
                          )
                        : const Center(
                            child: Text(
                              "Waiting...",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodIndicator(String stressLevel) {
    String emoji = stressLevel == "Relax" ? "😊" 
                  : stressLevel == "Mild Stress" ? "😐" 
                  : stressLevel == "High Stress" ? "😰"
                  : "😊";
    
    Color ringColor = stressLevel == "Relax" ? Colors.greenAccent
                     : stressLevel == "Mild Stress" ? Colors.orangeAccent
                     : Colors.redAccent;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ringColor.withOpacity(0.3 + (_pulseController.value * 0.3)),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: ringColor.withOpacity(0.4),
                blurRadius: 20 + (_pulseController.value * 10),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 50),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mood Indicator',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStressButton(String stressLevel) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stressLevel == "Relax" 
              ? [const Color(0xFF11998E), const Color(0xFF38EF7D)]
              : stressLevel == "Mild Stress"
                  ? [const Color(0xFFFFB75E), const Color(0xFFED8F03)]
                  : [const Color(0xFFE55D87), const Color(0xFF5FC3E4)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          stressLevel == "Relax" 
              ? "RELAXED 😊" 
              : stressLevel == "Mild Stress"
                  ? "MILD STRESS 😐"
                  : stressLevel == "High Stress"
                      ? "HIGH STRESS 😰"
                      : "UNKNOWN",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton("Relaxation Guides", Icons.spa, const Color(0xFF4ADE80)),
        _buildActionButton("Mood Journal", Icons.chat_bubble, const Color(0xFFA78BFA)),
        _buildActionButton("My Progress", Icons.show_chart, const Color(0xFF60A5FA)),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom EKG Painter
class EKGPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  EKGPainter({required this.dataPoints, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // Background grid
    final gridPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (dataPoints.length == 1) {
      final y = size.height / 2;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, y), 3, paint);
      return;
    }

    // Find min and max
    final minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final normalizedRange = range > 0 ? range : 1.0;

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Main line
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final glowPath = Path();
    
    for (int i = 0; i < dataPoints.length; i++) {
      final x = size.width * (i / (dataPoints.length - 1));
      final normalizedValue = (dataPoints[i] - minValue) / normalizedRange;
      final y = size.height - (size.height * normalizedValue * 0.7) - (size.height * 0.15);

      if (i == 0) {
        path.moveTo(x, y);
        glowPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        glowPath.lineTo(x, y);
      }
    }

    canvas.drawPath(glowPath, glowPaint);
    canvas.drawPath(path, paint);

    // Latest point with glow
    if (dataPoints.isNotEmpty) {
      final lastX = size.width;
      final normalizedValue = (dataPoints.last - minValue) / normalizedRange;
      final lastY = size.height - (size.height * normalizedValue * 0.7) - (size.height * 0.15);
      
      final pointGlowPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      
      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(lastX, lastY), 5, pointGlowPaint);
      canvas.drawCircle(Offset(lastX, lastY), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant EKGPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  WavePainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveLength = size.width / 3;
    final amplitude = 8.0;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 + 
                amplitude * math.sin((x / waveLength) * 2 * math.pi + (animationValue * 2 * math.pi));
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}