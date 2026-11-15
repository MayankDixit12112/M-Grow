import 'package:flutter/material.dart';

import 'calculator.dart';
import 'l10n.dart';
import 'medical.dart';
import 'models.dart';
import 'planner.dart';

const _dayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class PlanTab extends StatefulWidget {
  final UserProfile profile;
  final Targets targets;
  final List<List<PlannedMeal>> week;

  const PlanTab({
    super.key,
    required this.profile,
    required this.targets,
    required this.week,
  });

  @override
  State<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<PlanTab> {
  int day = DateTime.now().weekday - 1;
  bool showTimetable = false;

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      final hide = Medical.hideNumbers(widget.profile);
      final meals = widget.week[day];
      final total = meals.fold<int>(0, (s, m) => s + m.calories);
      final slots =
          Timetable.day(day, widget.profile, widget.targets, meals);

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(tr('tab_meals'))),
                ButtonSegment(value: true, label: Text(tr('tab_time'))),
              ],
              selected: {showTimetable},
              onSelectionChanged: (s) =>
                  setState(() => showTimetable = s.first),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                for (int i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_dayKeys[i]),
                      selected: i == day,
                      onSelected: (_) => setState(() => day = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: showTimetable
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final s in slots)
                        ListTile(
                          leading: Icon(s.icon),
                          title: Text(s.title),
                          subtitle: s.detail.isEmpty ? null : Text(s.detail),
                          trailing: Text(s.time),
                        ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (!hide)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            tr('planned_total',
                                {'a': total, 'b': widget.targets.calories}),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      for (final m in meals)
                        Card(
                          child: ListTile(
                            title: Text('${tr(m.slotKey)}: ${m.food.name}'),
                            subtitle: Text(hide
                                ? m.servingLabel
                                : '${m.servingLabel}\nP ${m.protein} g   C ${m.carbs} g   F ${m.fat} g'),
                            isThreeLine: !hide,
                            trailing: hide
                                ? null
                                : Text('${m.calories}\nkcal',
                                    textAlign: TextAlign.center),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      );
    });
  }
}
