import 'package:flutter/material.dart';

import 'l10n.dart';
import 'models.dart';
import 'storage.dart';

/// 193.0 -> 6'4"
String ftIn(double cm) {
  final totalIn = cm / 2.54;
  var ft = totalIn ~/ 12;
  var inch = (totalIn - ft * 12).round();
  if (inch == 12) {
    ft += 1;
    inch = 0;
  }
  return "$ft'$inch\"";
}

/// Reads "6'4", "6 4", "6ft 4in", "193" or "5.8" (feet). Returns cm or null.
double? parseHeight(String input) {
  final t = input
      .trim()
      .replaceAll('"', '')
      .replaceAll('’', "'")
      .replaceAll('′', "'")
      .toLowerCase();
  final m = RegExp(r"^(\d)\s*(?:'|ft|feet|\s)\s*(\d{1,2})?\s*(?:in|inch|inches)?$")
      .firstMatch(t);
  if (m != null) {
    final ft = int.parse(m.group(1)!);
    final inch = int.tryParse(m.group(2) ?? '0') ?? 0;
    if (ft >= 3 && ft <= 8 && inch < 12) return ft * 30.48 + inch * 2.54;
  }
  final n = double.tryParse(t.replaceAll(',', '.'));
  if (n == null) return null;
  if (n >= 90 && n <= 260) return n;
  if (n >= 3 && n <= 8.5) return n * 30.48;
  return null;
}

class HeightScreen extends StatefulWidget {
  final UserProfile profile;

  const HeightScreen({super.key, required this.profile});

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  late UserProfile p;
  final _father = TextEditingController();
  final _mother = TextEditingController();
  final _goal = TextEditingController();
  double? _lo;
  double? _hi;

  static const _habits = [
    ('sleep', 'hg_h_sleep', Icons.bedtime),
    ('stretch', 'hg_h_stretch', Icons.self_improvement),
    ('posture', 'hg_h_posture', Icons.accessibility_new),
    ('protein', 'hg_h_protein', Icons.egg_alt),
    ('sun', 'hg_h_sun', Icons.wb_sunny),
    ('play', 'hg_h_play', Icons.sports_basketball),
    ('water', 'hg_h_water', Icons.water_drop),
  ];

  @override
  void initState() {
    super.initState();
    p = widget.profile;
    final f = Storage.getDouble('hg_father');
    final m = Storage.getDouble('hg_mother');
    if (f != null) _father.text = _n(f);
    if (m != null) _mother.text = _n(m);
    _goal.text = Storage.getString('hg_goal') ?? '';
    _calc(save: false);
  }

  @override
  void dispose() {
    _father.dispose();
    _mother.dispose();
    _goal.dispose();
    super.dispose();
  }

  String _n(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  void _calc({bool save = true}) {
    final f = double.tryParse(_father.text.replaceAll(',', '.'));
    final m = double.tryParse(_mother.text.replaceAll(',', '.'));
    final ok = f != null && m != null && f >= 120 && f <= 230 && m >= 120 && m <= 230;
    setState(() {
      if (!ok) {
        _lo = null;
        _hi = null;
        return;
      }
      final male = p.sex == Sex.male;
      final mid = male ? (f + m + 13) / 2 : (f + m - 13) / 2;
      _lo = mid - 8.5;
      _hi = mid + 8.5;
    });
    if (save && ok) {
      Storage.setDouble('hg_father', f);
      Storage.setDouble('hg_mother', m);
    }
  }

  String _stageKey() {
    final a = p.age;
    final male = p.sex == Sex.male;
    if (a < 10) return 'hg_stage_young';
    if (male) {
      if (a <= 16) return 'hg_stage_growing';
      if (a <= 20) return 'hg_stage_slowing';
      return 'hg_stage_done';
    }
    if (a <= 14) return 'hg_stage_growing';
    if (a <= 17) return 'hg_stage_slowing';
    return 'hg_stage_done';
  }

  Future<void> _logHeight() async {
    final c = TextEditingController();
    final cm = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('hg_log_add')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: tr('hg_log_cm'), suffixText: 'cm'),
            ),
            const SizedBox(height: 8),
            Text(tr('hg_log_hint'), style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(c.text.replaceAll(',', '.'));
              Navigator.pop(ctx, (v != null && v >= 60 && v <= 230) ? v : null);
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    c.dispose();
    if (cm == null) return;
    await Storage.addHeight(cm);
    p = p.copyWith(heightCm: cm);
    await Storage.saveProfile(p);
    if (mounted) setState(() {});
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );

  Widget _goalMessage() {
    final text = _goal.text.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final g = parseHeight(text);
    final err = TextStyle(color: Theme.of(context).colorScheme.error);
    if (g == null) return Text(tr('hg_goal_bad'), style: err);
    if (_lo == null) return Text(tr('hg_goal_need'));
    final gs = '${g.round()} cm (${ftIn(g)})';
    final key = g > _hi!
        ? 'hg_goal_above'
        : (g < _lo! ? 'hg_goal_below' : 'hg_goal_in');
    return Text(tr(key, {'g': gs}));
  }

