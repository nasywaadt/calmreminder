// lib/core/models/journal_entry.dart

class JournalEntry {
  final String id;
  final String mood;
  final String note;
  final DateTime timestamp;
  final String stressLevel;

  JournalEntry({
    required this.id,
    required this.mood,
    required this.note,
    required this.timestamp,
    required this.stressLevel,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'mood': mood,
    'note': note,
    'timestamp': timestamp.toIso8601String(),
    'stressLevel': stressLevel,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'],
    mood: json['mood'],
    note: json['note'],
    timestamp: DateTime.parse(json['timestamp']),
    stressLevel: json['stressLevel'],
  );
}