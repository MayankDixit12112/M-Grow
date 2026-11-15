import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'config.dart';
import 'l10n.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<String> _load() async {
    final raw = await rootBundle.loadString('assets/privacy_policy.md');
    return raw
        .replaceAll('{{EMAIL}}', Config.feedbackEmail)
        .replaceAll('{{DEVELOPER}}', Config.developerName);
  }

  @override
  Widget build(BuildContext context) {
    return LangScope(builder: (context) {
      final theme = Theme.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(tr('privacy_title'))),
        body: SafeArea(
          child: FutureBuilder<String>(
            future: _load(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final lines = snap.data!.split('\n');
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final l in lines)
                    if (l.trim().isEmpty)
                      const SizedBox(height: 8)
                    else if (l.startsWith('# '))
                      Text(l.substring(2), style: theme.textTheme.headlineSmall)
                    else if (l.startsWith('## '))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(l.substring(3),
                            style: theme.textTheme.titleMedium),
                      )
                    else if (l.startsWith('- '))
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text('•  ${l.substring(2)}'),
                      )
                    else
                      Text(l),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}