  Widget _verdict(String id, String verdict) {
    final (icon, color) = switch (verdict) {
      'ok' => (Icons.check_circle, Colors.green),
      'part' => (Icons.error_outline, Colors.orange),
      _ => (Icons.cancel, Colors.red),
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(tr('hg_${id}_t')),
      subtitle: Text(tr('hg_${id}_d')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      final theme = Theme.of(context);
      final key = Storage.todayKey();
      final done = Storage.habitsFor(key);
      final heights = Storage.loadHeights();
      final first = heights.isEmpty ? null : heights.first;
      final last = heights.isEmpty ? null : heights.last;
      double? perYear;
      if (first != null && last != null && first.date != last.date) {
        final days = DateTime.parse(last.date)
            .difference(DateTime.parse(first.date))
            .inDays;
        if (days >= 60) perYear = (last.cm - first.cm) / days * 365;
      }
      final vegan = p.diet == Diet.vegan;

      return Scaffold(
        appBar: AppBar(title: Text(tr('hg_title'))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(tr('hg_info')),
                ),
              ),

              // ---- stage ----
              _title(tr('hg_stage_title')),
              Text(
                tr('hg_now', {
                  'cm': p.heightCm.round(),
                  'ft': ftIn(p.heightCm),
                }),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(tr(_stageKey())),

              // ---- prediction and goal ----
              _title(tr('hg_pred_title')),
              Text(tr('hg_pred_info')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _father,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _calc(),
                      decoration: InputDecoration(
                          labelText: tr('hg_father'),
                          border: const OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _mother,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _calc(),
                      decoration: InputDecoration(
                          labelText: tr('hg_mother'),
                          border: const OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              if (_lo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    tr('hg_pred_res', {
                      'a': _lo!.round(),
                      'b': _hi!.round(),
                      'fa': ftIn(_lo!),
                      'fb': ftIn(_hi!),
                    }),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _goal,
                onChanged: (v) {
                  Storage.setString('hg_goal', v);
                  setState(() {});
                },
                decoration: InputDecoration(
                    labelText: tr('hg_goal'), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              _goalMessage(),

              // ---- daily habits ----
              _title(tr('hg_habits_title')),
              LinearProgressIndicator(
                value: done.length / _habits.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 4),
              Text(tr('hg_done', {'a': done.length, 'b': _habits.length}),
                  style: theme.textTheme.bodySmall),
              for (final h in _habits)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: Icon(h.$3),
                  value: done.contains(h.$1),
                  title: Text(tr(h.$2)),
                  onChanged: (_) async {
                    await Storage.toggleHabit(key, h.$1);
                    if (mounted) setState(() {});
                  },
                ),

              // ---- routine ----
              _title(tr('hg_routine_title')),
              Text(tr('hg_routine_note'), style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              for (int i = 1; i <= 8; i++)
                Card(
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('$i', style: const TextStyle(fontSize: 13)),
                    ),
                    title: Text(tr('hg_e$i')),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(tr('hg_e${i}_d'))],
                  ),
                ),
              const SizedBox(height: 8),
              Text(tr('hg_sport')),

              // ---- food ----
              _title(tr('hg_food_title')),
              Text(tr('hg_food_list')),
              if (vegan)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(tr('hg_food_vegan')),
                ),

              // ---- popular methods ----
              _title(tr('hg_myth_title')),
              _verdict('m1', 'ok'),
              _verdict('m2', 'ok'),
              _verdict('m3', 'ok'),
              _verdict('m4', 'part'),
              _verdict('m5', 'no'),
              _verdict('m6', 'no'),
              _verdict('m7', 'part'),
              _verdict('m8', 'no'),
              _verdict('m9', 'no'),

              // ---- doctor ----
              _title(tr('hg_doc_title')),
              Text(tr('hg_doc_list')),

              // ---- log ----
              _title(tr('hg_log_title')),
              FilledButton.icon(
                onPressed: _logHeight,
                icon: const Icon(Icons.add),
                label: Text(tr('hg_log_add')),
              ),
              const SizedBox(height: 8),
              if (first != null && last != null && first.date != last.date)
                Text(tr('hg_log_gain',
                    {'n': (last.cm - first.cm).toStringAsFixed(1)})),
              if (perYear != null)
                Text(tr('hg_speed', {'n': perYear.toStringAsFixed(1)})),
              for (int i = heights.length - 1; i >= 0; i--)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.height),
                  title: Text(
                      '${heights[i].cm.toStringAsFixed(1)} cm  (${ftIn(heights[i].cm)})'),
                  subtitle: i > 0
                      ? Text(
                          '${(heights[i].cm - heights[i - 1].cm) >= 0 ? '+' : ''}${(heights[i].cm - heights[i - 1].cm).toStringAsFixed(1)} cm')
                      : null,
                  trailing: Text(heights[i].date),
                ),
              const SizedBox(height: 16),
              Text(tr('disclaimer'), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      );
    });
  }
}
