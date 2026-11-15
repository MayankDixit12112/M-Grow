import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'l10n.dart';
import 'models.dart';
import 'storage.dart';

class OnboardingScreen extends StatefulWidget {
  final UserProfile? existing;

  const OnboardingScreen({super.key, this.existing});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late Sex _sex;
  late Activity _activity;
  late Goal _goal;
  late Diet _diet;
  bool _guardian = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _age = TextEditingController(text: e?.age.toString() ?? '');
    _height = TextEditingController(text: e?.heightCm.toString() ?? '');
    _weight = TextEditingController(text: e?.weightKg.toString() ?? '');
    _sex = e?.sex ?? Sex.male;
    _activity = e?.activity ?? Activity.light;
    _goal = e?.goal ?? Goal.maintain;
    _diet = e?.diet ?? Diet.vegetarian;
    _guardian = e?.guardianOk ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  int? get _ageNum => int.tryParse(_age.text);
  bool get _minor => (_ageNum ?? 30) < 18;

  String? _range(String? v, double min, double max) {
    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
    if (n == null) return tr('err_num');
    if (n < min || n > max) return '$min - $max';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final age = int.parse(_age.text);
    final minor = age < 18;
    if (minor && !_guardian) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('guardian'))));
      return;
    }
    final old = widget.existing;
    final profile = UserProfile(
      name: _name.text.trim().isEmpty ? '' : _name.text.trim(),
      age: age,
      sex: _sex,
      heightCm: double.parse(_height.text.replaceAll(',', '.')),
      weightKg: double.parse(_weight.text.replaceAll(',', '.')),
      activity: _activity,
      goal: minor
          ? Goal.grow
          : (_goal == Goal.grow ? Goal.maintain : _goal),
      diet: _diet,
      allergies: old?.allergies ?? const [],
      conditions: old?.conditions ?? const [],
      notes: old?.notes ?? '',
      guardianOk: minor ? _guardian : false,
      shareWithCoach: minor ? false : (old?.shareWithCoach ?? false),
    );
    await Storage.saveProfile(profile);
    final weights = Storage.loadWeights();
    if (weights.isEmpty || weights.last.kg != profile.weightKg) {
      await Storage.addWeight(profile.weightKg);
    }
    if (!mounted) return;
    if (old != null) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _chips<T>(List<T> values, T selected, String Function(T) label,
      void Function(T) onSelected) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(label(v)),
            selected: v == selected,
            onSelected: (_) => setState(() => onSelected(v)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      final editing = widget.existing != null;
      final goals =
          _minor ? [Goal.grow] : [Goal.lose, Goal.maintain, Goal.gain];
      final shownGoal = _minor
          ? Goal.grow
          : (_goal == Goal.grow ? Goal.maintain : _goal);
      return Scaffold(
        appBar: AppBar(
          title: Text(editing ? tr('me_edit') : tr('welcome')),
          actions: [
            if (!editing)
              PopupMenuButton<String>(
                icon: const Icon(Icons.language),
                tooltip: tr('language'),
                onSelected: (c) {
                  L10n.lang.value = c;
                  Storage.setLanguage(c);
                },
                itemBuilder: (_) => [
                  for (final e in L10n.languages.entries)
                    PopupMenuItem(value: e.key, child: Text(e.value)),
                ],
              ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!editing)
                  Text(tr('welcome_sub'),
                      style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                      labelText: tr('name_opt'),
                      border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                            labelText: tr('age'),
                            border: const OutlineInputBorder()),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null) return tr('err_num');
                          if (n < 6 || n > 100) return tr('err_age');
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _height,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                            labelText: tr('height'),
                            border: const OutlineInputBorder()),
                        validator: (v) => _range(v, 90, 230),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: tr('weight'),
                      border: const OutlineInputBorder()),
                  validator: (v) => _range(v, 15, 250),
                ),
                _section(tr('sex')),
                _chips<Sex>(Sex.values, _sex, (v) => tr(v.key), (v) => _sex = v),
                _section(tr('goal')),
                _chips<Goal>(goals, shownGoal, (v) => tr(v.key), (v) => _goal = v),
                if (_minor)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(tr('minor_info'),
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                _section(tr('diet')),
                _chips<Diet>(Diet.values, _diet, (v) => tr(v.key), (v) => _diet = v),
                _section(tr('activity')),
                _chips<Activity>(Activity.values, _activity, (v) => tr(v.key),
                    (v) => _activity = v),
                if (_minor)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _guardian,
                    onChanged: (v) => setState(() => _guardian = v ?? false),
                    title: Text(tr('guardian')),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(editing ? tr('save') : tr('create')),
                  ),
                ),
                const SizedBox(height: 12),
                Text(tr('disclaimer'),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    });
  }
}
