import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// All data stays on the device. No account, no server.
class Storage {
  static late SharedPreferences _p;

  /// Bumped whenever a day log changes, so screens can refresh.
  static final ValueNotifier<int> tick = ValueNotifier(0);

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  static String todayKey() => DateTime.now().toIso8601String().substring(0, 10);

  // ---------- language ----------
  static String? language() => _p.getString('lang');
  static Future<void> setLanguage(String code) => _p.setString('lang', code);

  // ---------- small helpers ----------
  static int? getInt(String k) => _p.getInt(k);
  static Future<void> setInt(String k, int v) => _p.setInt(k, v);
  static bool getBool(String k) => _p.getBool(k) ?? false;
  static Future<void> setBool(String k, bool v) => _p.setBool(k, v);

  // ---------- profile ----------
  static UserProfile? loadProfile() {
    final s = _p.getString('profile');
    if (s == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProfile(UserProfile p) =>
      _p.setString('profile', jsonEncode(p.toJson()));

  // ---------- weight ----------
  static List<WeightEntry> loadWeights() {
    final s = _p.getString('weights');
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List)
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addWeight(double kg) async {
    final list = loadWeights();
    final today = todayKey();
    list.removeWhere((e) => e.date == today);
    list.add(WeightEntry(today, kg));
    list.sort((a, b) => a.date.compareTo(b.date));
    await _p.setString(
        'weights', jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // ---------- daily logs ----------
  static DayLog loadLog(String key) {
    final s = _p.getString('log_$key');
    if (s == null) return DayLog();
    try {
      return DayLog.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return DayLog();
    }
  }

  static Future<void> saveLog(String key, DayLog log) async {
    await _p.setString('log_$key', jsonEncode(log.toJson()));
    tick.value++;
  }

  /// Consecutive days (ending today or yesterday) with at least one food logged.
  static int streak() {
    int n = 0;
    for (int i = 0; i < 400; i++) {
      final d = DateTime.now()
          .subtract(Duration(days: i))
          .toIso8601String()
          .substring(0, 10);
      final has = loadLog(d).foods.isNotEmpty;
      if (has) {
        n++;
      } else if (i == 0) {
        continue;
      } else {
        break;
      }
    }
    return n;
  }

  // ---------- delete everything ----------
  static Future<void> deleteAll() async {
    await _p.clear();
    tick.value++;
  }
}
