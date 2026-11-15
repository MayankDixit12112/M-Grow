import 'package:flutter/material.dart';

import 'l10n.dart';
import 'medical.dart';
import 'models.dart';

class Topic {
  final String id;
  final IconData icon;
  final List<String> words;

  const Topic(this.id, this.icon, this.words);

  String get chipKey => 'oc_t_$id';
  String get answerKey => 'oc_a_$id';
}

const topics = <Topic>[
  Topic('water', Icons.water_drop,
      ['water', 'hydrate', 'hydration', 'thirst', 'पानी', 'पीना']),
  Topic('sleep', Icons.bedtime,
      ['sleep', 'insomnia', 'bedtime', 'tired', 'नींद', 'सोना']),
  Topic('protein', Icons.egg_alt, ['protein', 'प्रोटीन']),
  Topic('weight', Icons.monitor_weight, [
    'weight', 'lose', 'fat', 'slim', 'obese', 'belly', 'diet',
    'वजन', 'वज़न', 'चर्बी', 'मोटा', 'मोटापा',
  ]),
  Topic('muscle', Icons.fitness_center, [
    'muscle', 'bulk', 'strength', 'gym', 'weight gain', 'gain weight',
    'मांसपेशी', 'बॉडी',
  ]),
  Topic('steps', Icons.directions_walk,
      ['step', 'walk', 'walking', 'कदम', 'चलना']),
  Topic('stress', Icons.self_improvement,
      ['stress', 'anxiety', 'anxious', 'worry', 'sad', 'mood', 'तनाव', 'चिंता']),
  Topic('height', Icons.height,
      ['height', 'tall', 'taller', 'grow', 'growth', 'लंबाई', 'कद']),
  Topic('breakfast', Icons.free_breakfast,
      ['breakfast', 'morning meal', 'नाश्ता']),
  Topic('sugar', Icons.cake,
      ['sugar', 'sweet', 'junk', 'soda', 'cola', 'चीनी', 'मीठा']),
  Topic('exercise', Icons.directions_run,
      ['exercise', 'workout', 'routine', 'yoga', 'cardio', 'व्यायाम', 'कसरत']),
  Topic('fasting', Icons.no_food, [
    'fast', 'fasting', 'intermittent', 'skip meal', 'starve', 'उपवास', 'व्रत',
  ]),
];

/// Quick, safe tips that work with no internet.
class OfflineCoach {
  static Topic? topicFor(String text) {
    final t = text.toLowerCase();
    Topic? best;
    int bestScore = 0;
    for (final topic in topics) {
      int score = 0;
      for (final w in topic.words) {
        final ascii = w.codeUnits.every((c) => c < 128);
        final hit = ascii
            ? RegExp('\\b${RegExp.escape(w)}\\w*').hasMatch(t)
            : t.contains(w);
        if (hit) score += w.contains(' ') ? 3 : 1;
      }
      if (score > bestScore) {
        best = topic;
        bestScore = score;
      }
    }
    return best;
  }

  static String answerFor(Topic t, UserProfile p) {
    if (p.conditions.contains('ed') &&
        const {'weight', 'fasting', 'sugar'}.contains(t.id)) {
      return tr('n_ed');
    }
    if (t.id == 'weight' && p.isMinor) return tr('oc_a_weight_minor');
    return tr(t.answerKey);
  }

  static String reply(String text, UserProfile p) {
    final t = topicFor(text);
    return t == null ? tr('oc_none') : answerFor(t, p);
  }

  static bool sensitive(String text, UserProfile p) {
    if (!Medical.hideNumbers(p)) return false;
    final t = topicFor(text);
    return t != null && const {'weight', 'fasting', 'sugar'}.contains(t.id);
  }
}
