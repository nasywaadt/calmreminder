// lib/pages/admin/analytics_page.dart

import 'package:calmreminder/services/analytics_service.dart';
import 'package:calmreminder/services/firebase_service.dart';
import 'package:flutter/material.dart';
import '../../core/models/user_data.dart';
import 'dart:math' as math;

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  String? _selectedUserId;
  String _selectedUserEmail = '';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
              Color(0xFF667EEA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildUserSelector(),
              Expanded(
                child: _selectedUserId == null 
                  ? _buildEmptyState()
                  : _buildAnalyticsContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            '📊 System Analytics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSelector() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getUsersList(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: LinearProgressIndicator(color: Colors.white),
          );
        }

        final users = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text(
                '👤 Select User to Analyze',
                style: TextStyle(color: Colors.white70),
              ),
              value: _selectedUserId,
              dropdownColor: const Color(0xFF764BA2),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: users.map((user) {
                return DropdownMenuItem(
                  value: user['userId'] as String,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user['email'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'ID: ${(user['userId'] as String).substring(0, 8)}...',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final selectedUser = users.firstWhere((u) => u['userId'] == value);
                  setState(() {
                    _selectedUserId = value;
                    _selectedUserEmail = selectedUser['email'] as String;
                  });
                  _animController.reset();
                  _animController.forward();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('📈', style: TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No User Selected',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a user to view detailed analytics',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return StreamBuilder<List<UserData>>(
      stream: _firebaseService.getUserSensorData(_selectedUserId!, limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📭', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                Text(
                  'No Data Available',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'User hasn\'t generated any sensor data yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final summary = AnalyticsService.getDailySummary(data);
        final stressDist = summary['stressDistribution'] as Map<String, double>;
        final avgBpmByTime = AnalyticsService.calculateAverageBPMByTime(data);
        final stressComparison = AnalyticsService.compareStressByTime(data);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _animController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Header
                _buildUserInfoCard(),
                
                const SizedBox(height: 20),

                // Quick Stats Grid
                _buildQuickStatsGrid(summary),

                const SizedBox(height: 20),

                // Stress Distribution
                _buildStressDistributionCard(stressDist),

                const SizedBox(height: 20),

                // BPM by Time Category
                _buildBPMByTimeCard(avgBpmByTime),

                const SizedBox(height: 20),

                // AI Insights
                _buildInsightsCard(stressComparison),

                const SizedBox(height: 20),

                // Hourly Chart
                _buildHourlyChartCard(data),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analyzing Data For',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedUserEmail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent, width: 1),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid(Map<String, dynamic> summary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Average BPM',
          '${summary['averageBPM']}',
          Icons.favorite,
          const Color(0xFFFF6B9D),
        ),
        _buildStatCard(
          'Total Records',
          '${summary['totalRecords']}',
          Icons.analytics,
          const Color(0xFF4ADE80),
        ),
        _buildStatCard(
          'Stress Time',
          '${summary['totalStressTime']} min',
          Icons.timer,
          const Color(0xFFFFB75E),
        ),
        _buildStatCard(
          'Peak Hour',
          '${summary['mostStressfulHour']}:00',
          Icons.access_time,
          const Color(0xFF60A5FA),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressDistributionCard(Map<String, double> stressDist) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Stress Distribution',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressRow(
            'Relax',
            stressDist['Relax'] ?? 0,
            Colors.greenAccent,
            '😊',
          ),
          const SizedBox(height: 12),
          _buildProgressRow(
            'Mild Stress',
            stressDist['Mild Stress'] ?? 0,
            Colors.orangeAccent,
            '😐',
          ),
          const SizedBox(height: 12),
          _buildProgressRow(
            'High Stress',
            stressDist['High Stress'] ?? 0,
            Colors.redAccent,
            '😰',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double value, Color color, String emoji) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildBPMByTimeCard(Map<String, double> avgBpmByTime) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.schedule, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Average BPM by Time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimeCard('🌅 Pagi (05:00 - 11:59)', avgBpmByTime['Pagi'] ?? 0, Colors.amber),
          const SizedBox(height: 12),
          _buildTimeCard('☀️ Siang (12:00 - 16:59)', avgBpmByTime['Siang'] ?? 0, Colors.orange),
          const SizedBox(height: 12),
          _buildTimeCard('🌙 Malam (17:00 - 04:59)', avgBpmByTime['Malam'] ?? 0, Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String label, double bpm, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${bpm.toStringAsFixed(1)} BPM',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(Map<String, String> stressComparison) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.3),
            Colors.pink.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb, color: Colors.yellow, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Most Stressful: ${stressComparison['mostStressful']}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Least Stressful: ${stressComparison['leastStressful']}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stressComparison['insight'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChartCard(List<UserData> data) {
    final hourlyData = AnalyticsService.getHourlyStressData(data);
    
    if (hourlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Hourly Stress Pattern',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: HourlyChartPainter(hourlyData: hourlyData),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegend(Colors.greenAccent, 'Relax'),
              _buildLegend(Colors.orangeAccent, 'Mild'),
              _buildLegend(Colors.redAccent, 'High'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Hourly Chart
class HourlyChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> hourlyData;

  HourlyChartPainter({required this.hourlyData});

  @override
  void paint(Canvas canvas, Size size) {
    if (hourlyData.isEmpty) return;

    final maxValue = hourlyData.fold<int>(0, (max, data) {
      final total = (data['relax'] as int) + (data['mild'] as int) + (data['high'] as int);
      return total > max ? total : max;
    });

    if (maxValue == 0) return;

    final barWidth = size.width / hourlyData.length;
    final padding = barWidth * 0.2;

    for (int i = 0; i < hourlyData.length; i++) {
      final data = hourlyData[i];
      final relax = data['relax'] as int;
      final mild = data['mild'] as int;
      final high = data['high'] as int;
      final total = relax + mild + high;

      if (total == 0) continue;

      final x = i * barWidth + padding;
      final barActualWidth = barWidth - (padding * 2);

      // Draw stacked bars
      double currentY = size.height;

      // High stress (bottom)
      if (high > 0) {
        final highHeight = (high / maxValue) * size.height;
        final highRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, currentY - highHeight, barActualWidth, highHeight),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          highRect,
          Paint()..color = Colors.redAccent,
        );
        currentY -= highHeight;
      }

      // Mild stress (middle)
      if (mild > 0) {
        final mildHeight = (mild / maxValue) * size.height;
        final mildRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, currentY - mildHeight, barActualWidth, mildHeight),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          mildRect,
          Paint()..color = Colors.orangeAccent,
        );
        currentY -= mildHeight;
      }

      // Relax (top)
      if (relax > 0) {
        final relaxHeight = (relax / maxValue) * size.height;
        final relaxRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, currentY - relaxHeight, barActualWidth, relaxHeight),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          relaxRect,
          Paint()..color = Colors.greenAccent,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}