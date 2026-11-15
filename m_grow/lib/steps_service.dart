import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'storage.dart';

/// Counts steps with the phone's step sensor, by itself.
/// The sensor counts all day even when the app is closed; the total is
/// brought up to date each time the app opens.
class StepsService {
  static StreamSubscription<StepCount>? _sub;
  static final ValueNotifier<bool> running = ValueNotifier(false);

  /// off | on | denied | blocked | unsupported
  static final ValueNotifier<String> status = ValueNotifier('off');

  /// Starts counting. Asks for the Physical activity permission if needed.
  static Future<bool> start() async {
    try {
      var st = await Permission.activityRecognition.status;
      if (!st.isGranted) st = await Permission.activityRecognition.request();
      if (!st.isGranted) {
        running.value = false;
        status.value = st.isPermanentlyDenied ? 'blocked' : 'denied';
        return false;
      }
      await _sub?.cancel();
      _sub = Pedometer.stepCountStream.listen(
        _onStep,
        onError: (_) {
          running.value = false;
          status.value = 'unsupported';
        },
      );
      running.value = true;
      status.value = 'on';
      await Storage.setBool('steps_off', false);
      return true;
    } catch (_) {
      running.value = false;
      status.value = 'unsupported';
      return false;
    }
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    running.value = false;
    status.value = 'off';
    await Storage.setBool('steps_off', true);
  }

  /// Called when the home screen opens. Counting is on unless the person
  /// switched it off themselves.
  static Future<void> autoStart() async {
    if (running.value || Storage.getBool('steps_off')) return;
    await start();
  }

  /// Set today's total by hand (also keeps the automatic counter in step).
  static Future<void> setToday(int v) async {
    final key = Storage.todayKey();
    final last = Storage.getInt('steps_last');
    if (last != null) await Storage.setInt('steps_base_$key', last - v);
    final log = Storage.loadLog(key);
    log.steps = v;
    await Storage.saveLog(key, log);
  }

  static Future<void> _onStep(StepCount e) async {
    final raw = e.steps; // steps since the phone last restarted
    final key = Storage.todayKey();
    final last = Storage.getInt('steps_last');
    var base = Storage.getInt('steps_base_$key');
    final log = Storage.loadLog(key);

    if (base == null) {
      // First reading of the day. Count from the last reading we saw. On the
      // very first run there is none, so start from now.
      base = (last != null && raw >= last) ? last : raw;
      await Storage.setInt('steps_base_$key', base);
    } else if (raw < base) {
      // The phone restarted during the day: carry on from today's total.
      base = raw - log.steps;
      await Storage.setInt('steps_base_$key', base);
    }
    await Storage.setInt('steps_last', raw);

    final n = raw - base;
    if (n >= 0 && n != log.steps) {
      log.steps = n;
      await Storage.saveLog(key, log);
    }
  }
}
