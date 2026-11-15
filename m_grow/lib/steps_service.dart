import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'storage.dart';

/// Counts steps with the phone's step sensor. If the sensor or permission is
/// not available, people can enter steps by hand.
class StepsService {
  static StreamSubscription<StepCount>? _sub;
  static final ValueNotifier<bool> running = ValueNotifier(false);

  static Future<bool> start() async {
    try {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) return false;
      await _sub?.cancel();
      _sub = Pedometer.stepCountStream.listen(_onStep, onError: (_) {});
      running.value = true;
      await Storage.setBool('steps_auto', true);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    running.value = false;
    await Storage.setBool('steps_auto', false);
  }

  /// Call at app start: resume counting if the person turned it on before.
  static Future<void> resumeIfEnabled() async {
    if (Storage.getBool('steps_auto')) {
      try {
        if (await Permission.activityRecognition.isGranted) {
          await start();
        }
      } catch (_) {}
    }
  }

  static Future<void> _onStep(StepCount e) async {
    final raw = e.steps; // steps since the phone last booted
    final key = Storage.todayKey();
    final last = Storage.getInt('steps_last');
    var base = Storage.getInt('steps_base_$key');
    if (base == null) {
      base = (last != null && raw >= last) ? last : 0;
      await Storage.setInt('steps_base_$key', base);
    } else if (raw < base) {
      base = 0; // phone rebooted during the day
      await Storage.setInt('steps_base_$key', 0);
    }
    await Storage.setInt('steps_last', raw);

    final log = Storage.loadLog(key);
    log.steps = raw - base;
    await Storage.saveLog(key, log);
  }
}
