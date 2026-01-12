import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMessage {
  final String id;
  final String userId;
  final String title;
  final String subtitle;
  final String message;
  final String emoji;
  final List<String> tips;
  final String stressLevel;
  final DateTime timestamp;
  final bool isRead;

  AdminMessage({
    required this.id,
    required this.userId,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.emoji,
    required this.tips,
    required this.stressLevel,
    required this.timestamp,
    this.isRead = false,
  });

  factory AdminMessage.fromJson(Map<String, dynamic> json, String id) {
    DateTime parsedTime;
    if (json['timestamp'] is Timestamp) {
      parsedTime = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      parsedTime = DateTime.parse(json['timestamp']);
    } else {
      parsedTime = DateTime.now();
    }

    return AdminMessage(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? 'Relaxation Guide',
      subtitle: json['subtitle'] ?? 'Saran dari Admin',
      message: json['message'] ?? '',
      emoji: json['emoji'] ?? '🌟',
      tips: List<String>.from(json['tips'] ?? []),
      stressLevel: json['stressLevel'] ?? 'Relax',
      timestamp: parsedTime,
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'title': title,
    'subtitle': subtitle,
    'message': message,
    'emoji': emoji,
    'tips': tips,
    'stressLevel': stressLevel,
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
  };
}