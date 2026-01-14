// lib/pages/user/user_dashboard.dart

import 'package:calmreminder/services/mqtt_firebase_bridge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Tambahkan ini
import '../../core/mqtt/mqtt_service.dart';
import '../../core/models/sensor_data.dart';
import 'dart:collection';
import 'dart:math' as math;
import 'relaxation_guides_page.dart';
import 'mood_journal_page.dart';
import 'my_progress_page.dart';
import 'package:calmreminder/pages/about_page.dart';

// Data history manager untuk EKG
class DataHistory extends ChangeNotifier {
  final Queue<double> _heartRateHistory = Queue();
  final Queue<double> _tempHistory = Queue();
  final Queue<String> _stressHistory = Queue();
  final Queue<DateTime> _timestamps = Queue();
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

  void addStressLevel(String level) {
    _stressHistory.add(level);
    _timestamps.add(DateTime.now());
    if (_stressHistory.length > maxDataPoints) {
      _stressHistory.removeFirst();
      _timestamps.removeFirst();
    }
    notifyListeners();
  }

  List<double> get heartRateHistory => _heartRateHistory.toList();
  List<double> get tempHistory => _tempHistory.toList();
  List<String> get stressHistory => _stressHistory.toList();
  List<DateTime> get timestamps => _timestamps.toList();
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
  String _lastStressLevel = "";
  
  MqttFirebaseBridge? _mqttBridge;
  bool _isBridgeStarted = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isBridgeStarted) {
      final mqtt = Provider.of<MqttService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        _mqttBridge = MqttFirebaseBridge(
          userId: user.uid, 
          email: user.email ?? 'user@gmail.com',
          role: 'user',
          deviceId: 'ESP32_01', 
        );
        _mqttBridge!.startBridge(mqtt);
        _isBridgeStarted = true;
        debugPrint("🚀 Mqtt-Firebase Bridge Started for: ${user.email}");
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _calculateStressLevel(SensorData data) {
    double movement = (data.accX.abs() + data.accY.abs() + data.accZ.abs()) / 3;

    if (data.heartRate < 85 && movement < 1.5 && data.temp < 37) {
      return "Relax";
    }
    if ((data.heartRate >= 85 && data.heartRate < 110) || (movement >= 1.5 && movement < 3)) {
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

    String stressLevel = "Unknown";
    if (data != null) {
      stressLevel = data.stressLevel.isEmpty ? _calculateStressLevel(data) : data.stressLevel;
      if (stressLevel != _lastStressLevel) {
        _dataHistory.addStressLevel(stressLevel);
        _lastStressLevel = stressLevel;
      }
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6DD5ED), Color(0xFF2193B0), Color(0xFF8E54E9), Color(0xFFCC2B5E)],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: data == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildHeader(context), // Kirim context untuk logout
                        const SizedBox(height: 30),
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
                        _buildMoodIndicator(stressLevel),
                        const SizedBox(height: 20),
                        _buildStressButton(stressLevel),
                        const SizedBox(height: 30),
                        _buildActionButtons(context, stressLevel, _dataHistory),
                        const SizedBox(height: 12),
                        _buildInfoCard("Movement (accZ)", data.accZ.toStringAsFixed(2), Icons.sensors),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
  return Row(
    children: [
      // === KIRI KOSONG (agar judul tetap tengah secara visual) ===
      const SizedBox(width: 110),

      // === TENGAH: LOGO & JUDUL ===
      Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('💜', style: TextStyle(fontSize: 35)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Calm Reminder',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),

      const Spacer(), // 🔑 PEMISAH UTAMA

      // === KANAN: ABOUT + LOGOUT (MEPET) ===
      Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'Tentang Aplikasi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
    ],
  );
}

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Provider.of<MqttService>(context, listen: false).disconnect();
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String stressLevel, DataHistory history) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _buildActionItem(context, "Relaxation", Icons.spa, const Color(0xFF4ADE80), 
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => RelaxationGuidesPage(stressLevel: stressLevel)))),
        _buildActionItem(context, "Journal", Icons.chat_bubble, const Color(0xFFA78BFA), 
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodJournalPage()))),
        _buildActionItem(context, "Progress", Icons.show_chart, const Color(0xFF60A5FA), 
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyProgressPage(dataHistory: history)))),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- SISA WIDGET (MetricCard, MoodIndicator, dll) TETAP SAMA SEPERTI SEBELUMNYA ---
  
  Widget _buildMetricCard({required String title, required String value, required String unit, required Color color, required IconData icon, required AnimationController animation, required List<double> ekgData}) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.white)), const Icon(Icons.info_outline, color: Colors.white70)]),
                const Spacer(),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(value, style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Text(unit, style: const TextStyle(color: Colors.white70)),
                ]),
                const SizedBox(height: 8),
                SizedBox(height: 40, child: CustomPaint(size: const Size(double.infinity, 40), painter: EKGPainter(dataPoints: ekgData, color: Colors.white))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodIndicator(String stressLevel) {
    String emoji = stressLevel == "Relax" ? "😊" : stressLevel == "Mild Stress" ? "😐" : "😰";
    Color ringColor = stressLevel == "Relax" ? Colors.greenAccent : stressLevel == "Mild Stress" ? Colors.orangeAccent : Colors.redAccent;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        width: 180, height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor.withOpacity(0.3 + (_pulseController.value * 0.3)), width: 3),
        ),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(emoji, style: const TextStyle(fontSize: 50)), const Text('Mood Indicator', style: TextStyle(color: Colors.white70))])),
      ),
    );
  }

  Widget _buildStressButton(String stressLevel) {
    return Container(
      width: double.infinity, height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: stressLevel == "Relax" ? [Colors.teal, Colors.green] : [Colors.orange, Colors.red]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(child: Text(stressLevel.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [Icon(icon, color: Colors.white70), const SizedBox(width: 16), Text(title, style: const TextStyle(color: Colors.white)), const Spacer(), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
    );
  }
}

class EKGPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  EKGPainter({required this.dataPoints, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // Background grid (opsional)
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

    // ===== BAGIAN PENTING: NORMALISASI DATA =====
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
      
      // Normalisasi nilai data ke koordinat Y
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

    // Latest point with glow (titik terakhir)
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