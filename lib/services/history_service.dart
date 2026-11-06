import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a past file transfer session.
class TransferRecord {
  const TransferRecord({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    required this.direction, // 'sent' or 'received'
    required this.timestamp,
    required this.durationSeconds,
    required this.averageBytesPerSecond,
    required this.sha256Verified,
    this.localPath,
  });

  final String id;
  final String fileName;
  final int fileSizeBytes;
  final String direction;
  final DateTime timestamp;
  final int durationSeconds;
  final double averageBytesPerSecond;
  final bool sha256Verified;
  final String? localPath;

  bool get isSent => direction == 'sent';
  bool get isReceived => direction == 'received';

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'direction': direction,
        'timestamp': timestamp.toIso8601String(),
        'durationSeconds': durationSeconds,
        'averageBytesPerSecond': averageBytesPerSecond,
        'sha256Verified': sha256Verified,
        if (localPath != null) 'localPath': localPath,
      };

  factory TransferRecord.fromJson(Map<String, dynamic> json) {
    return TransferRecord(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int,
      direction: json['direction'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      durationSeconds: json['durationSeconds'] as int,
      averageBytesPerSecond: (json['averageBytesPerSecond'] as num).toDouble(),
      sha256Verified: json['sha256Verified'] as bool,
      localPath: json['localPath'] as String?,
    );
  }
}

/// Service that persists and manages transfer history.
class HistoryService extends ChangeNotifier {
  HistoryService._();
  static final HistoryService instance = HistoryService._();

  static const _keyHistory = 'qrbeam_transfer_history_json';
  final List<TransferRecord> _records = [];

  List<TransferRecord> get records => List.unmodifiable(_records);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyHistory);
    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        _records.clear();
        for (final item in list) {
          _records.add(TransferRecord.fromJson(item as Map<String, dynamic>));
        }
        _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> addRecord(TransferRecord record) async {
    _records.insert(0, record);
    notifyListeners();
    await _save();
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> clearHistory() async {
    _records.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _records.map((r) => r.toJson()).toList();
    await prefs.setString(_keyHistory, jsonEncode(jsonList));
  }
}
