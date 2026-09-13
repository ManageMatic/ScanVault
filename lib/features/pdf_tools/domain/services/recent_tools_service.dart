import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentToolUsage {
  final String toolId;
  final DateTime lastUsed;
  final int count;

  const RecentToolUsage({
    required this.toolId,
    required this.lastUsed,
    this.count = 1,
  });

  Map<String, dynamic> toJson() => {
        'toolId': toolId,
        'lastUsed': lastUsed.toIso8601String(),
        'count': count,
      };

  factory RecentToolUsage.fromJson(Map<String, dynamic> json) => RecentToolUsage(
        toolId: json['toolId'] as String,
        lastUsed: DateTime.parse(json['lastUsed'] as String),
        count: (json['count'] as num?)?.toInt() ?? 1,
      );
}

class RecentToolsService {
  static const String _storageKey = 'scanvault_recent_pdf_tools_v1';

  Future<List<RecentToolUsage>> getRecentTools({int limit = 5}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        return _defaultRecentTools();
      }

      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final usages = list
          .map((item) => RecentToolUsage.fromJson(item as Map<String, dynamic>))
          .toList();

      usages.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return usages.take(limit).toList();
    } catch (_) {
      return _defaultRecentTools();
    }
  }

  Future<void> recordToolUsage(String toolId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      final usages = <RecentToolUsage>[];

      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        usages.addAll(
          list.map((item) => RecentToolUsage.fromJson(item as Map<String, dynamic>)),
        );
      }

      final existingIndex = usages.indexWhere((u) => u.toolId == toolId);
      if (existingIndex >= 0) {
        final existing = usages[existingIndex];
        usages[existingIndex] = RecentToolUsage(
          toolId: toolId,
          lastUsed: DateTime.now(),
          count: existing.count + 1,
        );
      } else {
        usages.add(RecentToolUsage(
          toolId: toolId,
          lastUsed: DateTime.now(),
          count: 1,
        ));
      }

      usages.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      final trimmed = usages.take(10).toList();
      await prefs.setString(
        _storageKey,
        jsonEncode(trimmed.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> clearRecentTools() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  List<RecentToolUsage> _defaultRecentTools() {
    return [
      RecentToolUsage(
        toolId: 'merge',
        lastUsed: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RecentToolUsage(
        toolId: 'compress',
        lastUsed: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      RecentToolUsage(
        toolId: 'imagesToPdf',
        lastUsed: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }
}
