import 'package:flutter/material.dart';

import 'calculator.dart';
import 'l10n.dart';
import 'models.dart';
import 'planner.dart';
import 'steps_service.dart';
import 'storage.dart';
import 'tab_coach.dart';
import 'tab_log.dart';
import 'tab_me.dart';
import 'tab_plan.dart';
import 'tab_today.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserProfile profile;
  late Targets targets;
  late List<List<PlannedMeal>> week;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
    StepsService.autoStart(); // steps count by themselves
  }

  void _load() {
    profile = Storage.loadProfile()!;
    targets = Calculator.compute(profile);
    week = MealPlanner.week(profile, targets);
  }

  void _reload() => setState(_load);

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      final pages = <Widget>[
        TodayTab(
            profile: profile, targets: targets, week: week, onChanged: _reload),
        LogTab(profile: profile),
        PlanTab(profile: profile, targets: targets, week: week),
        CoachTab(profile: profile, onChanged: _reload),
        MeTab(profile: profile, targets: targets, onChanged: _reload),
      ];
      return Scaffold(
        appBar: AppBar(title: const Text('M Grow')),
        body: SafeArea(child: IndexedStack(index: tab, children: pages)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.today), label: tr('nav_today')),
            NavigationDestination(
                icon: const Icon(Icons.edit_note), label: tr('nav_log')),
            NavigationDestination(
                icon: const Icon(Icons.restaurant_menu), label: tr('nav_plan')),
            NavigationDestination(
                icon: const Icon(Icons.smart_toy), label: tr('nav_coach')),
            NavigationDestination(
                icon: const Icon(Icons.person), label: tr('nav_me')),
          ],
        ),
      );
    });
  }
}
