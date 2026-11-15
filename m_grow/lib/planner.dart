import 'package:flutter/material.dart';

import 'calculator.dart';
import 'foods.dart';
import 'l10n.dart';
import 'medical.dart';
import 'models.dart';

class PlannedMeal {
  final String slot; // B, L, S, D
  final String time;
  final Food food;
  final double servings;

  const PlannedMeal(this.slot, this.time, this.food, this.servings);

  String get slotKey => switch (slot) {
        'B' => 'sl_break',
        'L' => 'sl_lunch',
        'S' => 'sl_snack',
        _ => 'sl_dinner',
      };

  int get calories => (food.cal * servings).round();
  int get protein => (food.protein * servings).round();
  int get carbs => (food.carbs * servings).round();
  int get fat => (food.fat * servings).round();

  String get servingLabel {
    if (servings == 1) return food.serving;
    final s = servings == servings.roundToDouble()
        ? servings.toInt().toString()
        : servings.toString();
    return '$s x ${food.serving}';
  }
}

class MealPlanner {
  static const _slots = ['B', 'L', 'S', 'D'];
  static const _share = {'B': 0.25, 'L': 0.35, 'S': 0.10, 'D': 0.30};
  static const _time = {
    'B': '8:30 AM',
    'L': '1:30 PM',
    'S': '5:00 PM',
    'D': '8:00 PM',
  };

  /// 7 days (Mon..Sun), 4 meals each, sized to the calorie target and filtered
  /// by diet and allergies. Meals with a declared allergen are never used.
  static List<List<PlannedMeal>> week(UserProfile p, Targets t) {
    final level = p.diet.index;
    final avoid = Medical.avoid(p);
    return List.generate(7, (day) {
      return List.generate(_slots.length, (i) {
        final slot = _slots[i];
        final pool = foods
            .where((f) =>
                f.slots.contains(slot) &&
                f.level <= level &&
                !f.allergens.any(avoid.contains))
            .toList();
        final food = pool.isEmpty ? fallbackFood : pool[(day + i) % pool.length];
        final raw = (t.calories * _share[slot]!) / food.cal;
        final servings = (raw.clamp(0.5, 2.0) * 4).round() / 4;
        return PlannedMeal(slot, _time[slot]!, food, servings);
      });
    });
  }
}

class TimeSlot {
  final String time;
  final String title;
  final String detail;
  final IconData icon;

  const TimeSlot(this.time, this.title, this.detail, this.icon);
}

class Timetable {
  static const _adult = [
    'wk_strength', 'wk_cardio', 'wk_strength', 'wk_yoga', 'wk_full',
    'wk_fun', 'wk_rest',
  ];
  static const _kid = [
    'wk_play', 'wk_fun', 'wk_play', 'wk_yoga', 'wk_play', 'wk_fun', 'wk_rest',
  ];

  static List<TimeSlot> day(
      int dayIdx, UserProfile p, Targets t, List<PlannedMeal> meals) {
    final wk = (p.isMinor ? _kid : _adult)[dayIdx];
    final liters = (t.waterMl / 1000).toStringAsFixed(1);
    return [
      TimeSlot('6:30 AM', tr('sl_wake'), tr('sl_wake_d'), Icons.wb_sunny),
      TimeSlot('7:00 AM', tr(wk), '', Icons.fitness_center),
      TimeSlot('8:30 AM', tr('sl_break'), meals[0].food.name, Icons.free_breakfast),
      TimeSlot('11:00 AM', tr('sl_water'), tr('sl_water_d', {'n': liters}), Icons.water_drop),
      TimeSlot('1:30 PM', tr('sl_lunch'), meals[1].food.name, Icons.lunch_dining),
      TimeSlot('5:00 PM', tr('sl_snack'), meals[2].food.name, Icons.apple),
      TimeSlot('8:00 PM', tr('sl_dinner'), meals[3].food.name, Icons.dinner_dining),
      TimeSlot(p.isMinor ? '9:30 PM' : '10:30 PM', tr('sl_sleep'),
          tr('sl_sleep_d'), Icons.bedtime),
    ];
  }
}
