import 'dart:math';

import 'package:flutter/material.dart';

import 'l10n.dart';
import 'medical.dart';
import 'models.dart';
import 'parser.dart';
import 'storage.dart';

class LogTab extends StatefulWidget {
  final UserProfile profile;

  const LogTab({super.key, required this.profile});

  @override
  State<LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<LogTab> {
  final _c = TextEditingController();
  List<ParsedItem> _results = [];
  bool _calculated = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _q(double q) => q == q.roundToDouble() ? '${q.toInt()}' : '$q';

  int _exKcal(ParsedItem it) =>
      (it.exercise!.met * widget.profile.weightKg * it.minutes / 60).round();

  void _calc() {
    setState(() {
      _results = Parser.parse(_c.text);
      _calculated = true;
    });
  }

  Future<void> _addAll() async {
    final key = Storage.todayKey();
    final log = Storage.loadLog(key);
    for (final it in _results) {
      if (it.food != null) {
        final f = it.food!;
        final q = it.qty;
        log.foods.add(LogEntry(
          q == 1 ? f.name : '${_q(q)} x ${f.name}',
          (f.cal * q).round(),
          (f.protein * q).round(),
          (f.carbs * q).round(),
          (f.fat * q).round(),
        ));
      } else if (it.exercise != null) {
        log.exercises.add(ExerciseEntry(
            it.exercise!.name, it.minutes, _exKcal(it), it.exercise!.walk));
      } else if (it.steps != null) {
        log.steps = max(log.steps, it.steps!);
      }
    }
    await Storage.saveLog(key, log);
    setState(() {
      _results = [];
      _calculated = false;
      _c.clear();
    });
  }

  Future<void> _custom() async {
    final name = TextEditingController();
    final kcal = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('log_custom')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(labelText: tr('log_name')),
            ),
            TextField(
              controller: kcal,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr('log_kcal')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('add'))),
        ],
      ),
    );
    final n = name.text.trim();
    final k = int.tryParse(kcal.text);
    name.dispose();
    kcal.dispose();
    if (ok == true && n.isNotEmpty && k != null && k >= 0 && k <= 5000) {
      final key = Storage.todayKey();
      final log = Storage.loadLog(key);
      log.foods.add(LogEntry(n, k, 0, 0, 0));
      await Storage.saveLog(key, log);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      final theme = Theme.of(context);
      final hide = Medical.hideNumbers(widget.profile);
      final found = _results.where((r) => r.found).toList();
      final unknown = _results.where((r) => !r.found).toList();

      return ValueListenableBuilder<int>(
        valueListenable: Storage.tick,
        builder: (context, _, __) {
          final log = Storage.loadLog(Storage.todayKey());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(tr('log_title'), style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _c,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: tr('log_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _calc,
                icon: const Icon(Icons.calculate),
                label: Text(tr('log_btn')),
              ),
              if (_calculated) ...[
                const SizedBox(height: 16),
                if (found.isEmpty)
                  Text(tr('log_none'))
                else ...[
                  Text(tr('log_found'), style: theme.textTheme.titleMedium),
                  for (final it in found)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(it.food != null
                          ? Icons.restaurant
                          : (it.steps != null
                              ? Icons.directions_walk
                              : Icons.fitness_center)),
                      title: Text(it.food != null
                          ? (it.qty == 1
                              ? it.food!.name
                              : '${_q(it.qty)} x ${it.food!.name}')
                          : (it.exercise != null
                              ? '${it.exercise!.name} - ${it.minutes} min'
                              : '${it.steps} ${tr('steps')}')),
                      subtitle: it.food != null
                          ? Text(it.food!.serving)
                          : null,
                      trailing: hide
                          ? null
                          : Text(it.food != null
                              ? '${(it.food!.cal * it.qty).round()} kcal'
                              : (it.exercise != null
                                  ? '-${_exKcal(it)} kcal'
                                  : '')),
                    ),
                  Text(tr('log_note'), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  FilledButton(
                      onPressed: _addAll, child: Text(tr('log_add_all'))),
                ],
                for (final it in unknown)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(tr('log_unknown', {'t': it.text}),
                        style: TextStyle(color: theme.colorScheme.error)),
                  ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _custom,
                  icon: const Icon(Icons.add),
                  label: Text(tr('log_custom')),
                ),
              ),
              const Divider(),
              Text(tr('log_today'), style: theme.textTheme.titleMedium),
              if (log.foods.isEmpty && log.exercises.isEmpty && log.steps == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(tr('log_empty')),
                ),
              for (int i = 0; i < log.foods.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restaurant),
                  title: Text(log.foods[i].name),
                  subtitle: hide ? null : Text('${log.foods[i].kcal} kcal'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: tr('delete'),
                    onPressed: () async {
                      log.foods.removeAt(i);
                      await Storage.saveLog(Storage.todayKey(), log);
                    },
                  ),
                ),
              for (int i = 0; i < log.exercises.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fitness_center),
                  title: Text(log.exercises[i].name),
                  subtitle: Text(hide
                      ? '${log.exercises[i].minutes} min'
                      : '${log.exercises[i].minutes} min - ${log.exercises[i].kcal} kcal'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: tr('delete'),
                    onPressed: () async {
                      log.exercises.removeAt(i);
                      await Storage.saveLog(Storage.todayKey(), log);
                    },
                  ),
                ),
              if (log.steps > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.directions_walk),
                  title: Text('${log.steps} ${tr('steps')}'),
                ),
            ],
          );
        },
      );
    });
  }
}
