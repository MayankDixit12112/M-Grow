import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'calculator.dart';
import 'coach_logic.dart';
import 'l10n.dart';
import 'medical.dart';
import 'models.dart';
import 'planner.dart';
import 'height_screen.dart';
import 'steps_service.dart';
import 'storage.dart';

class TodayTab extends StatelessWidget {
  final UserProfile profile;
  final Targets targets;
  final List<List<PlannedMeal>> week;
  final VoidCallback onChanged;

  const TodayTab({
    super.key,
    required this.profile,
    required this.targets,
    required this.week,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LangScope(
      builder: (context) => ValueListenableBuilder<int>(
        valueListenable: Storage.tick,
        builder: (context, _, __) => _body(context),
      ),
    );
  }

  Future<void> _askSteps(BuildContext context, DayLog log, String key) async {
    final c = TextEditingController(text: log.steps == 0 ? '' : '${log.steps}');
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('steps_enter')),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(c.text);
              Navigator.pop(ctx, (n != null && n >= 0 && n <= 100000) ? n : null);
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    c.dispose();
    if (v != null) await StepsService.setToday(v);
  }

  Widget _macro(BuildContext context, String label, String value) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );

  Widget _stepStatus(BuildContext context, String st) {
    final small = Theme.of(context).textTheme.bodySmall;
    switch (st) {
      case 'on':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(tr('st_on'))),
                ],
              ),
              Text(tr('st_note'), style: small),
            ],
          ),
        );
      case 'denied':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('st_denied')),
              const SizedBox(height: 6),
              FilledButton.tonal(
                onPressed: StepsService.start,
                child: Text(tr('st_allow')),
              ),
            ],
          ),
        );
      case 'blocked':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('st_blocked')),
              const SizedBox(height: 6),
              FilledButton.tonal(
                onPressed: openAppSettings,
                child: Text(tr('st_settings')),
              ),
            ],
          ),
        );
      case 'unsupported':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(tr('st_unsup')),
        );
      default:
        return Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: StepsService.start,
            icon: const Icon(Icons.directions_walk),
            label: Text(tr('steps_auto')),
          ),
        );
    }
  }

  Widget _body(BuildContext context) {
    final key = Storage.todayKey();
    final log = Storage.loadLog(key);
    final t = targets;
    final hide = Medical.hideNumbers(profile);
    final budget = Calculator.budget(profile, t, log);
    final burned = Calculator.burned(profile, log);
    final streak = Storage.streak();
    final meals = week[DateTime.now().weekday - 1];
    final theme = Theme.of(context);
    final name = profile.name;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          name.isEmpty ? tr('greet', {'name': ''}).replaceAll(' !', '!') : tr('greet', {'name': name}),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        for (final k in t.noteKeys)
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(tr(k)),
            ),
          ),
        if (!hide) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('calories'), style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(tr('kcal_of', {'a': log.kcal, 'b': budget}),
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (log.kcal / budget).clamp(0.0, 1.0),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _macro(context, tr('protein'), '${log.protein}/${t.protein} g'),
              _macro(context, tr('carbs'), '${log.carbs}/${t.carbs} g'),
              _macro(context, tr('fat'), '${log.fat}/${t.fat} g'),
            ],
          ),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_walk),
                    const SizedBox(width: 8),
                    Text('${tr('steps')}: ${log.steps} / ${t.stepGoal}',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (log.steps / t.stepGoal).clamp(0.0, 1.0),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                if (!hide)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${tr('burned')}: $burned kcal',
                        style: theme.textTheme.bodyMedium),
                  ),
                ValueListenableBuilder<String>(
                  valueListenable: StepsService.status,
                  builder: (context, st, _) => _stepStatus(context, st),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _askSteps(context, log, key),
                    icon: const Icon(Icons.edit),
                    label: Text(tr('steps_enter')),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.water_drop),
            title: Text('${tr('water')}: ${log.waterMl} / ${t.waterMl} ml'),
            trailing: FilledButton.tonal(
              onPressed: () async {
                log.waterMl += 250;
                await Storage.saveLog(key, log);
              },
              child: Text(tr('glass_add')),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.height),
            title: Text(tr('hg_card_title')),
            subtitle: Text(tr('hg_card_sub')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HeightScreen(profile: profile)));
              onChanged();
            },
          ),
        ),
        if (streak > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text(tr('streak', {'n': streak})),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(tr('tasks'), style: theme.textTheme.titleMedium),
        for (final task in Coach.tasks(profile, t, log))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(task.icon),
            title: Text(task.text),
          ),
        const SizedBox(height: 8),
        Text(tr('meals_today'), style: theme.textTheme.titleMedium),
        for (final m in meals)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${tr(m.slotKey)}: ${m.food.name}'),
            subtitle: Text(hide
                ? '${m.servingLabel} - ${m.time}'
                : '${m.servingLabel} - ${m.calories} kcal - ${m.time}'),
            trailing: IconButton(
              tooltip: tr('log_it'),
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () async {
                final l = Storage.loadLog(key);
                l.foods.add(LogEntry(
                    m.food.name, m.calories, m.protein, m.carbs, m.fat));
                await Storage.saveLog(key, l);
              },
            ),
          ),
        const SizedBox(height: 16),
        Text(tr('disclaimer'), style: theme.textTheme.bodySmall),
      ],
    );
  }
}
