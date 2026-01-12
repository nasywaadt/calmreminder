// lib/pages/user/my_progress_page.dart

import 'package:calmreminder/services/time_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'user_dashboard.dart';

class MyProgressPage extends StatefulWidget {
  final DataHistory dataHistory;

  const MyProgressPage({super.key, required this.dataHistory});

  @override
  State<MyProgressPage> createState() => _MyProgressPageState();
}

class _MyProgressPageState extends State<MyProgressPage> {
  String _selectedPeriod = 'Week';
  String? _currentTime;
  bool _isLoadingTime = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentTime();
  }

  Future<void> _fetchCurrentTime() async {
    final time = await TimeService.getCurrentTime();
    setState(() {
      _currentTime = time != null 
          ? DateFormat('EEEE, d MMMM yyyy HH:mm').format(time)
          : DateFormat('EEEE, d MMMM yyyy HH:mm').format(DateTime.now());
      _isLoadingTime = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stressHistory = widget.dataHistory.stressHistory;
    final heartRateHistory = widget.dataHistory.heartRateHistory;
    final timestamps = widget.dataHistory.timestamps;

    // Calculate statistics
    int relaxCount = stressHistory.where((s) => s == 'Relax').length;
    int mildCount = stressHistory.where((s) => s == 'Mild Stress').length;
    int highCount = stressHistory.where((s) => s == 'High Stress').length;
    int total = stressHistory.length;

    double avgHeartRate = heartRateHistory.isEmpty 
        ? 0 
        : heartRateHistory.reduce((a, b) => a + b) / heartRateHistory.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF60A5FA),
              Color(0xFF3B82F6),
              Color(0xFF2563EB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'My Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time Display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _isLoadingTime
                                    ? const Text(
                                        'Loading time...',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      )
                                    : Text(
                                        _currentTime ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Period Selector
                        Row(
                          children: ['Day', 'Week', 'Month'].map((period) {
                            final isSelected = _selectedPeriod == period;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedPeriod = period);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    period,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 30),

                        // Statistics Cards
                        const Text(
                          'Overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Records',
                                '$total',
                                Icons.analytics,
                                Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Avg Heart Rate',
                                '${avgHeartRate.toStringAsFixed(0)} BPM',
                                Icons.favorite,
                                Colors.redAccent,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Stress Distribution
                        const Text(
                          'Stress Level Distribution',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (total == 0)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'No data available yet',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              _buildStressBar(
                                'Relax',
                                relaxCount,
                                total,
                                Colors.greenAccent,
                              ),
                              const SizedBox(height: 12),
                              _buildStressBar(
                                'Mild Stress',
                                mildCount,
                                total,
                                Colors.orangeAccent,
                              ),
                              const SizedBox(height: 12),
                              _buildStressBar(
                                'High Stress',
                                highCount,
                                total,
                                Colors.redAccent,
                              ),
                            ],
                          ),

                        const SizedBox(height: 30),

                        // Heart Rate Trend
                        const Text(
                          'Heart Rate Trend',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: heartRateHistory.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No heart rate data',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : CustomPaint(
                                  size: const Size(double.infinity, double.infinity),
                                  painter: ProgressChartPainter(
                                    dataPoints: heartRateHistory,
                                    color: Colors.redAccent,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 30),

                        // Insights
                        _buildInsightCard(
                          stressHistory,
                          heartRateHistory,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
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
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressBar(String label, int count, int total, Color color) {
    double percentage = total > 0 ? (count / total) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              '$count times (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(List<String> stressHistory, List<double> heartRateHistory) {
    String insight = '';
    String emoji = '💡';

    if (stressHistory.isEmpty) {
      insight = 'Start tracking your stress levels to get personalized insights.';
    } else {
      int relaxCount = stressHistory.where((s) => s == 'Relax').length;
      double relaxPercentage = (relaxCount / stressHistory.length) * 100;

      if (relaxPercentage >= 70) {
        emoji = '🎉';
        insight = 'Excellent! You\'ve been relaxed ${relaxPercentage.toStringAsFixed(0)}% of the time. Keep up the great work!';
      } else if (relaxPercentage >= 40) {
        emoji = '👍';
        insight = 'Good progress! Try to incorporate more relaxation techniques into your daily routine.';
      } else {
        emoji = '💪';
        insight = 'Your stress levels are elevated. Consider using our relaxation guides and taking regular breaks.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              const Text(
                'Insight',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight,
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
}

class ProgressChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  ProgressChartPainter({required this.dataPoints, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final normalizedRange = range > 0 ? range : 1.0;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Area under curve
    final areaPath = Path();
    final areaPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Line
    final linePath = Path();
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = size.width * (i / (dataPoints.length - 1));
      final normalizedValue = (dataPoints[i] - minValue) / normalizedRange;
      final y = size.height - (size.height * normalizedValue * 0.8) - (size.height * 0.1);

      if (i == 0) {
        linePath.moveTo(x, y);
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, linePaint);

    // Data points
    for (int i = 0; i < dataPoints.length; i++) {
      final x = size.width * (i / (dataPoints.length - 1));
      final normalizedValue = (dataPoints[i] - minValue) / normalizedRange;
      final y = size.height - (size.height * normalizedValue * 0.8) - (size.height * 0.1);

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ProgressChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}