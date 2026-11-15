import 'package:flutter/material.dart';

import 'calculator.dart';
import 'l10n.dart';
import 'medical.dart';
import 'models.dart';

class CoachTask {
  final IconData icon;
  final String text;

  const CoachTask(this.icon, this.text);
}

/// Builds today's to-do list from what the person has logged so far.
class Coach {
  static List<CoachTask> tasks(UserProfile p, Targets t, DayLog log) {
    final out = <CoachTask>[];
    final hide = Medical.hideNumbers(p);

    if (log.foods.isEmpty) {
      out.add(CoachTask(Icons.edit_note, tr('task_log')));
    } else if (!hide) {
      final left = Calculator.budget(p, t, log) - log.kcal;
      if (left > 200) {
        out.add(CoachTask(Icons.restaurant, tr('task_cal_left', {'n': left})));
      } else if (left < -150 && t.goal == Goal.lose) {
        out.add(CoachTask(Icons.info_outline, tr('task_cal_over', {'n': -left})));
      }
      final gap = t.protein - log.protein;
      if (gap > t.protein * 0.2) {
        out.add(CoachTask(Icons.egg_alt, tr('task_protein', {'n': gap})));
      }
    }

    final glasses = ((t.waterMl - log.waterMl) / 250).ceil();
    if (glasses > 0) {
      out.add(CoachTask(Icons.water_drop, tr('task_water', {'n': glasses})));
    }

    final stepGap = t.stepGoal - log.steps;
    if (stepGap > 500) {
      final n = (stepGap / 100).round() * 100;
      out.add(CoachTask(Icons.directions_walk, tr('task_steps', {'n': n})));
    }

    final minsGoal = p.isMinor ? 60 : 30;
    if (log.exerciseMinutes < minsGoal) {
      out.add(CoachTask(Icons.fitness_center,
          tr('task_move', {'n': minsGoal - log.exerciseMinutes})));
    }

    out.add(CoachTask(Icons.bedtime, tr('task_sleep')));
    return out;
  }
}
