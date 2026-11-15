import 'dart:math';

import 'medical.dart';
import 'models.dart';

class Targets {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int waterMl;
  final int stepGoal;
  final double bmi;
  final bool bmiValid;
  final Goal goal;
  final List<String> noteKeys;

  const Targets({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.waterMl,
    required this.stepGoal,
    required this.bmi,
    required this.bmiValid,
    required this.goal,
    required this.noteKeys,
  });

  String get bmiKey {
    if (bmi < 18.5) return 'b_under';
    if (bmi < 25) return 'b_ok';
    if (bmi < 30) return 'b_over';
    return 'b_obese';
  }
}

class Calculator {
  /// Adults: Mifflin-St Jeor. Under 18: Schofield (WHO) equations.
  /// Under 18s never get a calorie deficit. Medical flags remove deficits too.
  static Targets compute(UserProfile p) {
    final male = p.sex == Sex.male;
    final w = p.weightKg;
    final h = p.heightCm;
    final minor = p.isMinor;

    double bmr;
    if (!minor) {
      bmr = 10 * w + 6.25 * h - 5 * p.age + (male ? 5 : -161);
    } else if (p.age >= 10) {
      bmr = male ? 17.5 * w + 651 : 12.2 * w + 746;
    } else {
      bmr = male ? 22.7 * w + 495 : 22.5 * w + 499;
    }
    final tdee = bmr * p.activity.factor;

    final notes = <String>[];
    var goal = p.goal;
    if (minor) {
      goal = Goal.grow;
      notes.add('minor_info');
    } else if (goal == Goal.grow) {
      goal = Goal.maintain;
    }

    if (!minor && Medical.locked(p)) {
      final ed = p.conditions.contains('ed');
      if (goal == Goal.lose || (ed && goal == Goal.gain)) goal = Goal.maintain;
      notes.add(ed ? 'n_ed' : 'h_warn');
    }

    double cal = switch (goal) {
      Goal.lose => tdee - 500,
      Goal.gain => tdee + 300,
      _ => tdee,
    };

    if (goal == Goal.lose) {
      if (cal < tdee * 0.80) cal = tdee * 0.80; // never cut more than 20%
      final floor = male ? 1500.0 : 1200.0;
      if (cal < floor) {
        cal = floor;
        notes.add('n_floor');
      }
    }

    double proteinG;
    if (minor) {
      proteinG = w * 1.0;
    } else if (goal == Goal.lose || goal == Goal.gain) {
      proteinG = w * 1.8;
    } else {
      proteinG = w * 1.4;
    }
    if (p.conditions.contains('kidney')) proteinG = w * 0.8;

    final fatCal = cal * (minor ? 0.30 : 0.25);
    final carbsG = max(50.0, (cal - proteinG * 4 - fatCal) / 4);
    final hm = h / 100;

    double water = minor ? min(2500.0, max(1000.0, w * 40)) : w * 35;
    water = (water / 50).round() * 50.0;

    return Targets(
      calories: cal.round(),
      protein: proteinG.round(),
      carbs: carbsG.round(),
      fat: (fatCal / 9).round(),
      waterMl: water.round(),
      stepGoal: minor ? 10000 : (goal == Goal.lose ? 10000 : 8000),
      bmi: w / (hm * hm),
      bmiValid: !minor,
      goal: goal,
      noteKeys: notes,
    );
  }

  /// Net walking cost is roughly 0.5 kcal per kg per km.
  static int stepKcal(int steps, double heightCm, double weightKg) {
    final strideM = heightCm * 0.415 / 100;
    final km = steps * strideM / 1000;
    return (0.5 * weightKg * km).round();
  }

  /// Calories burned from logged workouts and steps. Walking-type workouts
  /// and steps overlap, so only the larger of the two is counted.
  static int burned(UserProfile p, DayLog log) {
    final stepK = stepKcal(log.steps, p.heightCm, p.weightKg);
    final walkK =
        log.exercises.where((e) => e.walk).fold<int>(0, (s, e) => s + e.kcal);
    final other =
        log.exercises.where((e) => !e.walk).fold<int>(0, (s, e) => s + e.kcal);
    return other + max(stepK, walkK);
  }

  /// Calorie budget for the day. Half of burned calories are added back for
  /// adults, because activity level is already part of the base target.
  /// Under 18s and people with an eating-disorder history get no add-back.
  static int budget(UserProfile p, Targets t, DayLog log) {
    if (p.isMinor || Medical.hideNumbers(p)) return t.calories;
    return t.calories + (burned(p, log) * 0.5).round();
  }
}
