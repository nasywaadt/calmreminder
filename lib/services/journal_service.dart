// lib/core/services/journal_service.dart

import 'dart:convert';
import 'package:calmreminder/core/models/journal_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalService {
  static const String _key = 'journal_entries';

  static Future<List<JournalEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => JournalEntry.fromJson(json)).toList();
  }

  static Future<void> saveEntry(JournalEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getEntries();
    entries.insert(0, entry); // Insert at beginning
    
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  static Future<void> deleteEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getEntries();
    entries.removeWhere((entry) => entry.id == id);
    
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }
}