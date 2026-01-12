// lib/core/services/analytics_service.dart

import 'package:calmreminder/core/models/user_data.dart';


class AnalyticsService {
  // Calculate average BPM
  static double calculateAverageBPM(List<UserData> dataList) {
    if (dataList.isEmpty) return 0;
    final sum = dataList.fold<int>(0, (sum, data) => sum + data.heartRate);
    return sum / dataList.length;
  }

  // Calculate average BPM by time category
  static Map<String, double> calculateAverageBPMByTime(List<UserData> dataList) {
    final Map<String, List<int>> bpmByTime = {
      'Pagi': [],
      'Siang': [],
      'Malam': [],
    };

    for (var data in dataList) {
      bpmByTime[data.timeCategory]?.add(data.heartRate);
    }

    return bpmByTime.map((key, values) {
      if (values.isEmpty) return MapEntry(key, 0.0);
      final avg = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(key, avg);
    });
  }

  // Calculate stress frequency by time
  static Map<String, Map<String, int>> calculateStressFrequencyByTime(List<UserData> dataList) {
    final Map<String, Map<String, int>> frequency = {
      'Pagi': {'Relax': 0, 'Mild Stress': 0, 'High Stress': 0},
      'Siang': {'Relax': 0, 'Mild Stress': 0, 'High Stress': 0},
      'Malam': {'Relax': 0, 'Mild Stress': 0, 'High Stress': 0},
    };

    for (var data in dataList) {
      frequency[data.timeCategory]?[data.stressLevel] = 
          (frequency[data.timeCategory]?[data.stressLevel] ?? 0) + 1;
    }

    return frequency;
  }

  // Get most stressful hour
  static Map<String, dynamic> getMostStressfulHour(List<UserData> dataList) {
    final Map<int, int> stressCountByHour = {};
    
    for (var data in dataList) {
      if (data.stressLevel == 'High Stress' || data.stressLevel == 'Mild Stress') {
        final hour = data.timestamp.hour;
        stressCountByHour[hour] = (stressCountByHour[hour] ?? 0) + 1;
      }
    }

    if (stressCountByHour.isEmpty) {
      return {'hour': 0, 'count': 0};
    }

    final mostStressfulHour = stressCountByHour.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return {
      'hour': mostStressfulHour.key,
      'count': mostStressfulHour.value,
    };
  }

  // Calculate total stress time today (in minutes)
  static int calculateTotalStressTime(List<UserData> dataList) {
    int stressCount = dataList.where((data) => 
      data.stressLevel == 'High Stress' || data.stressLevel == 'Mild Stress'
    ).length;
    
    // Assuming each data point represents ~5 minutes
    return stressCount * 5;
  }

  // Get stress distribution percentage
  static Map<String, double> getStressDistribution(List<UserData> dataList) {
    if (dataList.isEmpty) {
      return {'Relax': 0, 'Mild Stress': 0, 'High Stress': 0};
    }

    final total = dataList.length;
    final relaxCount = dataList.where((d) => d.stressLevel == 'Relax').length;
    final mildCount = dataList.where((d) => d.stressLevel == 'Mild Stress').length;
    final highCount = dataList.where((d) => d.stressLevel == 'High Stress').length;

    return {
      'Relax': (relaxCount / total) * 100,
      'Mild Stress': (mildCount / total) * 100,
      'High Stress': (highCount / total) * 100,
    };
  }

  // Get hourly stress data for graph
  static List<Map<String, dynamic>> getHourlyStressData(List<UserData> dataList) {
    final Map<int, Map<String, int>> hourlyData = {};

    for (var data in dataList) {
      final hour = data.timestamp.hour;
      if (!hourlyData.containsKey(hour)) {
        hourlyData[hour] = {'Relax': 0, 'Mild Stress': 0, 'High Stress': 0};
      }
      hourlyData[hour]![data.stressLevel] = 
          (hourlyData[hour]![data.stressLevel] ?? 0) + 1;
    }

    return hourlyData.entries.map((entry) {
      return {
        'hour': entry.key,
        'relax': entry.value['Relax'] ?? 0,
        'mild': entry.value['Mild Stress'] ?? 0,
        'high': entry.value['High Stress'] ?? 0,
      };
    }).toList()..sort((a, b) => (a['hour'] as int).compareTo(b['hour'] as int));
  }

  // Compare stress between time categories
  static Map<String, String> compareStressByTime(List<UserData> dataList) {
    final frequency = calculateStressFrequencyByTime(dataList);
    
    final Map<String, int> totalStressByTime = {};
    
    for (var time in ['Pagi', 'Siang', 'Malam']) {
      totalStressByTime[time] = 
          (frequency[time]!['Mild Stress'] ?? 0) + 
          (frequency[time]!['High Stress'] ?? 0);
    }

    if (totalStressByTime.values.every((count) => count == 0)) {
      return {
        'mostStressful': 'Tidak ada data',
        'leastStressful': 'Tidak ada data',
        'insight': 'Belum ada data stress yang tercatat',
      };
    }

    final mostStressful = totalStressByTime.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final leastStressful = totalStressByTime.entries
        .reduce((a, b) => a.value < b.value ? a : b);

    String insight = '';
    if (mostStressful.key == 'Malam') {
      insight = 'User paling sering stress di malam hari. Sarankan untuk istirahat lebih awal.';
    } else if (mostStressful.key == 'Siang') {
      insight = 'User paling sering stress di siang hari. Sarankan untuk break sejenak.';
    } else {
      insight = 'User mengalami stress di pagi hari. Sarankan untuk meditasi pagi.';
    }

    return {
      'mostStressful': mostStressful.key,
      'leastStressful': leastStressful.key,
      'insight': insight,
    };
  }

  // Generate suggestion based on time and stress pattern
  static String generateSuggestion(String timeCategory, String stressLevel) {
    if (stressLevel == 'High Stress') {
      if (timeCategory == 'Malam') {
        return 'Stres tinggi terdeteksi di malam hari. Kurangi penggunaan gadget dan cobalah teknik relaksasi sebelum tidur.';
      } else if (timeCategory == 'Siang') {
        return 'Stres tinggi terdeteksi di siang hari. Luangkan waktu istirahat 10-15 menit dan minum air putih.';
      } else {
        return 'Stres tinggi terdeteksi di pagi hari. Mulai hari dengan meditasi ringan atau jalan santai.';
      }
    } else if (stressLevel == 'Mild Stress') {
      if (timeCategory == 'Malam') {
        return 'Stress ringan di malam hari. Coba dengarkan musik yang menenangkan.';
      } else if (timeCategory == 'Siang') {
        return 'Stress ringan di siang hari. Ambil break sejenak dan lakukan stretching.';
      } else {
        return 'Stress ringan di pagi hari. Atur jadwal dengan lebih baik.';
      }
    }
    
    return 'Kondisi baik. Pertahankan pola hidup sehat!';
  }

  // Get daily summary
  static Map<String, dynamic> getDailySummary(List<UserData> dataList) {
    final avgBPM = calculateAverageBPM(dataList);
    final totalStressTime = calculateTotalStressTime(dataList);
    final mostStressfulHour = getMostStressfulHour(dataList);
    final stressDistribution = getStressDistribution(dataList);
    
    return {
      'totalRecords': dataList.length,
      'averageBPM': avgBPM.toStringAsFixed(1),
      'totalStressTime': totalStressTime,
      'mostStressfulHour': mostStressfulHour['hour'],
      'stressDistribution': stressDistribution,
    };
  }
}