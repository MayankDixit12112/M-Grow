import 'package:flutter/material.dart';

import 'l10n.dart';
import 'medical.dart';
import 'models.dart';
import 'storage.dart';

class HealthScreen extends StatefulWidget {
  final UserProfile profile;

  const HealthScreen({super.key, required this.profile});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  late final Set<String> _allergies;
  late final Set<String> _conditions;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _allergies = widget.profile.allergies.toSet();
    _conditions = widget.profile.conditions.toSet();
    _notes = TextEditingController(text: widget.profile.notes);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.profile.copyWith(
      allergies: _allergies.toList(),
      conditions: _conditions.toList(),
      notes: _notes.text.trim(),
    );
    await Storage.saveProfile(updated);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _group(String title, List<String> keys, String prefix, Set<String> sel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final k in keys)
              FilterChip(
                label: Text(tr('$prefix$k')),
                selected: sel.contains(k),
                onSelected: (v) => setState(() {
                  if (v) {
                    sel.add(k);
                  } else {
                    sel.remove(k);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      final preview = widget.profile.copyWith(
        allergies: _allergies.toList(),
        conditions: _conditions.toList(),
      );
      final adult = !widget.profile.isMinor;
      return Scaffold(
        appBar: AppBar(title: Text(tr('h_title'))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(tr('h_info')),
              _group(tr('h_allergies'), Medical.allergens, 'al_', _allergies),
              _group(tr('h_conditions'), Medical.conditions, 'c_', _conditions),
              if (adult && Medical.locked(preview))
                Card(
                  margin: const EdgeInsets.only(top: 16),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                        Medical.hideNumbers(preview) ? tr('n_ed') : tr('h_warn')),
                  ),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _notes,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: tr('h_notes'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(tr('save')),
                ),
              ),
              const SizedBox(height: 12),
              Text(tr('disclaimer'), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
    });
  }
}
