import 'exercises.dart';
import 'foods.dart';

class ParsedItem {
  final String text;
  final Food? food;
  final Exercise? exercise;
  final double qty;
  final int minutes;
  final int? steps;

  const ParsedItem(
    this.text, {
    this.food,
    this.exercise,
    this.qty = 1,
    this.minutes = 0,
    this.steps,
  });

  bool get found => food != null || exercise != null || steps != null;
}

/// Turns free text like "2 roti, 1 bowl dal, banana, walked 30 min, gym 1 hour"
/// into food, exercise and step entries. Works offline.
class Parser {
  static const _stop = {
    'i', 'ate', 'had', 'have', 'eaten', 'drank', 'did', 'today', 'for',
    'breakfast', 'lunch', 'dinner', 'snack', 'snacks', 'of', 'the', 'some',
    'my', 'in', 'morning', 'evening', 'night', 'went', 'to', 'played', 'done',
    'took', 'around', 'about', 'also', 'was', 'were', 'plus',
  };

  static const _units = {
    'cup', 'cups', 'bowl', 'bowls', 'plate', 'plates', 'glass', 'glasses',
    'piece', 'pieces', 'pcs', 'pc', 'slice', 'slices', 'spoon', 'spoons',
    'tbsp', 'tsp', 'katori', 'scoop', 'scoops', 'can', 'cans', 'bottle',
    'handful', 'serving', 'servings', 'medium', 'large', 'small',
  };

  static const _numWords = {
    'a': 1.0,
    'an': 1.0,
    'one': 1.0,
    'two': 2.0,
    'three': 3.0,
    'four': 4.0,
    'five': 5.0,
    'six': 6.0,
    'half': 0.5,
  };

  static List<ParsedItem> parse(String input) {
    final cleaned = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s./,;+&]', unicode: true), ' ');
    final parts = cleaned.split(RegExp(r'[,;\n+&]+|\band\b|\bthen\b'));
    final out = <ParsedItem>[];
    for (final raw in parts) {
      final tokens = raw
          .trim()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty && !_stop.contains(t))
          .toList();
      if (tokens.isEmpty) continue;
      out.add(_one(tokens.join(' ')));
    }
    return out;
  }

  static ParsedItem _one(String text) {
    // 1) steps, e.g. "6000 steps"
    final sm = RegExp(r'(\d[\d,]*)\s*steps?').firstMatch(text);
    if (sm != null) {
      return ParsedItem(text,
          steps: int.parse(sm.group(1)!.replaceAll(',', '')));
    }

    // 2) exercise
    final ex = _matchExercise(text);
    if (ex != null) {
      int minutes = 0;
      final dm = RegExp(
              r'(\d+(?:\.\d+)?)\s*(hours?|hrs?|h|minutes?|mins?|m)\b')
          .firstMatch(text);
      if (dm != null) {
        final v = double.parse(dm.group(1)!);
        final u = dm.group(2)!;
        minutes = (u.startsWith('h') ? v * 60 : v).round();
      } else {
        final km = RegExp(
                r'(\d+(?:\.\d+)?)\s*(km|kms|kilometers?|kilometres?)')
            .firstMatch(text);
        if (km != null && ex.kmh > 0) {
          minutes = (double.parse(km.group(1)!) / ex.kmh * 60).round();
        }
      }
      if (minutes <= 0) minutes = 30;
      return ParsedItem(text, exercise: ex, minutes: minutes);
    }

    // 3) food, with optional leading quantity
    var tokens = text.split(' ');
    double qty = 1;
    if (tokens.isNotEmpty) {
      final first = tokens.first;
      final frac = RegExp(r'^(\d+)/(\d+)$').firstMatch(first);
      final num = RegExp(r'^(\d+(?:\.\d+)?)x?$').firstMatch(first);
      if (frac != null) {
        final d = int.parse(frac.group(2)!);
        qty = d == 0 ? 1 : int.parse(frac.group(1)!) / d;
        tokens = tokens.sublist(1);
      } else if (num != null) {
        qty = double.parse(num.group(1)!);
        tokens = tokens.sublist(1);
      } else if (_numWords.containsKey(first)) {
        qty = _numWords[first]!;
        tokens = tokens.sublist(1);
      }
    }
    if (qty <= 0 || qty > 20) qty = 1;
    final name = tokens.where((t) => !_units.contains(t)).join(' ').trim();
    if (name.isEmpty) return ParsedItem(text);
    final food = _matchFood(name);
    if (food == null) return ParsedItem(text);
    return ParsedItem(text, food: food, qty: qty);
  }

  static Exercise? _matchExercise(String text) {
    Exercise? best;
    int bestLen = 0;
    for (final e in exercises) {
      for (final a in [e.name.toLowerCase(), ...e.aliases]) {
        if (RegExp('\\b${RegExp.escape(a)}\\b').hasMatch(text) &&
            a.length > bestLen) {
          best = e;
          bestLen = a.length;
        }
      }
    }
    return best;
  }

  static Food? _matchFood(String text) {
    final singular = text
        .split(' ')
        .map((w) => (w.length > 3 && w.endsWith('s'))
            ? w.substring(0, w.length - 1)
            : w)
        .join(' ');
    final variants = {text, singular};
    Food? best;
    int bestScore = 0;
    for (final f in foods) {
      for (final a in f.keys) {
        for (final v in variants) {
          if (RegExp('\\b${RegExp.escape(a)}\\b').hasMatch(v)) {
            final score = a.length * 2 + (f.slots.isEmpty ? 1 : 0);
            if (score > bestScore) {
              best = f;
              bestScore = score;
            }
          }
        }
      }
    }
    return best;
  }
}
