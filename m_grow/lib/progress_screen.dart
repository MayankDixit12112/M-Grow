import 'package:flutter/material.dart';

import 'calculator.dart';
import 'l10n.dart';
import 'medical.dart';
import 'models.dart';
import 'storage.dart';

class ProgressScreen extends StatefulWidget {
  final UserProfile profile;
  final Targets targets;

  const ProgressScreen({super.key, required this.profile, required this.targets});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Future<void> _logWeight() async {
    final c = TextEditingController();
    final kg = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('pr_log_w')),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(c.text.replaceAll(',', '.'));
              Navigator.pop(ctx, (v != null && v >= 15 && v <= 250) ? v : null);
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    c.dispose();
    if (kg != null) {
      await Storage.addWeight(kg);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      final p = widget.profile;
      final t = widget.targets;
      final theme = Theme.of(context);

      // With an eating-disorder history, weight and BMI are not shown.
      if (Medical.hideNumbers(p)) {
        return Scaffold(
          appBar: AppBar(title: Text(tr('pr_title'))),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(tr('n_ed')),
          ),
        );
      }

      final weights = Storage.loadWeights();
      final start = weights.isEmpty ? p.weightKg : weights.first.kg;
      final current = weights.isEmpty ? p.weightKg : weights.last.kg;
      final diff = current - start;

      return Scaffold(
        appBar: AppBar(title: Text(tr('pr_title'))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text(
                      '${tr('bmi')} ${t.bmi.toStringAsFixed(1)}${t.bmiValid ? '  -  ${tr(t.bmiKey)}' : ''}'),
                  subtitle: t.bmiValid ? null : Text(tr('b_minor')),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(tr('pr_now', {'n': current.toStringAsFixed(1)})),
                  subtitle: Text(
                      '${start.toStringAsFixed(1)} kg  ->  ${current.toStringAsFixed(1)} kg  (${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg)'),
                ),
              ),
              FilledButton.icon(
                onPressed: _logWeight,
                icon: const Icon(Icons.add),
                label: Text(tr('pr_log_w')),
              ),
              const SizedBox(height: 16),
              Text(tr('pr_history'), style: theme.textTheme.titleMedium),
              for (final w in weights.reversed)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: Text('${w.kg.toStringAsFixed(1)} kg'),
                  trailing: Text(w.date),
                ),
            ],
          ),
        ),
      );
    });
  }
}
