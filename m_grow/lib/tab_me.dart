import 'package:flutter/material.dart';

import 'calculator.dart';
import 'feedback_screen.dart';
import 'health_screen.dart';
import 'l10n.dart';
import 'models.dart';
import 'onboarding_screen.dart';
import 'privacy_screen.dart';
import 'progress_screen.dart';
import 'storage.dart';

class MeTab extends StatelessWidget {
  final UserProfile profile;
  final Targets targets;
  final VoidCallback onChanged;

  const MeTab({
    super.key,
    required this.profile,
    required this.targets,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context, Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen));
    onChanged();
  }

  void _pickLanguage(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final e in L10n.languages.entries)
              ListTile(
                title: Text(e.value),
                trailing: L10n.lang.value == e.key
                    ? const Icon(Icons.check)
                    : null,
                onTap: () async {
                  L10n.lang.value = e.key;
                  await Storage.setLanguage(e.key);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('me_delete')),
        content: Text(tr('delete_q')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('delete'))),
        ],
      ),
    );
    if (ok != true) return;
    await Storage.deleteAll();
    L10n.lang.value = 'en';
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      final theme = Theme.of(context);
      Widget tile(IconData icon, String title, VoidCallback onTap,
              {Color? color}) =>
          ListTile(
            leading: Icon(icon, color: color),
            title: Text(title, style: TextStyle(color: color)),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          );

      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    profile.name.isEmpty ? 'M Grow' : profile.name,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          tile(Icons.show_chart, tr('me_progress'),
              () => _open(context, ProgressScreen(profile: profile, targets: targets))),
          tile(Icons.medical_information, tr('me_health'),
              () => _open(context, HealthScreen(profile: profile))),
          tile(Icons.edit, tr('me_edit'),
              () => _open(context, OnboardingScreen(existing: profile))),
          tile(Icons.language, tr('me_lang'), () => _pickLanguage(context)),
          tile(Icons.feedback, tr('me_fb'),
              () => _open(context, const FeedbackScreen())),
          tile(Icons.privacy_tip, tr('me_privacy'),
              () => _open(context, const PrivacyScreen())),
          const Divider(),
          tile(Icons.delete_forever, tr('me_delete'), () => _deleteAll(context),
              color: theme.colorScheme.error),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(tr('disclaimer'), style: theme.textTheme.bodySmall),
          ),
        ],
      );
    });
  }
}
