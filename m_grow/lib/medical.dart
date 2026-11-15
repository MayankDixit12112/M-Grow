import 'models.dart';

/// Conservative rules for allergies and medical conditions.
/// These make the app safer; they are NOT medical advice.
class Medical {
  static const allergens = [
    'peanut',
    'treenut',
    'milk',
    'egg',
    'gluten',
    'soy',
    'fish',
    'shellfish',
    'sesame',
  ];

  /// 'ed' = history of an eating disorder.
  static const conditions = [
    'diabetes',
    'hypertension',
    'thyroid',
    'pcos',
    'heart',
    'kidney',
    'asthma',
    'pregnancy',
    'celiac',
    'lactose',
    'anemia',
    'ed',
  ];

  /// For these, the app never sets weight-loss targets on its own.
  static const _lock = {'pregnancy', 'kidney', 'ed', 'diabetes', 'heart'};

  static bool locked(UserProfile p) => p.conditions.any(_lock.contains);

  /// With an eating-disorder history the app hides calorie and weight numbers.
  static bool hideNumbers(UserProfile p) => p.conditions.contains('ed');

  /// Allergens to filter out (declared allergies plus implied ones).
  static Set<String> avoid(UserProfile p) {
    final s = p.allergies.toSet();
    if (p.conditions.contains('celiac')) s.add('gluten');
    if (p.conditions.contains('lactose')) s.add('milk');
    return s;
  }
}
