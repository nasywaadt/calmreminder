// lib/core/services/time_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class TimeService {
  // Menggunakan WorldTimeAPI (gratis, tanpa API key)
  static Future<DateTime?> getCurrentTime() async {
    try {
      final response = await http.get(
        Uri.parse('https://worldtimeapi.org/api/timezone/Asia/Jakarta'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DateTime.parse(data['datetime']);
      }
    } catch (e) {
      print('Error fetching time: $e');
    }
    
    // Fallback ke waktu lokal jika API gagal
    return DateTime.now();
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }
}