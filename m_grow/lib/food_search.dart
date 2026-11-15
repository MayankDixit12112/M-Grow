import 'package:flutter/material.dart';

import 'foods.dart';
import 'l10n.dart';
import 'medical.dart';
import 'models.dart';
import 'storage.dart';

/// Opens a search sheet over the whole food list. Tap a dish, choose how much,
/// and it is added to today.
Future<void> showFoodSearch(BuildContext context, UserProfile profile) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FoodSearchSheet(profile: profile),
  );
}

String _q(double q) => q == q.roundToDouble() ? '${q.toInt()}' : '$q';

class _FoodSearchSheet extends StatefulWidget {
  final UserProfile profile;

  const _FoodSearchSheet({required this.profile});

  @override
  State<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<_FoodSearchSheet> {
  final _c = TextEditingController();
  final List<String> _added = [];
  late final List<Food> _all;
  late List<Food> _shown;

  @override
  void initState() {
    super.initState();
    _all = [...foods]..sort((a, b) => a.name.compareTo(b.name));
    _shown = _all;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _filter(String text) {
    final words = text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    setState(() {
      if (words.isEmpty) {
        _shown = _all;
        return;
      }
      _shown = _all.where((f) {
        final hay = '${f.keys.join(' ')} ${f.serving.toLowerCase()}';
        return words.every(hay.contains);
      }).toList();
    });
  }

  List<String> _conflicts(Food f) {
    final avoid = Medical.avoid(widget.profile);
    return f.allergens.where(avoid.contains).toList();
  }

  Future<void> _pick(Food f) async {
    final hide = Medical.hideNumbers(widget.profile);
    final conflicts = _conflicts(f);
    double qty = 1;
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(f.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('fs_serving_is', {'s': f.serving})),
              const SizedBox(height: 12),
              Text(tr('fs_qty'), style: Theme.of(ctx).textTheme.titleSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: qty > 0.5 ? () => setD(() => qty -= 0.5) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(_q(qty),
                        style: Theme.of(ctx).textTheme.headlineMedium),
                  ),
                  IconButton.filledTonal(
                    onPressed: qty < 20 ? () => setD(() => qty += 0.5) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final v in [0.5, 1.0, 1.5, 2.0, 3.0])
                    ChoiceChip(
                      label: Text(_q(v)),
                      selected: qty == v,
                      onSelected: (_) => setD(() => qty = v),
                    ),
                ],
              ),
              if (!hide)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(tr('fs_total', {'k': (f.cal * qty).round()}),
                      style: Theme.of(ctx).textTheme.titleMedium),
                ),
              if (conflicts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    tr('fs_contains',
                        {'a': conflicts.map((a) => tr('al_$a')).join(', ')}),
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, qty),
                child: Text(tr('fs_add'))),
          ],
        ),
      ),
    );
    if (result == null) return;
    final key = Storage.todayKey();
    final log = Storage.loadLog(key);
    log.foods.add(LogEntry(
      result == 1 ? f.name : '${_q(result)} x ${f.name}',
      (f.cal * result).round(),
      (f.protein * result).round(),
      (f.carbs * result).round(),
      (f.fat * result).round(),
    ));
    await Storage.saveLog(key, log);
    if (mounted) setState(() => _added.add(f.name));
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      final hide = Medical.hideNumbers(widget.profile);
      final theme = Theme.of(context);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _c,
                        autofocus: true,
                        onChanged: _filter,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: tr('fs_hint'),
                          border: const OutlineInputBorder(),
                          suffixIcon: _c.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _c.clear();
                                    _filter('');
                                  },
                                ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: tr('fs_close'),
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (_added.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: const Icon(Icons.check_circle, color: Colors.green),
                      label: Text(tr('fs_added', {'n': _added.last})),
                    ),
                  ),
                ),
              Expanded(
                child: _shown.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(tr('fs_none'), textAlign: TextAlign.center),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _shown.length,
                        itemBuilder: (context, i) {
                          final f = _shown[i];
                          final conflict = _conflicts(f).isNotEmpty;
                          return ListTile(
                            title: Text(f.name),
                            subtitle: Text(hide
                                ? f.serving
                                : '${f.serving} - ${f.cal} kcal'),
                            trailing: conflict
                                ? Icon(Icons.warning_amber,
                                    color: theme.colorScheme.error)
                                : const Icon(Icons.add_circle_outline),
                            onTap: () => _pick(f),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
