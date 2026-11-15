enum Sex { male, female }

/// `grow` is used automatically for everyone under 18. No weight-loss targets.
enum Goal { lose, maintain, gain, grow }

// Order matters: a higher index means a less restrictive diet.
enum Diet { vegan, vegetarian, nonVeg }

enum Activity { sedentary, light, moderate, active, veryActive }

extension SexX on Sex {
  String get key => this == Sex.male ? 'male' : 'female';
}

extension GoalX on Goal {
  String get key => const ['goal_lose', 'goal_maintain', 'goal_gain', 'goal_grow'][index];
}

extension DietX on Diet {
  String get key => const ['vegan', 'vegetarian', 'nonveg'][index];
}

extension ActivityX on Activity {
  double get factor => const [1.2, 1.375, 1.55, 1.725, 1.9][index];
  String get key => 'act$index';
}

class UserProfile {
  final String name;
  final int age;
  final Sex sex;
  final double heightCm;
  final double weightKg;
  final Activity activity;
  final Goal goal;
  final Diet diet;
  final List<String> allergies;
  final List<String> conditions;
  final String notes;
  final bool guardianOk;
  final bool shareWithCoach;

  const UserProfile({
    required this.name,
    required this.age,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
    required this.diet,
    this.allergies = const [],
    this.conditions = const [],
    this.notes = '',
    this.guardianOk = false,
    this.shareWithCoach = false,
  });

  bool get isMinor => age < 18;

  UserProfile copyWith({
    List<String>? allergies,
    List<String>? conditions,
    String? notes,
    bool? shareWithCoach,
  }) =>
      UserProfile(
        name: name,
        age: age,
        sex: sex,
        heightCm: heightCm,
        weightKg: weightKg,
        activity: activity,
        goal: goal,
        diet: diet,
        allergies: allergies ?? this.allergies,
        conditions: conditions ?? this.conditions,
        notes: notes ?? this.notes,
        guardianOk: guardianOk,
        shareWithCoach: shareWithCoach ?? this.shareWithCoach,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'sex': sex.index,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activity': activity.index,
        'goal': goal.index,
        'diet': diet.index,
        'allergies': allergies,
        'conditions': conditions,
        'notes': notes,
        'guardianOk': guardianOk,
        'shareWithCoach': shareWithCoach,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] as String,
        age: j['age'] as int,
        sex: Sex.values[j['sex'] as int],
        heightCm: (j['heightCm'] as num).toDouble(),
        weightKg: (j['weightKg'] as num).toDouble(),
        activity: Activity.values[j['activity'] as int],
        goal: Goal.values[j['goal'] as int],
        diet: Diet.values[j['diet'] as int],
        allergies: ((j['allergies'] as List?) ?? const []).cast<String>(),
        conditions: ((j['conditions'] as List?) ?? const []).cast<String>(),
        notes: (j['notes'] as String?) ?? '',
        guardianOk: (j['guardianOk'] as bool?) ?? false,
        shareWithCoach: (j['shareWithCoach'] as bool?) ?? false,
      );
}

class WeightEntry {
  final String date; // yyyy-MM-dd
  final double kg;

  const WeightEntry(this.date, this.kg);

  Map<String, dynamic> toJson() => {'date': date, 'kg': kg};

  factory WeightEntry.fromJson(Map<String, dynamic> j) =>
      WeightEntry(j['date'] as String, (j['kg'] as num).toDouble());
}

class LogEntry {
  final String name;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  const LogEntry(this.name, this.kcal, this.protein, this.carbs, this.fat);

  Map<String, dynamic> toJson() =>
      {'n': name, 'k': kcal, 'p': protein, 'c': carbs, 'f': fat};

  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(
        j['n'] as String,
        j['k'] as int,
        j['p'] as int,
        j['c'] as int,
        j['f'] as int,
      );
}

class ExerciseEntry {
  final String name;
  final int minutes;
  final int kcal;
  final bool walk; // walking-type activity, covered by steps if tracked

  const ExerciseEntry(this.name, this.minutes, this.kcal, this.walk);

  Map<String, dynamic> toJson() =>
      {'n': name, 'm': minutes, 'k': kcal, 'w': walk};

  factory ExerciseEntry.fromJson(Map<String, dynamic> j) => ExerciseEntry(
        j['n'] as String,
        j['m'] as int,
        j['k'] as int,
        (j['w'] as bool?) ?? false,
      );
}

class DayLog {
  final List<LogEntry> foods;
  final List<ExerciseEntry> exercises;
  int steps;
  int waterMl;

  DayLog({
    List<LogEntry>? foods,
    List<ExerciseEntry>? exercises,
    this.steps = 0,
    this.waterMl = 0,
  })  : foods = foods ?? [],
        exercises = exercises ?? [];

  int get kcal => foods.fold<int>(0, (s, e) => s + e.kcal);
  int get protein => foods.fold<int>(0, (s, e) => s + e.protein);
  int get carbs => foods.fold<int>(0, (s, e) => s + e.carbs);
  int get fat => foods.fold<int>(0, (s, e) => s + e.fat);
  int get exerciseMinutes => exercises.fold<int>(0, (s, e) => s + e.minutes);

  Map<String, dynamic> toJson() => {
        'foods': foods.map((e) => e.toJson()).toList(),
        'ex': exercises.map((e) => e.toJson()).toList(),
        'steps': steps,
        'water': waterMl,
      };

  factory DayLog.fromJson(Map<String, dynamic> j) => DayLog(
        foods: ((j['foods'] as List?) ?? const [])
            .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        exercises: ((j['ex'] as List?) ?? const [])
            .map((e) => ExerciseEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: (j['steps'] as int?) ?? 0,
        waterMl: (j['water'] as int?) ?? 0,
      );
}
